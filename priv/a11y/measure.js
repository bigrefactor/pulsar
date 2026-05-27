// Pulsar a11y measurement script — injected into fixture pages by
// test/integration/a11y/measure_test.exs. All measurements operate on
// elements tagged `[data-fixture-cell]` (see test/support/dev_app/live/*).
//
// API surface exposed on `window.PulsarA11yMeasure`:
//
//   measureAll()                  -> { url, theme, viewport, cells: [...] }
//   applyTextSpacingOverride()    -> void
//   removeTextSpacingOverride()   -> void
//   detectOverflows()             -> [cellId, ...]
//
// The Elixir test harness calls these in sequence per page+theme, then
// formats the JSON into docs/a11y/measurements/<component>-<theme>.md.

(function () {
  "use strict";

  const TEXT_SPACING_STYLE_ID = "pulsar-a11y-text-spacing-override";
  const REFLOW_STYLE_ID = "pulsar-a11y-reflow-constraint";
  // WCAG 1.4.12 thresholds.
  const TEXT_SPACING_CSS = `
    *:not(.pulsar-a11y-skip-text-spacing) {
      line-height: 1.5 !important;
      letter-spacing: 0.12em !important;
      word-spacing: 0.16em !important;
    }
    p, .pulsar-a11y-paragraph {
      margin-bottom: 2em !important;
    }
  `;

  // -- Color parsing & contrast ---------------------------------------------

  // Canvas-based color parser. Delegates to the browser by painting `input`
  // on a 1×1 canvas and reading the rasterized pixel. Handles every CSS
  // color form the browser understands: `rgb()`, `rgba()`, hex, named
  // colors, `oklch()`, `oklab()`, `color(display-p3 …)`, `hsl()`, etc.
  // Returns null for unparseable input (browser falls back to black with
  // alpha 0, which we detect and treat as a parse failure unless the
  // input clearly meant transparent).
  //
  // Pulsar uses Tailwind v4 semantic tokens (`oklch(...)` via CSS
  // variables); a regex-only parser misses these.
  let _canvas = null;
  let _ctx = null;
  function ensureCanvas() {
    if (_ctx) return _ctx;
    _canvas = document.createElement("canvas");
    _canvas.width = 1;
    _canvas.height = 1;
    _ctx = _canvas.getContext("2d", { willReadFrequently: true });
    return _ctx;
  }

  function parseColor(input) {
    if (!input) return null;
    const str = String(input).trim();
    if (!str) return null;
    if (str === "transparent" || str === "rgba(0, 0, 0, 0)") {
      return { r: 0, g: 0, b: 0, a: 0 };
    }
    // Fast-path rgb()/rgba() — the canvas approach loses sub-pixel alpha
    // precision (alpha is stored as a 0–255 int in the bitmap), so prefer
    // the regex when it works.
    let m = str.match(/^rgba?\(\s*([\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)(?:[,\s/]+([\d.]+%?))?\s*\)$/i);
    if (m) {
      let a = m[4] === undefined ? 1 : parseFloat(m[4]);
      if (typeof m[4] === "string" && m[4].endsWith("%")) a = a / 100;
      return { r: parseFloat(m[1]), g: parseFloat(m[2]), b: parseFloat(m[3]), a };
    }
    // Hex fast-path.
    m = str.match(/^#([0-9a-f]{3,8})$/i);
    if (m) {
      const hex = m[1];
      if (hex.length === 3) {
        return {
          r: parseInt(hex[0] + hex[0], 16),
          g: parseInt(hex[1] + hex[1], 16),
          b: parseInt(hex[2] + hex[2], 16),
          a: 1,
        };
      }
      if (hex.length === 6) {
        return {
          r: parseInt(hex.slice(0, 2), 16),
          g: parseInt(hex.slice(2, 4), 16),
          b: parseInt(hex.slice(4, 6), 16),
          a: 1,
        };
      }
      if (hex.length === 8) {
        return {
          r: parseInt(hex.slice(0, 2), 16),
          g: parseInt(hex.slice(2, 4), 16),
          b: parseInt(hex.slice(4, 6), 16),
          a: parseInt(hex.slice(6, 8), 16) / 255,
        };
      }
    }
    // Anything else (oklch, oklab, color(), hsl, named colors, …): paint
    // through the browser. clearRect resets to (0,0,0,0); if fillStyle is
    // unrecognized, fillRect is a no-op and the readback stays (0,0,0,0).
    try {
      const ctx = ensureCanvas();
      ctx.clearRect(0, 0, 1, 1);
      // Reading fillStyle back tells us if the browser parsed the color.
      // Chrome returns the canonical form on success, the previous value
      // on failure — set a sentinel first.
      ctx.fillStyle = "rgba(0, 0, 0, 0)";
      const before = ctx.fillStyle;
      ctx.fillStyle = str;
      if (ctx.fillStyle === before && str !== "rgba(0, 0, 0, 0)") {
        // Browser rejected the color string.
        return null;
      }
      ctx.fillRect(0, 0, 1, 1);
      const px = ctx.getImageData(0, 0, 1, 1).data;
      return { r: px[0], g: px[1], b: px[2], a: px[3] / 255 };
    } catch (_e) {
      return null;
    }
  }

  // sRGB → linear, per WCAG 2.x relative-luminance formula.
  function channelLuminance(c8) {
    const c = c8 / 255;
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  }

  function luminance(rgb) {
    return (
      0.2126 * channelLuminance(rgb.r) +
      0.7152 * channelLuminance(rgb.g) +
      0.0722 * channelLuminance(rgb.b)
    );
  }

  function contrastRatio(fg, bg) {
    const L1 = luminance(fg);
    const L2 = luminance(bg);
    const lighter = Math.max(L1, L2);
    const darker = Math.min(L1, L2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  // Composite `over` on top of `under` (Porter-Duff source-over).
  function compositeOver(over, under) {
    if (!over) return under;
    if (over.a >= 1) return { r: over.r, g: over.g, b: over.b, a: 1 };
    const a = over.a + under.a * (1 - over.a);
    if (a === 0) return { r: 0, g: 0, b: 0, a: 0 };
    return {
      r: (over.r * over.a + under.r * under.a * (1 - over.a)) / a,
      g: (over.g * over.a + under.g * under.a * (1 - over.a)) / a,
      b: (over.b * over.a + under.b * under.a * (1 - over.a)) / a,
      a,
    };
  }

  // Walks up the DOM resolving the effective background color of `el`,
  // compositing semi-transparent ancestors onto the eventual opaque
  // ancestor (or white as the canvas default).
  function effectiveBackground(el) {
    let stack = [];
    let node = el;
    while (node && node.nodeType === 1) {
      const style = window.getComputedStyle(node);
      const bg = parseColor(style.backgroundColor);
      if (bg && bg.a > 0) stack.push(bg);
      if (bg && bg.a >= 1) break;
      node = node.parentElement;
    }
    // Fall back to canvas (white). The browser default-canvas color cannot
    // be observed via getComputedStyle reliably.
    let composed = { r: 255, g: 255, b: 255, a: 1 };
    for (let i = stack.length - 1; i >= 0; i--) {
      composed = compositeOver(stack[i], composed);
    }
    return composed;
  }

  // -- Per-element measurements ---------------------------------------------

  function describe(el) {
    const id = el.getAttribute("data-fixture-cell");
    const role = el.getAttribute("role") || el.tagName.toLowerCase();
    return { id, tagName: el.tagName.toLowerCase(), role };
  }

  function measureTargetSize(el) {
    const rect = el.getBoundingClientRect();
    return {
      width: Math.round(rect.width * 100) / 100,
      height: Math.round(rect.height * 100) / 100,
      pass24: rect.width >= 24 && rect.height >= 24,
    };
  }

  function measureTextContrast(el) {
    const style = window.getComputedStyle(el);
    const fg = parseColor(style.color);
    if (!fg) return { ratio: null, reason: "unparseable-color" };
    const bg = effectiveBackground(el);
    // Composite the fg's alpha onto the bg too — semi-transparent text on
    // an opaque bg renders against the bg.
    const fgEffective = compositeOver(fg, bg);
    const ratio = contrastRatio(fgEffective, bg);
    const fontPx = parseFloat(style.fontSize) || 0;
    const fontWeight = parseInt(style.fontWeight, 10) || 400;
    // WCAG defines "large text" as 18pt (24px) normal, or 14pt (≈18.66px) bold.
    const isLarge = fontPx >= 24 || (fontPx >= 18.66 && fontWeight >= 700);
    const threshold = isLarge ? 3.0 : 4.5;
    return {
      ratio: round(ratio, 2),
      fg: rgbString(fgEffective),
      bg: rgbString(bg),
      fontPx: round(fontPx, 1),
      fontWeight,
      isLargeText: isLarge,
      threshold,
      pass: ratio >= threshold - 0.005,
    };
  }

  function measureBorderContrast(el) {
    const style = window.getComputedStyle(el);
    const widthPx = parseFloat(style.borderTopWidth) || 0;
    if (widthPx <= 0 || style.borderTopStyle === "none") {
      return { ratio: null, reason: "no-border" };
    }
    const borderColor = parseColor(style.borderTopColor);
    if (!borderColor || borderColor.a === 0) {
      return { ratio: null, reason: "no-border" };
    }
    const parent = el.parentElement;
    const adjacentBg = parent ? effectiveBackground(parent) : { r: 255, g: 255, b: 255, a: 1 };
    const borderEffective = compositeOver(borderColor, adjacentBg);
    const ratio = contrastRatio(borderEffective, adjacentBg);
    return {
      ratio: round(ratio, 2),
      color: rgbString(borderEffective),
      bg: rgbString(adjacentBg),
      widthPx: round(widthPx, 1),
      threshold: 3.0,
      pass: ratio >= 2.995,
    };
  }

  // Pulsar focus indicators are painted by Tailwind v4's `ring-*` utilities
  // under the `focus-visible:` variant. Tailwind composes the ring through
  // CSS variables:
  //
  //   --tw-ring-color   — the ring color (set by `ring-<name>`)
  //   --tw-ring-shadow  — `0 0 0 (Npx + offset) <color>`
  //   --tw-ring-offset-shadow — `0 0 0 <offset>px <offset-color>`
  //
  // and `box-shadow` resolves to `var(--tw-ring-offset-shadow), var(--tw-ring-shadow), …`.
  // In Chromium, the composed `box-shadow` reads back as multiple
  // 0-spread/0-blur transparent layers when these variables haven't been
  // assigned values — even when `:focus-visible` matches at the same
  // instant. The reliable signal is the variables themselves, which the
  // focus-visible utility sets directly. Native focus indicators (no
  // Tailwind ring) fall back to `outline-*`.
  function measureFocusRing(el) {
    if (typeof el.focus !== "function") return { ratio: null, reason: "not-focusable" };
    const previousActive = document.activeElement;
    try {
      try {
        el.focus({ preventScroll: true, focusVisible: true });
      } catch (_e) {
        el.focus({ preventScroll: true });
      }
      // Some browsers update :focus-visible state only after a paint —
      // force one before reading.
      void el.offsetWidth;

      // Disabled / inert / tabindex="-1" elements ignore .focus() — the
      // focus-visible state never engages. Report as not focusable rather
      // than reading the unfocused box-shadow (which is typically a drop
      // shadow giving a misleading low-contrast number).
      if (document.activeElement !== el) {
        return { ratio: null, reason: "not-focusable-in-state" };
      }

      const style = window.getComputedStyle(el);

      // Native outline (rendered only when style is not none/hidden).
      const outlineStyle = style.outlineStyle;
      const outlineWidth = parseFloat(style.outlineWidth) || 0;
      const outlineColor = parseColor(style.outlineColor);
      if (
        outlineStyle !== "none" &&
        outlineStyle !== "hidden" &&
        outlineWidth > 0 &&
        outlineColor &&
        outlineColor.a > 0
      ) {
        return contrastResult("outline", outlineColor, outlineWidth, el);
      }

      // Tailwind ring via CSS variables. --tw-ring-shadow being non-empty
      // (and not the default "0 0 #0000") tells us a `ring-*` utility is
      // currently active.
      const ringShadow = (style.getPropertyValue("--tw-ring-shadow") || "").trim();
      const ringColorVar = (style.getPropertyValue("--tw-ring-color") || "").trim();
      const ringActive =
        ringShadow && ringShadow !== "0 0 #0000" && ringShadow !== "0 0 rgba(0, 0, 0, 0)";

      if (ringActive && ringColorVar) {
        const ringColor = parseColor(ringColorVar);
        if (ringColor && ringColor.a > 0) {
          const widthPx = extractRingWidth(ringShadow) || 2;
          return contrastResult("ring", ringColor, widthPx, el);
        }
      }

      // Last resort: parse the resolved box-shadow value. Picks the layer
      // with greatest spread; skips drop shadows (spread = 0, blur > 0).
      const ringFromShadow = parseFirstRingShadow(style.boxShadow);
      if (ringFromShadow) {
        return contrastResult("ring", ringFromShadow.color, ringFromShadow.widthPx, el);
      }

      return { ratio: null, reason: "no-focus-ring" };
    } finally {
      if (previousActive && typeof previousActive.focus === "function") {
        try {
          previousActive.focus({ preventScroll: true });
        } catch (_e) {
          // best-effort restore
        }
      } else if (typeof el.blur === "function") {
        el.blur();
      }
    }
  }

  function contrastResult(kind, color, widthPx, el) {
    const parent = el.parentElement;
    const adjacentBg = parent ? effectiveBackground(parent) : { r: 255, g: 255, b: 255, a: 1 };
    const effective = compositeOver(color, adjacentBg);
    const ratio = contrastRatio(effective, adjacentBg);
    return {
      kind,
      ratio: round(ratio, 2),
      color: rgbString(effective),
      bg: rgbString(adjacentBg),
      widthPx: round(widthPx, 1),
      threshold: 3.0,
      pass: ratio >= 2.995,
    };
  }

  // Tailwind ring shadow string: `0 0 0 calc(2px + 2px) oklch(…)` or
  // `0 0 0 4px <color>`. Width is the spread (4th length). Ignore the
  // calc() inner expression — we only need the resolved px count for
  // reporting.
  function extractRingWidth(ringShadow) {
    const calcMatch = ringShadow.match(/calc\(([^)]+)\)/);
    if (calcMatch) {
      // Sum pixel constants inside the calc expression.
      let sum = 0;
      const pxParts = calcMatch[1].match(/-?[\d.]+px/g) || [];
      for (const p of pxParts) sum += parseFloat(p);
      if (sum > 0) return sum;
    }
    const direct = ringShadow.match(/(-?[\d.]+)px/g) || [];
    if (direct.length >= 4) return parseFloat(direct[3]);
    return null;
  }

  // Tailwind's `ring-* ring-offset-*` produces two box-shadow layers:
  // `0 0 0 <offset-w>px <offset-color>, 0 0 0 <ring-w + offset-w>px <ring-color>`.
  // The first layer is the offset (background color, creating a gap); the
  // second is the actual ring. Picking the first layer reports near-zero
  // contrast (offset vs adjacent bg are by design near-equal). The correct
  // signal is the layer with the greatest spread — the outermost ring.
  function parseFirstRingShadow(boxShadow) {
    if (!boxShadow || boxShadow === "none") return null;
    // Split on top-level commas — rgb()/rgba() contain commas.
    const layers = splitTopLevelCommas(boxShadow);
    const parsed = [];
    for (const layer of layers) {
      // Color match: capture rgb/rgba (including space-separated rgb()
      // returned by some browsers), oklch/oklab/color() functions, or hex.
      const colorMatch = layer.match(
        /(rgba?\([^)]+\)|oklch\([^)]+\)|oklab\([^)]+\)|color\([^)]+\)|hsla?\([^)]+\)|#[0-9a-f]{3,8})/i,
      );
      if (!colorMatch) continue;
      const color = parseColor(colorMatch[1]);
      if (!color || color.a === 0) continue;
      const rest = (
        layer.slice(0, colorMatch.index) + layer.slice(colorMatch.index + colorMatch[0].length)
      ).trim();
      const lens = rest.match(/-?[\d.]+px/g) || [];
      // x y blur spread. Spread is the relevant width for ring shadows.
      const spread = lens[3] ? parseFloat(lens[3]) : 0;
      const blur = lens[2] ? parseFloat(lens[2]) : 0;
      const widthPx = spread > 0 ? spread : blur;
      if (widthPx <= 0) continue;
      parsed.push({ color, widthPx });
    }
    if (parsed.length === 0) return null;
    // Outermost layer wins (greatest spread).
    parsed.sort((a, b) => b.widthPx - a.widthPx);
    return parsed[0];
  }

  function splitTopLevelCommas(s) {
    const out = [];
    let depth = 0;
    let start = 0;
    for (let i = 0; i < s.length; i++) {
      const ch = s[i];
      if (ch === "(") depth++;
      else if (ch === ")") depth--;
      else if (ch === "," && depth === 0) {
        out.push(s.slice(start, i).trim());
        start = i + 1;
      }
    }
    out.push(s.slice(start).trim());
    return out;
  }

  // -- Overflow detection ---------------------------------------------------

  // A cell overflows if its inner content exceeds its layout box. Returns
  // the list of cell IDs whose scrollWidth/scrollHeight exceeds their
  // clientWidth/clientHeight by more than 1 px (sub-pixel rounding noise).
  function detectOverflows() {
    const cells = document.querySelectorAll("[data-fixture-cell]");
    const overflows = [];
    cells.forEach((el) => {
      const tol = 1;
      const overflowsX = el.scrollWidth - el.clientWidth > tol;
      const overflowsY = el.scrollHeight - el.clientHeight > tol;
      if (overflowsX || overflowsY) {
        overflows.push({
          id: el.getAttribute("data-fixture-cell"),
          x: overflowsX,
          y: overflowsY,
          scrollWidth: el.scrollWidth,
          clientWidth: el.clientWidth,
          scrollHeight: el.scrollHeight,
          clientHeight: el.clientHeight,
        });
      }
    });
    return overflows;
  }

  function applyTextSpacingOverride() {
    if (document.getElementById(TEXT_SPACING_STYLE_ID)) return;
    const style = document.createElement("style");
    style.id = TEXT_SPACING_STYLE_ID;
    style.textContent = TEXT_SPACING_CSS;
    document.head.appendChild(style);
  }

  function removeTextSpacingOverride() {
    const style = document.getElementById(TEXT_SPACING_STYLE_ID);
    if (style) style.remove();
  }

  // CSS-level reflow simulation. PlaywrightEx doesn't expose live viewport
  // resize, so we constrain html+body width and re-check overflow. Caveat:
  // CSS media queries based on viewport width don't trigger — for Pulsar
  // this is acceptable because components are content-driven (no fixed
  // widths or min-widths called out in the 1.4.10 audit evidence). Flagged
  // overflows under this mode confirm a reflow gap; non-overflows confirm
  // the worst-case render fits in 320 CSS px.
  function applyReflowConstraint(width) {
    if (document.getElementById(REFLOW_STYLE_ID)) return;
    const style = document.createElement("style");
    style.id = REFLOW_STYLE_ID;
    style.textContent = `
      html, body {
        width: ${width}px !important;
        max-width: ${width}px !important;
        overflow-x: visible !important;
      }
    `;
    document.head.appendChild(style);
  }

  function removeReflowConstraint() {
    const style = document.getElementById(REFLOW_STYLE_ID);
    if (style) style.remove();
  }

  // -- Top-level --------------------------------------------------------------

  function measureAll() {
    const cells = Array.from(document.querySelectorAll("[data-fixture-cell]")).map((el) => ({
      ...describe(el),
      rect: measureTargetSize(el),
      text: measureTextContrast(el),
      border: measureBorderContrast(el),
      focusRing: measureFocusRing(el),
    }));
    return {
      url: window.location.pathname,
      theme: document.documentElement.dataset.theme || "light",
      viewport: { width: window.innerWidth, height: window.innerHeight },
      cells,
    };
  }

  // -- Helpers --------------------------------------------------------------

  function round(n, places) {
    if (n === null || n === undefined || Number.isNaN(n)) return null;
    const factor = Math.pow(10, places);
    return Math.round(n * factor) / factor;
  }

  function rgbString(rgb) {
    if (!rgb) return null;
    const r = Math.round(rgb.r);
    const g = Math.round(rgb.g);
    const b = Math.round(rgb.b);
    if (rgb.a >= 1) return `rgb(${r}, ${g}, ${b})`;
    return `rgba(${r}, ${g}, ${b}, ${round(rgb.a, 3)})`;
  }

  // Whole-page reflow check: returns true if document.scrollWidth exceeds
  // the constraint width. Used alongside detectOverflows() — the latter is
  // per-cell, this is page-level.
  function pageOverflowsHorizontally(width) {
    return document.documentElement.scrollWidth > width + 1;
  }

  window.PulsarA11yMeasure = {
    measureAll,
    applyTextSpacingOverride,
    removeTextSpacingOverride,
    applyReflowConstraint,
    removeReflowConstraint,
    pageOverflowsHorizontally,
    detectOverflows,
    // Exposed for unit testing in the browser console.
    _internal: { parseColor, contrastRatio, effectiveBackground, luminance },
  };
})();
