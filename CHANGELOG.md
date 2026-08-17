# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - Combobox: A Typeahead Form Control

- **New `combobox` component**: a text input that filters a list of options as
  you type and writes the picked option into a form field. The input holds the
  query, a popover anchored to the field lists the matches, and picking one
  makes it the field's value. It carries combobox semantics
  (`role="combobox"` + `role="listbox"` with a roving `aria-activedescendant`),
  ↑/↓ to move, Enter to pick, Escape to dismiss, a chevron that opens the list
  without typing, and a clear button. Unlike `command` — which holds no value
  and runs a callback — `combobox` is a form control: it renders the hidden
  input (or hidden `<select multiple>`) your form submits.
- **`multiple` collects several values as removable badges**, each with a
  labeled dismiss control, and Backspace on an empty query removes the last one.
  The list stays open across picks so a run of selections is one interaction.
- **Filtering is a function you supply**: `filter` is `(query, options)` and
  defaults to a built-in case-insensitive subsequence matcher ranked by how
  tightly the match is packed. Pass `async` to run an I/O-bound source
  off-process — it cancels the in-flight request on the next keystroke and shows
  a spinner while it runs — and `display` to name the labels of values a remote
  source has not listed. `debounce` defaults to 0 when synchronous and 250ms
  when `async`.
- **`options` takes the same shapes as `select`**: scalars, `{label, value}`
  tuples, keyword options with `:key` and `:value` (plus optional `:icon`,
  `:description`, and `:disabled`), and `{group_label, options}` pairs, which
  render as labelled `role="group"` sections.
- **`field` dispatches to it with `type="combobox"`**, so a combobox gets the
  same label, error, and `aria-describedby` wiring as every other input type;
  `filter`, `async`, and `display` pass through.
- **`:item` and `:empty` slots** replace the default row and empty-state markup,
  and every string it renders — the empty text, the result counts, the button
  labels — is an overridable attr for `gettext`.
- Ships with a generator (`mix pulsar.gen.combobox`), a Storybook story, and a
  WCAG 2.2 AA audit at `docs/a11y/combobox.md`.

### Changed - `popover` Gains a Trigger-Less `"manual"` Mode, and Validates Its Trigger

- **`trigger_mode="manual"` renders a panel with no trigger at all**, positioned
  against whatever `anchor` points at and opened and closed entirely through
  `show/1` and `hide/1`. It exists for controls that own their own open state —
  `combobox` is the first — where the thing that opens the panel is an input the
  caller renders, not a button the popover can wire. In manual mode the panel
  exposes no `aria-expanded`/`aria-controls`/`aria-describedby` relationship of
  its own; the caller owns that relationship for the element `anchor` names.
- **The `:trigger` slot is no longer `required: true`** at the attr level, since
  manual mode has none.
- **`popover/1` now raises on a trigger/mode mismatch**, where it previously
  rendered something inert:
  - a `"click"` or `"hover"` popover with no `:trigger` raises `ArgumentError`.
    **This changes behavior for existing callers**: a host rendering a
    conditionally-empty `<:trigger :if={...}>` used to get a panel nothing could
    open, and now raises at render time. If you relied on that, guard the whole
    `<.popover>` rather than its trigger slot.
  - a `"manual"` popover with no `:anchor` raises — it has no trigger to
    position against, so without an anchor the panel would sit at the viewport
    origin.
  - a `"manual"` popover that *does* pass a `:trigger` raises, since nothing
    would wire it.

### Added - `popover` Can Be Closed and Opened From a `JS` Command

- **`Popover.show/1` and `Popover.hide/1` open and close a panel by id**, from
  the server or from any `Phoenix.LiveView.JS` chain, with `show/2` and `hide/2`
  composing onto an existing pipeline. Until now a panel in click mode could
  only be worked by its trigger, Escape, or an outside click, and there was no
  correct way to close it from code: `JS.hide` sets `display: none`, which
  leaves the element open in the top layer — still suppressing light-dismiss for
  panels beneath it, and throwing on the next `showPopover()`. The helpers call
  `hidePopover()`/`showPopover()`, the only correct close and open.
- **A form inside a panel can now submit and dismiss it** —
  `phx-submit={JS.push("apply") |> Popover.hide("filters")}` — which the native
  invoker attributes cannot express: the browser ignores `popovertarget` on any
  button that submits a form. That case previously took an app-level hook on the
  form's `submit` event.
