# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed - Ghost Variants No Longer Carry Card Elevation

- **`button`'s `ghost` variant no longer renders `shadow-card hover:shadow-dropdown`**: ghost is flat chrome — no fill, no border, no lift — so it can sit in a header or toolbar without competing with the controls around it. `solid` and `outline` are unchanged and keep their elevation; `link` is unaffected. Ghost keeps its `hover:scale-[1.02] active:scale-[0.98]` press affordance — only the resting and hover shadow are gone. Anyone who wants an elevated ghost button can pass `class="shadow-card"`, which Twm composes normally.
- **`checkbox`'s `card` layout no longer lifts on hover in the `ghost` variant**: `hover:shadow-card` is gone, for the same reason — a ghost card is a selectable region, not a raised surface. The `solid` (`hover:shadow-card`) and `outline` (`hover:shadow-dropdown`) card variants are unchanged, and the ghost card keeps its `hover:bg-*/10` tint and checked-state background, so hover and selection remain visible.
- **`switch`'s `ghost` variant thumb no longer renders `shadow-dropdown shadow-black/6`**: it was the last ghost surface in the library still carrying resting elevation, so a ghost switch sat visibly raised next to the ghost buttons in the same toolbar. The thumb keeps `border border-border-strong`, which is what separates it from the track. `solid` (`shadow-modal`) and `outline` (`shadow-dropdown`) thumbs are unchanged.
- **`button`'s `ghost` variant now styles its `pressed` state**: a ghost toggle button rendered `aria-pressed="true"`/`data-pressed="true"` but was pixel-identical to the unpressed one, so the state reached screen readers and nobody else. Ghost now carries `data-[pressed=true]:bg-<color>/15` (and `data-[pressed=true]:hover:bg-<color>/25`, so a pressed button still responds to hover); `neutral` uses the `surface-1-active`/`surface-2-active` tokens.
- **`checkbox`'s and `radio_group`'s `card` layouts no longer react to hover when disabled**: both cards set `cursor-not-allowed` and `opacity-disabled` but not `pointer-events-none`, so a disabled card still ran its `hover:bg-*` tint and (for `checkbox`'s `solid`/`outline`) its hover shadow — advertising a click that does nothing. Adding `pointer-events-none` matches what `button`, `switch`, `input`, `select`, and `textarea` already do.
- **`checkbox`'s `neutral` cards now tint neutral instead of primary**: the `ghost` and `outline` card variants painted `has-[:checked]:bg-primary/10` for `color="neutral"`, so an explicitly neutral card turned the theme's primary hue when checked and disagreed with both its own `solid` variant and `radio_group`'s neutral ghost card. They now use `bg-neutral/15` (ghost) and `bg-neutral/10` (outline), so neutral checkbox cards and neutral radio cards match on the same screen.

These are rendering changes to the shipped `Pulsar.Components.*` modules, so apps that consume Pulsar as a dependency pick them up on `mix deps.update pulsar`. Apps that generated their own copies keep them until they regenerate.

### Changed (Breaking) - Components No Longer Invent Random ids

- **`id` is now required on components whose id is referenced from outside their own render**: `accordion`, `collapsible`, `popover`, `tabs`, `flash`, `sidebar`, `menu`, `menu_group`, `dropdown_menu`, `dropdown_menu_submenu`, `modal`, `table`, `drawer`, `alert_dialog`, and `tooltip`. Each of these either puts `phx-hook` on the element carrying the id, or keys a JS command helper on it, or expects the caller to point `aria-*` at it, or derives further ids from it for LiveView stream targets (`table` builds `"<id>-tbody"` and `"<id>-empty"`). The id was previously built from `System.unique_integer/1`, which is per-call rather than per-element — so a LiveView's disconnected render shipped different ids than the connected render that replaced it, morphdom rebuilt the element instead of reusing it, and any colocated hook remounted and lost its client state. A function component has no render-stable identity to derive from, so the id has to come from the caller, the same contract `live_component` already has. **Migration:** add an `id` to these components. `mix compile` flags call sites in `.heex` and `.ex` sources, but only as a *warning* — the build still succeeds, and a call site you skip fails at render time with a `KeyError`, not at build time. Sources that `mix compile` never reads need a manual sweep: grep the fifteen component names across your `.exs` files (component tests, and `.story.exs` storybook stories, which PhoenixStorybook compiles at page load — so the first signal there is a broken page) and any `.eex` templates. `mix compile --warnings-as-errors` will not catch those.
- **`calendar` and `date_picker` raise when the id cannot be derived**: both hold selection state in a colocated hook, and neither declares a `name` attr to fall back to. A bound instance still derives its id from the form field; an unbound one now requires an explicit `id` instead of silently generating one that changes each render. Because the derivation is purely a function of the field, two instances bound to the *same* field now derive the *same* id — previously the random suffix made them accidentally distinct. Give at least one of them an explicit `id` when you render a field twice (a range's start and end pickers, a compact and an expanded calendar on one page).

### Fixed - Components No Longer Emit Unreferenced or Duplicate ids

- **`button` and `navbar` emit no `id` unless the caller supplies one**: nothing referenced either. `button`'s `phx-hook` is only on the `as={:a}` and `as={:div}` pseudo-button branches, which still generate an id because LiveView requires one there; the native `<button>` branch emitted an id that appeared in no selector, no `aria-*` reference, and no hook.
- **`alert`, `menu_section`, and `dropdown_menu_group` generate an id only when one is used**: `alert` when `dismissible` (for the dismiss button's `aria-controls`), the two section components when a `label` is present (for `aria-labelledby`).

  Six branches still generate a per-render id, not fixed here. Four are settled trade-offs. The three above churn only when the referencing markup is present, but nothing outside that render points at those ids, so the churn costs an attribute diff and no client state. `button` with `as={:a}` or `as={:div}` churns on a `phx-hook` root — but the branches accept `href`/`navigate`, so requiring an id would break every `<.button href={...}>` call site, and the hook only attaches listeners, so remounting it loses nothing.

  The other two sit on hook roots that hold real client state, and closing either means a contract change. `input_otp` with neither a `field`, a `name`, nor an `id` derives its hook root's id (`"<id>-otp"`) from a generated value, so a disconnected-to-connected swap remounts that hook and wipes a partially typed code. `radio_group` with neither a `field` nor a `name` also lands a generated id on a hook root. Both were left alone because neither case is reachable from a wired-up call: a radio group with no field and no name submits nowhere, and `on_complete` runs a `%JS{}` command without sending the field value, so a fieldless, nameless `input_otp` has no path to the server for the code either. Bind a field — or keep the component in a form — and the id is stable. Pass an explicit `id` to pin any of these six; for `radio_group` and `input_otp`, a `name` works too.
- **Form inputs derive their id from `name` before generating one**: `input`, `checkbox`, `switch`, `radio_group`, `select`, and `textarea` now resolve caller `id`, then `field.id`, then `name`, then a generated value. An unbound input with a `name` had a stable source going unused. Five of the six only ever reach the generated rung on the bound path, because unbound they require a `name`: `input`, `checkbox`, and `switch` raise without one, as do `select` and `textarea`. `radio_group` is the exception — it has no such check, so an unbound group with neither a `field` nor a `name` still falls through to a generated id (see the accepted-limitations note above).

  The `name` is normalized into id shape on the way — `user[notifications]` becomes `user_notifications`, matching what Phoenix's own `field.id` would have produced for that field, and `tags[]` becomes `tags_`. A raw name is not id-shaped: `switch` interpolates its resolved id into a CSS selector for the click-target overlay (`to: "#<id>"`), and `#user[notifications]` parses as `#user` plus an attribute selector, matching nothing and leaving the overlay dead.

  Normalization does not make the id *unique*, and it cannot: siblings that intentionally share a `name` derive the same id, so `<.checkbox :for={t <- tags} name="tags[]" value={t} />` renders `id="tags_"` on every instance. This is the same behavior a shared `field` has always had in Phoenix — `field.id` is a function of the field, not of the instance — and the fix is the same: pass an explicit `id` per instance. Duplicate ids on a `phx-hook` root give morphdom an ambiguous match target, so this matters beyond `<label for>`.
- **`select` declares an `:id` attr, so a caller-supplied `id` reaches the `<select>` element**: it had none, so `id` was an HTML global that landed in `@rest` while `assigns[:id]` stayed `nil` — the element rendered the name-derived id *and* re-spread the caller's from `@rest`, two `id` attributes on one tag. Browsers keep the first, so the caller's id was silently dropped and any `<label for>` pointing at it matched nothing, costing the select its accessible name. `<.field type="select">` passes an id on every render, so this fired for every field-wrapped select, not just direct calls. No change for callers who never passed an `id`.
- **`flash_group` derives child flash ids from a stable group id**: children were keyed on `System.unique_integer/1`, feeding a fresh id per render into `flash`'s hook root. The group takes an `id` defaulting to `"flash-group"` and derives children as `"<id>-<type>"`, matching Phoenix's own `flash_group`. Because that default is now a constant rather than a fresh integer per call, two id-less groups on one page emit identical child ids on a `phx-hook` root — give each group an explicit `id` when you render more than one.
- **The generated `CoreComponents` wrappers no longer emit a caller's `id` twice**: `assigns_to_attributes/2` returns the `:rest` key itself, so `{@extra}` assigned the wrapped Pulsar component's `:rest` map wholesale and `{@rest}` then re-spread the same keys — binding `id` to the declared attr *and* leaving a copy in `@rest`. `<.button id="x">` produced two `id` attributes on one tag. Fixed in `button`, `header`, `table`, and `list`.

### Fixed - Generated Themes Declare `color-scheme`

- **Generated themes now declare `color-scheme`, so browser-drawn UI matches the theme's polarity**: swapping semantic tokens repaints only what CSS paints. Scrollbars, `<select>` popup lists, `<input type="date">` and `type="time"` pickers, the autofill overlay, and spellcheck menus are drawn by the browser and read `color-scheme` — nothing else, not even a `background-color` on `<body>`. A page under `[data-theme="dark"]` therefore painted dark surfaces while its scrollbars and dropdowns stayed light. `themes/light.css` now carries `color-scheme: light` in a bare `:root` rule (covering apps that never set `data-theme`) and in its `[data-theme="light"], .theme-light` block (so a light subtree nested inside a dark ancestor flips its chrome back); `themes/dark.css` carries `color-scheme: dark`. The declaration sits outside the `@theme` block because Tailwind v4 accepts only custom properties and `@keyframes` there. Note that the viewport scrollbar reads the root element only — set the theme on `<html>` if you want it to follow.
- **`mix pulsar.gen.theme <name> --dark` sets a scaffolded theme's polarity**: with `:root` now declaring `light`, a scaffolded theme that declares nothing inherits light polarity and reproduces the bug above. Themes scaffolded without the flag declare `color-scheme: light`; `--dark` declares `color-scheme: dark`. The flag has no effect on the bare `mix pulsar.gen.theme` install path, which generates the built-in light and dark pair.

### Fixed - Generated Storybook Uses Semantic Radius Tokens

- **Generated storybook stories no longer hardcode raw Tailwind radii on themed surfaces**: the Dark mode page's sample cards and the Resizable story's panel containers said `rounded-lg`, the Typography page's inline code chip said `rounded-md`, and the Login example's card said `rounded-xl` — while the Themes page prescribes `rounded-box`/`rounded-field` for exactly those surfaces. They now use the semantic tokens, so `--radius-box`/`--radius-field` overrides reach every generated story surface. Visually identical under the default theme except the login card (0.75rem → 0.5rem, now matching the real Card component's radius).
- **The Link story's variant control defaults to `"outline"` again**: the story template still said `"solid"` from before the component's default changed to always-underlined links, so generated storybooks documented a default the component doesn't have. The story now matches the component.

### Fixed - Generated Components No Longer Reference Stellar

- **Generated components no longer claim Stellar provenance**: the `select/1`, `radio_group/1`, and `textarea/1` moduledocs said the component was "built on Stellar.Components.*" — a library Pulsar does not depend on — and eight component templates carried Stellar provenance comments, all of which shipped into user apps via the generators. The moduledocs now describe the component itself and the comments are gone. No behavior change.

### Changed - Disabled Items Are Keyboard-Reachable

- **`dropdown_menu/1`, `tabs/1`, and `accordion/1` no longer skip disabled items in keyboard navigation**: arrow keys, Home/End, and (in menus) typeahead now reach a disabled item, so screen-reader users can discover it and hear why it's there — per the APG recommendation that disabled items in composite widgets stay focusable. Activation stays blocked: Enter, Space, and click do nothing on a disabled item, a disabled submenu trigger never opens its submenu, and focusing a disabled tab leaves the current tab selected (selection still follows focus onto enabled tabs).
- **Disabled tabs and accordion headers no longer render the native `disabled` attribute** (a natively disabled button cannot receive focus): they carry `aria-disabled="true"` instead, as dropdown menu items already did. Anything targeting these buttons with `[disabled]` in CSS or tests should target `[aria-disabled="true"]`.

### Added - Dropzone Component

- **`dropzone/1`** (`mix pulsar.gen.dropzone`): a file-upload dropzone for LiveView uploads. Renders a clickable, keyboard-operable upload zone for an `allow_upload/3` config — drag-and-drop via `phx-drop-target`, click-to-browse via a zone-wide label around `live_file_input`, image previews (`live_img_preview`), per-entry progress bars, and cancel buttons. The four LiveView upload errors render as overridable message attrs (`too_large_message`, `not_accepted_message`, `too_many_files_message`, `external_client_failure_message`); cancel defaults to pushing `"cancel-upload"` with the entry ref and accepts an `on_cancel` override (`%JS{}` or `(entry) -> %JS{}`). Carries the house `variant`/`color`/`size` axes (dashed-outline default) and composes `Icon` and `Progress`. The drag-over highlight and prompt swap key off LiveView's built-in `phx-drop-target-active` class, so the component ships no JavaScript of its own; this raises Pulsar's `phoenix_live_view` requirement to `~> 1.2` (the class shipped in LiveView 1.2.0). WCAG 2.2 AA audited (`docs/a11y/dropzone.md`).

### Fixed - Content-Security-Policy

- **No component renders an inline `style` attribute**: under a CSP whose `style-src` lacks `'unsafe-inline'`, browsers drop inline style declarations silently — no error, no fallback. Four sites were affected: resizable panels ignored `default_size` and collapsed to their flex default, progress bars rendered the track but never filled, and staggered flash animations lost their per-item delay. Dynamic values now reach CSS either as a static utility class or as an SVG presentation attribute, which CSP does not govern. A nonce would not have helped: nonces whitelist `<style>` and `<script>` *elements*, not style *attributes*. Pulsar now runs under `style-src 'self'` with no consumer configuration.
- **The storybook theme-swatch template was affected too**: `mix pulsar.gen.storybook` shipped a swatch whose colour came from an inline style, so every swatch rendered as an empty bordered box under a strict CSP. It now uses an SVG `<rect>` with a `fill-*` class.
- **Flashes 2 through 5 never animated**: `flash_group/1`'s per-item stagger was applied as an inline `transition-delay`, but LiveView strips a `JS.show` transition's classes after its `time` window, which defaults to 200ms. With the default `stagger_delay: 100`, the second flash had its transition cut in half and the third through fifth were skipped entirely. The delay is now a `delay-*` class inside the transition, and `time` is extended to cover it.

### Changed - Progress and Resizable Rendering

- **`progress/1`'s determinate linear fill is now an SVG `<rect>`**, not a `<div>`. The track is unchanged. Anyone targeting the fill element by structure or by its `bg-*` class should target the `<rect>` and its `fill-*` class instead. The radial shape is unchanged — it already drove its fill through SVG attributes.
- **`flash_group/1`'s `stagger_delay` is snapped to a supported step**: `0, 75, 100, 150, 200, 300, 500, 700, 1000` ms. The attr keeps its type and default, but a value off that scale now renders as the nearest one, because only classes written literally in source exist at runtime.
- **`resizable/1`'s initial size is applied by its hook**: a static render without JavaScript shows the fixed 30% fallback regardless of `default_size`. Dragging a separator already required JavaScript; this extends that to the initial size. There is no CSP-safe way to emit an arbitrary integer percentage as a class.

### Added - CSP Documentation

- **`docs/csp.md`** states which policy Pulsar supports: no `style-src 'unsafe-inline'` is required, but **`img-src 'self' data:` is** — Heroicons are applied as CSS masks whose source is a `data:` URI, and CSS-referenced images are governed by `img-src`. Confirmed in a browser: under `default-src 'self'` alone, Chrome blocks the mask and the icon renders with no visible content. A guard test (`Pulsar.NoInlineStyleTest`) now fails the build if an inline style attribute reappears in a component, template, or storybook source.

### Breaking - Required-Field Accessible Name

- **`label/1` no longer accepts `sr_required_text`**: the screen-reader-only "(required)" `<span>` and the `aria-hidden` asterisk `<span>` have both been removed. The required asterisk is now a Tailwind `after:content-['*']` pseudo-element on the `<label>` element itself, and required state is announced from the associated control's `required` attribute (or, for the date-picker's typeable display inputs, `aria-required`) instead. This changes the accessible name of every required field from `"Label (required)"` to exactly `"Label"`, and it also means the label's visible text content is now exactly its label text — so a required field can be found by exact-label matching (`fill_in("Email", ...)`), which previously failed because the rendered text included the "(required)" suffix. Call sites passing `sr_required_text` will emit a compile-time undefined-attribute warning; remove the attr.

### Added - Required-Field Legend

- **`form/1` accepts `required_legend` and `required_legend_text`**: set `required_legend={true}` to render an `aria-hidden` legend (default text "indicates a required field") at the top of the form, explaining what the asterisk on required labels means now that it's no longer spelled out per-field.

### Fixed - Date Picker Required State

- **`date_picker/1` accepts `required`**: sets `aria-required` on the visible display input(s), and `field/1` now forwards `required` for `type="date"` and `type="daterange"`. Native `required` isn't used because the display inputs are formatted text, not the field's submitted value.

### Fixed - Non-GET Menu Items

- **`dropdown_menu_item/1` and `menu_item/1` accept `method`**: a menu row can now perform a POST/PUT/DELETE — `<.dropdown_menu_item href={~p"/sign-out"} method="delete">Sign out</.dropdown_menu_item>`. Previously `method` was rejected as an undefined attribute, which failed the build for apps compiling with `--warnings-as-errors`, so no menu item could sign a user out or otherwise mutate the session. `csrf_token`, `download`, `target`, and `rel` are accepted alongside it.
- **`method` requires `href`**: pairing it with `navigate` or `patch` raises `ArgumentError` rather than silently issuing a GET, matching `Pulsar.Components.Link.a/1`. `method` is also confined to the link branch, so it no longer lands on the `<button>` an item without a target renders.

### Fixed - Idempotent Generator Re-runs

- **No more `.bak` files**: Re-running `mix pulsar.install` or a `mix pulsar.gen.*` task over an already-installed project no longer writes timestamped backup files; Igniter's own diff/confirmation prompt (and git) are the safety net.
- **True no-op on an unchanged project**: Re-running the installer over a project whose generated files haven't been touched now writes nothing.
- **`assets/css/app.css` is host-owned**: The theme installer only ensures the single `@import "./theme.css";` line is present; it no longer regenerates the rest of the file.
- **`@source` globs are no longer mistaken for CSS comments**: Phoenix's generated `app.css` contains `@source ".../phoenix-colocated/my_app/*/";`, whose glob holds a literal `/*`. That was read as a comment opener, hiding every line after it — so the theme `@import` looked absent and a duplicate was appended on each run. Comment detection now understands quoted strings.

### Changed - Dependencies

- Upgraded `phoenix_storybook` to `~> 1.3` (dev/test only), which drops the retired, unpatched `earmark` dependency (GHSA-52mm-h59v-f3c7) and lifts the LiveView 1.1 cap, so the suite now runs against LiveView 1.2.
- Upgraded `mint` to 1.9.3, resolving four advisories including two rated high.
- Routine upgrades within existing requirements: `phoenix_live_view` 1.2.8, `igniter` 0.8.3, `tailwind` 0.5.1, `bandit` 1.12.4, `ecto` 3.14.1, `lazy_html` 0.1.12. The Tailwind CLI stays pinned at 4.1.12, so generated CSS is unchanged.
- Upgraded the accessibility test stack (test-only): `a11y_audit` to `~> 0.4`, which moves axe-core from 4.11 to 4.12.1, and `phoenix_test_playwright` to `~> 0.15` alongside Playwright 1.62.1.

### Changed - Twm Adoption

- **BREAKING**: Replaced `bigrefactor/tailwind_merge` runtime dependency with [`twm`](https://hex.pm/packages/twm) (`~> 0.1`). Apps must update `mix.exs` and re-run `mix deps.get`. Generated components now `import Twm, only: [merge: 1]` instead of `TailwindMerge`. The install task adds `{Twm.Cache, []}` to the host app's supervision tree for LRU class-merge caching by default.
- **Tailwind v4 utility coverage**: Twm is a port of `tailwind-merge` JS v3.3.0, with native conflict-resolution for v4 utilities (`text-shadow-*`, `inset-shadow-*`, `field-sizing-*`, `mask-*`, etc.) that the previous merger did not know about.

### Changed - Self-Contained Component Library

- **BREAKING**: Complete self-contained component library implementation 
- **Single Dependency**: Only requires Twm for intelligent class merging
- **Self-Contained Components**: All 11 core components now include inlined accessibility and behavior
- **Production Ready**: Complete component coverage for Phoenix applications
- **Clean Architecture**: Zero compilation warnings, full test coverage maintained

### Added - Complete Component Library

- **Badge**: Flexible labels with variants and sizes (partial implementation)
- **Button**: Interactive buttons with loading states and colocated JavaScript hooks  
- **Checkbox**: Form checkboxes with card variants and Phoenix integration
- **Icon**: Centralized icon component with Heroicons support (partial implementation)
- **Input**: Text inputs with decorator system and validation support
- **Label**: Semantic labels with error states and accessibility
- **Link**: Navigation links with XSS protection and Phoenix routing
- **RadioGroup**: Radio button groups with ARIA semantics and card variants
- **Select**: Dropdown selects with option generation and form integration
- **Switch**: Toggle switches with Phoenix form support  
- **Textarea**: Multi-line text inputs with character counting

### Security & Accessibility

- **WCAG 2.2 AA Compliance**: All components include proper ARIA attributes (see [`docs/a11y/`](docs/a11y/README.md) for per-component audit evidence)
- **XSS Protection**: Built-in input sanitization and output escaping
- **Keyboard Navigation**: Full keyboard accessibility support
- **Screen Reader Support**: Proper semantic markup and state announcements

## [0.1.0] - 2025-09-01

### Added

- Initial release of Pulsar component generator system
- Comprehensive CI/CD pipeline with quality tools
- Core components: Button, Input, Label, Link, Textarea
- GitHub Actions workflows for CI, docs, releases, and security
- Quality tools integration: Credo, Dialyzer, ExCoveralls, MixAudit
- Documentation generation with ExDoc
- Automated Hex.pm package publishing
- Dependabot configuration for dependency management

### Dependencies

- Phoenix LiveView integration
- Twm for intelligent class composition (Tailwind v4-aware)
- Tailwind CSS utility-first styling

[0.1.0]: https://github.com/bigrefactor/pulsar/releases/tag/v0.1.0