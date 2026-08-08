# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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