- **A programmatic close returns focus to the trigger** when the panel owned
  focus, the way Escape does. This matters most for the submit case: LiveView
  blurs the active element while submitting, so the browser's own focus
  restoration has nothing left to restore and focus would land on `<body>`. A
  panel the user never focused into leaves focus where it is.
- The helpers work in either `trigger_mode`, and reach `dropdown_menu` and
  `tooltip` as well — both pass their own `id` to the panel they render, so
  `Popover.hide(id)` closes those too.

### Fixed - Table Keeps Focus and Streamed Rows Across a Load; Focus Rings Follow the Theme

- **A keyboard user no longer loses focus when a sortable header reloads the
  table.** The loading region rendered as a sibling before `<table>`, so
  flipping it rebuilt the table and destroyed the header the user had just
  activated — focus landed on `<body>`, and every subsequent Tab restarted from
  the top of the document. The region is now always mounted with only its text
  conditional, which also makes the announcement reliable: a live region
  inserted together with its content is announced inconsistently.
- **Column headers and sort buttons carry ids derived from the table id**
  (`<table-id>-col-<n>`, `<table-id>-sort-<n>`), keeping `aria-sort` attached to
  the same element across a reload.
- **A streamed table no longer loses every row after a load.** Setting
  `loading` on a table backed by `@streams.*` emptied it: a stream's inserts are
  consumed on their first render and never re-sent, so the rows exist only in
  the client's DOM, and the data `<tbody>` was being replaced by the skeleton
  one. The data body now stays mounted and `hidden` while loading. Visible
  change: the previous rows are in the DOM during a load rather than removed,
  though `hidden` keeps them out of the render and the accessibility tree.
- **Focus rings no longer paint a white halo in dark themes.** `ring-offset-2`
  is used across 19 components, but no theme defined
  `--tw-ring-offset-color`, so every offset drew Tailwind's `#fff` default —
  correct against a light surface, a bright halo against a dark one. Themes now
  default it to `--color-background`, so the prevailing
  `focus-visible:ring-2 ring-ring ring-offset-2` idiom is theme-correct
  wherever it is copied, including into your own markup. Light themes are
  unchanged; no per-call-site class is needed, and any explicit
  `ring-offset-*` still wins.

### Changed - `badge` Is Now a Two-Action Token

- **`on_remove` + `remove_label` render a labeled dismiss control**, so a
  removable token no longer means hand-rolling a button, an icon, and an
  `aria-label` at every call site. `badge/1` raises when `on_remove` arrives
  without `remove_label` — the control is icon-only, so the label is its only
  accessible name. `select`'s multi-select tokens now use it, dropping their own
  copy.
- **`as` (`:span` | `:div`) lets the badge host flow content.** A popover panel
  is a `<div>`, which is not legal inside the default `<span>`, so a token whose
  label opens a filter editor had no valid markup. With `as={:div}` the trigger
  and panel land as siblings inside the badge and the popover wires up normally.
- **The focus ring moved from the badge to its controls.** It was
  `focus-within` on the wrapper, which rings the whole token no matter which
  control has focus — ambiguous as soon as a token carries two. Each direct
  `<button>`/`<a>` now rings itself on `focus-visible`. Visible change: a
  dismissible badge rings the dismiss control rather than the whole badge, and
  `select`'s tokens no longer draw two nested rings.
- **The ≥24px target floor (WCAG 2.5.8) reaches the label region**, not just the
  addon slots, so an interactive label meets it too. Both are scoped to direct
  children, leaving the contents of a hosted popover panel alone.

### Added - Command: A Searchable, Keyboard-Navigable Option List

- **New `command` component**: a query field over a filtered, optionally grouped
  option list, with combobox semantics (`role="combobox"` + `role="listbox"` and a
  roving `aria-activedescendant`), ↑/↓ navigation, Enter to choose, and
  Escape to dismiss. Home and End stay with the caret, as they should in an
  editable combobox. It holds no value of its own — choosing a row runs your
  `on_select` callback and clears the query — so it fits action lists and command
  palettes as naturally as pickers. Use it inline, or inside a popover or modal
  that provides the surface.
- **`options` takes the same shapes as `select`**: scalars, `{label, value}`
  tuples, keyword options with `:key` and `:value` (plus optional `:icon`,
  `:shortcut`, `:description`, and `:disabled`), and `{group_label, options}`
  pairs, which render as labelled `role="group"` sections.
- **Filtering is a function you supply**: `filter` is `(query, options)` and
  defaults to a built-in case-insensitive subsequence matcher ranked by how
  tightly the match is packed. Pass `async` to run an I/O-bound source
  off-process, which cancels the in-flight request on the next keystroke — and
  on selection — and shows a spinner while it runs; with `async`, results refresh
  when a query is submitted rather than on every parent re-render, and selecting
  a row never runs your filter on the LiveView process.
- **`:item` and `:empty` slots** replace the default row and empty-state markup.
- Ships with a generator (`mix pulsar.gen.command`), a Storybook story, and a
  WCAG 2.2 AA audit at `docs/a11y/command.md`.

### Fixed - `popover` Triggers Survive a LiveView Patch

- **A `popover` whose trigger was re-rendered went dead, permanently.** The hook
  wires `popovertarget`, `aria-controls`, and `aria-expanded` onto the trigger,
  which sits outside the hook's own element and carries none of them in the
  server's markup. Any patch that re-rendered the trigger reverted it, and the
  hook's `updated()` repair could not run — LiveView calls it only when the
  hook's element, the panel, is itself patched. Native invoking is the only thing
  that opens the panel in click mode, so one patch was enough to kill the
  control for the life of the page. The hook now marks those attributes ignored
  (`JS.ignore_attributes`), so patches leave the client-owned values in place.
  `trigger_mode="hover"` got the same treatment for `aria-describedby`, which
  was silently dropping the tooltip's description off its trigger. This reaches
  everything built on the primitive — `dropdown_menu`, `tooltip`, `date_picker`,
  and `menu`'s horizontal groups.
- **Every trigger Pulsar renders itself now carries its own invoker.**
  `menu`'s horizontal group trigger, `dropdown_menu`'s submenu trigger, and
  `date_picker`'s calendar button emit `popovertarget`, `aria-controls`, and
  `aria-expanded` from the server rather than waiting for the hook to stamp
  them. These controls no longer depend on client wiring at all — they work
  before the hook mounts, and they survive a patch that replaces the trigger
  element outright, which the ignore marker above cannot. A caller-supplied
  `:trigger` is still wired by the hook; only Pulsar-authored markup can carry
  the attribute directly.

### Fixed - `button` Accepts the Native Invoker Attributes

- **`<.button popovertarget="filters" popovertargetaction="hide">` warned at every
  call site**: `popovertarget`, `popovertargetaction`, `command`, and `commandfor`
  are not LiveView globals, and `button/1` did not opt them into its `:global`.
  The attributes always reached the rendered `<button>` — the cost was an
  `undefined attribute` warning per call site, which fails any application
  compiling with `--warnings-as-errors`. Both `button/1` and the
  `core_components` drop-in now accept all four, so a button can dismiss the
  popover that contains it, or open a dialog, with no JavaScript.

### Fixed - Generated Templates Name Your Application's Namespace

- **Four component templates emitted Pulsar's own module names into generated
  code**: `form`, `input_otp`, `calendar`, and `date_picker` referred to
  `Pulsar.Components.*` in code copied into your application. Most were
  documentation examples, but `form` also raised a runtime `ArgumentError` naming
  `Pulsar.Components.Form.form/1` — a module your application does not have. All
  four now interpolate your own components namespace, and a guard test keeps them
  that way.

### Added - Accessible Sortable Table Headers

- **Table columns can opt into a complete sortable-header affordance with
  `sortable`, `sort_direction`, and `on_sort`**: Pulsar renders a native button
  and default Heroicon inside the column header and applies the valid WAI-ARIA
  sort state to the owning `<th>`. Columns with no current direction report
  `none`, so only the active column needs a `sort_direction`. Callers continue
  to own sort transitions, URLs, events, and query integration. Existing
  non-sortable columns are unchanged.

### Changed (Breaking) - Explicit Select IDs and Scoped Internal Actions

- **Unbound `select` calls now require an explicit `id` as well as a `name`**: deriving the DOM id from `name` could not distinguish same-named controls and produced duplicate select and hook-wrapper ids. Bound fields still prefer a caller `id`, then the field id, then a generated fallback. Add a stable, unique `id` to each direct unbound Select call.
- **`select`'s `on_remove_badge` now takes a 1-arity function**: the callback receives the clicked option value and returns a `%JS{}` command, so server pushes can include the option without relying on a `phx-value-option` DOM fallback. Migrate `on_remove_badge={JS.push("remove_tag")}` to `on_remove_badge={fn option -> JS.push("remove_tag", value: %{option: option}) end}`.
- **Select badge removal is isolated by DOM ancestry instead of a global id selector**: the internal removal event bubbles from the clicked badge button to its containing Select hook, so same-named Selects with distinct ids cannot update one another. The generated Storybook Select variations now carry stable explicit ids, and a generalized story-template guard rejects duplicate derived form-control identities.
- **Flash dismiss, Modal close, and Sidebar backdrop actions use the same bubbling rule**: each nested internal action is handled by its own component hook rather than dispatching through a potentially shared id selector. Public Modal and Sidebar helpers invoked from outside the component subtree remain explicitly id-targeted.
- **Sidebar separates layout and visual customization across its new root/panel DOM**: `class` and global attributes remain on the direct `<nav>` flex/hook root; use the new `panel_class` attr for background, border, overflow, flex-direction, and other visible-panel overrides that previously went through `class`.

### Fixed - Checkbox and Switch Honor an Explicit `checked`

- **`checkbox` and `switch` now let an explicit `checked` override the bound field in both directions**: both attrs declared `default: false`, so the component could not tell "not provided" from "provided as `false`" and simply ignored the attr whenever a field was bound — `checked={false}` on a checked field still rendered checked. The attr no longer carries a default, and the field value is used only when the caller omits it. Callers that never passed `checked` are unaffected.

### Fixed - Form Controls Accept the Native HTML Attributes They Forward

LiveView 1.2 dropped form attributes from the default global set. A component that neither declares such an attribute nor opts it into its `:global` still renders it — it arrives through `@rest` regardless — so the gap never surfaced at render time. It surfaced as an `undefined attribute` warning at every call site, failing the build for host apps compiling with `--warnings-as-errors`.

- **`field` now declares `minlength`, `maxlength`, `list`, `accept`, `capture`, and `form`**: `field` curates its input surface with explicit attrs and already covered the numeric bounds (`min`, `max`, `step`) and `pattern`/`autocomplete`, but the string-length bounds and the remaining form attributes were absent. `<.field type="password" minlength="12" maxlength="72" />` and `<.field type="file" accept="image/*" capture="user" />` now compile clean. `size` is deliberately not included: `field`'s `size` is the component scale (`"sm"`/`"md"`/`"lg"`) and shadows the HTML attribute of the same name.
- **`textarea`, `select`, and `input_otp` accept `autocomplete` and `form`; `switch` accepts `form`**: each was declaring a bare `:global` with no `include:`, so the same set was unreachable when calling these components directly. `input_otp` gains the one that matters most for it — `autocomplete="one-time-code"`, which is what drives SMS code autofill on iOS and Android.
- **`checkbox` accepts `form`**: declared as an explicit attr rather than a `:global` include, because the card variant puts `@rest` on the wrapping `<label>`, where a `form` attribute is inert. Both variants now place it on the `<input>`, including the hidden unchecked-value input.
- **`field` forwards `form` and `autocomplete` to every control it dispatches to**: declaring an attribute removes it from `@rest`, so `select`, `textarea`, `checkbox`, `switch`, and `otp` fields needed these passed explicitly. Previously `<.field type="select" autocomplete="off" />` dropped the attribute silently.

`date_picker` and `radio_group` still do not accept these: both put `@rest` on a wrapper element rather than on the control, so opting the attributes in would place them where they have no effect. Forwarding them onto the inner elements is tracked separately.

### Fixed - `field type="daterange"` Reports Its Own Contract

- **A `daterange` field without an `end_field` now raises naming `<.field type="daterange">`**: previously the missing binding surfaced from the wrapped date picker as `<.date_picker mode="range"> was given start_field but not end_field`, pointing at an internal component the caller never wrote.

### Fixed - Field-Bound Selects Submit Their Value

- **`select` now derives `name` and `value` from a bound form field again**: both attrs declare `default: nil`, which made the `assign_new/3` fallbacks no-ops, so a direct `<.select field={@form[:x]} />` rendered no `name` attribute at all and submitted nothing, and reported `data-has-value="false"` regardless of the field's value. Both are now resolved with an explicit caller-wins check. Selects rendered through `field/1` were unaffected, since `Field` passes `name` and `value` explicitly.

### Fixed - Table Row Keyboard Activation

- **`row_click` tables now resolve and mount their row hook, assign deterministic fallback IDs to non-stream rows, and activate rows with Enter or Space**: rows without an explicit or stream-supplied id receive a stable zero-based id, while custom and LiveView stream ids remain unchanged.

### Changed - Flash Groups Require String Keys

- **`flash_group` now accepts only Phoenix-native string flash keys**: non-string keys are ignored with a warning before rendering, so a manually assembled map cannot create duplicate child ids by mixing atom and string forms of the same key. Migrate manually assembled maps from `%{info: "..."}` to `%{"info" => "..."}`. `put_flash/3` already converts atom kinds to strings.
- **Flash dismissal now uses LiveView's native `"lv:clear-flash"` event**: the default close button clears the string-keyed flash without requiring a host `handle_event/3`. Custom keys that are unsafe in CSS selectors are encoded into unique child ids while the original key remains in dismiss payloads.

### Fixed - Dark Shell Dividers Use a Softer Strong Border

- **`--color-border-strong` now uses `gray-500` instead of `gray-400` in dark themes**: neutral sidebar and navbar shell seams remain visibly defined and retain at least 3:1 contrast, while no longer painting as near-white rules against the page. Light themes and colored borders are unchanged.

### Changed (Breaking) - Simplified Surface Token Hierarchy

- **`--color-surface-0` has been removed from generated themes**: `--color-background` is the application/page ground and default control fill, and `--color-surface-1`, `--color-surface-2`, and `--color-surface-3` are the elevation scale. **Migration:** replace `bg-surface-0` with `bg-background` and remove custom `--color-surface-0` overrides.

### Fixed - `form` Ships a Default Vertical Rhythm

- **`form` now stacks its children with `space-y-6`**: it applied no classes at all, so it was the only layout-bearing component in the library with no opinion about its own internal rhythm — `card`'s body is `flex flex-col p-5 gap-5`, `field` is `flex flex-col gap-2`, `header` is `flex flex-col gap-4`. A `field` followed by a `button` were siblings with no spacing between them: the field wrapper's bottom edge and the button's top edge sat at the same y-coordinate, and the button's `shadow-card` bled over the input's border, reading as an overlap. The class is merged through Twm, so a caller's own spacing wins: `class="space-y-4"` replaces the default outright. To lay a form out some other way, pass `space-y-0` alongside your own classes — `space-y` and `gap` are different Twm groups, so `class="grid grid-cols-2 gap-4"` on its own leaves both the margins and the gaps in play.

  `space-y-6` rather than `flex flex-col gap-6` deliberately: a flex column stretches its children on the cross axis, which would have made every submit button in every consuming app full-width. That is the right look for an auth card and the wrong one for a settings form, so it should not arrive as a side effect of a spacing fix. Margin-based spacing leaves intrinsic widths alone.
- **`form`'s `required_legend` paragraph no longer carries `mb-4`**: Tailwind v4 compiles `space-y-*` to a `margin-block-end` on `:where(& > :not(:last-child))` — zero specificity — so the legend's own margin beat the form's rhythm and pinned that one gap at 16px while every other gap sat at 24px. The legend is now spaced by the form like any other child.
- **`simple_form` no longer wraps its children in `<div class="space-y-8">`**: Pulsar had already stripped Phoenix's `mt-10 bg-white` from that element, leaving it as pure spacing indirection duplicating what the form itself now provides. Between-field spacing goes from 32px to 24px, and the gap above the `:actions` row from 32px to 24px, so a `simple_form` and a plain `form` on the same screen now agree. The actions row's `mt-2` went with it: adjacent sibling margins collapse to the larger of the two, so its 8px never had any effect — inside the old `space-y-8` wrapper either.

These are rendering changes to the shipped `Pulsar.Components.Form` and `Pulsar.CoreComponents` modules, so apps that consume Pulsar as a dependency pick them up on `mix deps.update pulsar`. Apps that generated their own copies keep them until they regenerate. Any form where you had added your own spacing to work around the missing default should have that workaround removed, or it will now compose with the default.

### Changed - Storybook Form Examples Use the Pulsar Form

- **The generated `login` and `settings_panel` storybook examples now render `Form.form` instead of Phoenix's `<.form>`**: both are form-shaped examples, and neither demonstrated the focus-on-error hook that is the component's reason to exist. Both also dropped the spacing classes they carried, since the form now supplies that rhythm itself.

### Fixed - Ghost Variants No Longer Carry Card Elevation

- **`button`'s `ghost` variant no longer renders `shadow-card hover:shadow-dropdown`**: ghost is flat chrome — no fill, no border, no lift — so it can sit in a header or toolbar without competing with the controls around it. `solid` and `outline` are unchanged and keep their elevation; `link` is unaffected. Ghost keeps its `hover:scale-[1.02] active:scale-[0.98]` press affordance — only the resting and hover shadow are gone. Anyone who wants an elevated ghost button can pass `class="shadow-card"`, which Twm composes normally.
- **`checkbox`'s `card` layout no longer lifts on hover in the `ghost` variant**: `hover:shadow-card` is gone, for the same reason — a ghost card is a selectable region, not a raised surface. The `solid` (`hover:shadow-card`) and `outline` (`hover:shadow-dropdown`) card variants are unchanged, and the ghost card keeps its `hover:bg-*/10` tint and checked-state background, so hover and selection remain visible.
- **`switch`'s `ghost` variant thumb no longer renders `shadow-dropdown shadow-black/6`**: it was the last ghost surface in the library still carrying resting elevation, so a ghost switch sat visibly raised next to the ghost buttons in the same toolbar. The thumb keeps `border border-border-strong`, which is what separates it from the track. `solid` (`shadow-modal`) and `outline` (`shadow-dropdown`) thumbs are unchanged.
- **`button`'s `ghost` variant now styles its `pressed` state**: a ghost toggle button rendered `aria-pressed="true"`/`data-pressed="true"` but was pixel-identical to the unpressed one, so the state reached screen readers and nobody else. A pressed ghost button now renders its hover-level tint plus a `ring-1 ring-inset` in its own color (`border-strong` for `neutral`). The tint stays at the hover level deliberately: ghost draws same-hue text on a same-hue tint, so deepening the tint for a state that persists costs text contrast — at `/15` the `secondary` label measured 4.44:1 against its own background, under the 4.5:1 that WCAG 2.2 AA requires for body text. The ring carries the state instead, and it also separates a pressed button from a merely hovered one.
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
- **Form inputs derive their id from `name` before generating one**: `input`, `checkbox`, `switch`, `radio_group`, and `textarea` now resolve caller `id`, then `field.id`, then `name`, then a generated value. An unbound input with a `name` had a stable source going unused. Four of the five only ever reach the generated rung on the bound path, because unbound they require a `name`: `input`, `checkbox`, `switch`, and `textarea` raise without one. `radio_group` is the exception — it has no such check, so an unbound group with neither a `field` nor a `name` still falls through to a generated id (see the accepted-limitations note above). Select is intentionally excluded: direct unbound calls now require an explicit `id`, as described above.

  The `name` is normalized into id shape on the way — `user[notifications]` becomes `user_notifications`, matching what Phoenix's own `field.id` would have produced for that field, and `tags[]` becomes `tags_`. A raw name is not id-shaped: `switch` interpolates its resolved id into a CSS selector for the click-target overlay (`to: "#<id>"`), and `#user[notifications]` parses as `#user` plus an attribute selector, matching nothing and leaving the overlay dead.

  Normalization does not make the id *unique*, and it cannot: siblings that intentionally share a `name` derive the same id, so `<.checkbox :for={t <- tags} name="tags[]" value={t} />` renders `id="tags_"` on every instance. This is the same behavior a shared `field` has always had in Phoenix — `field.id` is a function of the field, not of the instance — and the fix is the same: pass an explicit `id` per instance. Duplicate ids on a `phx-hook` root give morphdom an ambiguous match target, so this matters beyond `<label for>`.
- **`select` declares an `:id` attr, so a caller-supplied `id` reaches the `<select>` element**: it had none, so `id` was an HTML global that landed in `@rest` while `assigns[:id]` stayed `nil` — the element rendered the name-derived id *and* re-spread the caller's from `@rest`, two `id` attributes on one tag. Browsers keep the first, so the caller's id was silently dropped and any `<label for>` pointing at it matched nothing, costing the select its accessible name. `<.field type="select">` passes an id on every render, so this fired for every field-wrapped select, not just direct calls. Direct unbound Selects no longer derive an id from `name`; callers that previously omitted `id` must now supply a stable, unique one.
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
