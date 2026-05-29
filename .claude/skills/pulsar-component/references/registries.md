# Complete file manifest for a new component

Adding a component named `widget` (module `Widget`, function `widget/1`) touches
the files below. Each row that says "enforced by" has a test that fails if you
skip it — that's your safety net. Verify exact current line numbers/contents by
reading the file before editing; don't trust line numbers cited here (they drift).

> Replace `widget` / `Widget` with your component's snake_case / CamelCase name.

## A. Template + generated lib + generator + sync

| # | File | Action | Enforced by |
|---|------|--------|-------------|
| 1 | `priv/templates/widget.ex.eex` | **Create** template (module body only) — the source of truth | `mix pulsar.sync --check` |
| 2 | `lib/pulsar/components/widget.ex` | **Generated** by `mix pulsar.sync` (do not hand-write) | unit tests, compile |
| 3 | `lib/pulsar/template_sync.ex` | **Edit**: add tuple to `Pulsar.TemplateSync.pairs/0` | `mix pulsar.sync --check` |
| 4 | `lib/mix/tasks/pulsar.gen.widget.ex` | **Create** generator task | generator test (if present) |
| 5 | `lib/mix/tasks/pulsar.install.ex` | **Edit**: add to `@components` + `composes:` | install tests |

### 1 → 2 — the `mix pulsar.sync` transform (critical)

The template is the **single source of truth**. `mix pulsar.sync` renders it into
the committed lib module; `mix pulsar.sync --check` (in the `check`/`check.ci`
aliases and CI) fails the build if the committed lib file has drifted. Never
hand-edit `lib/pulsar/components/widget.ex` — edit the template and re-run sync.
The rule:

- **Template** (`priv/templates/widget.ex.eex`): the **module body only** (no
  `defmodule`/`end` wrapper), with any sibling-component alias written as an EEx
  interpolation so it resolves to the user's namespace at generation time:

  ```elixir
  # in the template (priv/templates/widget.ex.eex):
  alias <%= @component_namespace %>.Icon
  ```

- **Generated lib file** (`lib/pulsar/components/widget.ex`): the full module —
  `defmodule Pulsar.Components.Widget do … end` — with that line as the concrete
  `alias Pulsar.Components.Icon`.

`mix pulsar.sync` wraps the rendered template as `defmodule Pulsar.Components.Widget
do\n<indented body>\nend\n` and formats it. So the generated lib file is the
template's Elixir, differing only in the module wrapper and the
`<%= @component_namespace %>` substitution — produced for you, not maintained by hand.

`Pulsar.TemplateSync.pairs/0` entry to add (#3):
```elixir
{:widget, "lib/pulsar/components/widget.ex", "Pulsar.Components", "Pulsar.Components.Widget"},
```

### 3 — generator task

Minimal; the `Pulsar.Generator` macro does the work. **Do not add `@shortdoc`**
(short_doc defaults to `false` on purpose — per-component generators are hidden
from `mix help`; only `pulsar.install` is the public entry point):

```elixir
defmodule Mix.Tasks.Pulsar.Gen.Widget do
  use Pulsar.Generator,
    component: :widget,
    example: "mix pulsar.gen.widget",
    long_doc: """
    Generates a <one-line purpose>.

    <Longer description — features, examples, options. Mirror an existing
    generator like lib/mix/tasks/pulsar.gen.badge.ex.>

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end
```

### 4 — install task (`lib/mix/tasks/pulsar.install.ex`)

Two edits in the `Mix.Tasks.Pulsar.Install` module:

- Add to the `@components` map. The value is the **list of other components this
  one depends on** (empty list if none):
  ```elixir
  widget: [],            # or  widget: [:icon, :link]  if it composes them
  ```
- Add the generator to the `composes:` list in `info/2`:
  ```elixir
  "pulsar.gen.widget",
  ```

`validate_component_dependencies!/0` will raise at runtime if you list a dependency
that isn't itself a key in `@components`, so deps must be real components.

## B. Unit tests

| # | File | Action |
|---|------|--------|
| 6 | `test/pulsar/components/widget_test.exs` | **Create** (written first, in TDD step) |

See `testing.md` for structure.

## C. Storybook (3 files + 1 registry + 1 count test)

| # | File | Action | Enforced by |
|---|------|--------|-------------|
| 7 | `priv/templates/storybook/components/widget.story.exs.eex` | **Create** story template | gen.storybook tests |
| 8 | `lib/pulsar/generator/storybook.ex` | **Edit**: add `:widget` to `@components` | drives generation |
| 9 | `test/support/dev_app/storybook/components/widget.story.exs` | **Create** dev_app story | `Pulsar.DevApp.StorybookTest` |
| 10 | `test/pulsar/dev_app/storybook_test.exs` | **Edit**: path + counts | runs the smoke assertions |

### 7 ⇄ 9 — the story sync

The dev_app story (#9) is the story template (#7) **rendered**, with:
- `<%= @web_module %>` → `Pulsar.DevApp`
- `<%= @components_module %>` → `Pulsar.Components`

i.e. `diff <(substitute template) dev_app_story` is empty. Keep them in lockstep
exactly like the component template/lib pair. Story `.story.exs` files are plain
scripts (no module wrapper concern — they already declare `defmodule
<%= @web_module %>.Storybook.Components.Widget`). See `testing.md` for the format.

### 8 — storybook generator list (`lib/pulsar/generator/storybook.ex`)

Add `:widget` to the `@components` list (keep alphabetical). Components not in this
list get no story emitted.

### 10 — storybook smoke test (`test/pulsar/dev_app/storybook_test.exs`)

This test hard-codes counts. When you add a component you must:
- Add `/components/widget` to `@expected_component_paths`.
- Bump the total leaf count assertion (`length(Storybook.leaves()) == N` → `N+1`).
- Update the human-readable count strings ("all 19 component stories", the
  moduledoc "19 components" / "28 leaves") to match.

## D. A11y fixtures (axe gate)

| # | File | Action | Enforced by |
|---|------|--------|-------------|
| 11 | `test/support/dev_app/live/widget_live.ex` | **Create** fixture LiveView | axe integration test |
| 12 | `test/support/dev_app/router.ex` | **Edit**: add route(s) | resolves the fixture |
| 13 | `test/support/dev_app/components.ex` | **Edit**: add to `@fixtures` | drives axe test loop |

- Route (single-variant): `live "/components/widget", WidgetLive, :index`
- `@fixtures` entry: `{"Widget", "/components/widget"}`
- For heavy components (many variant×color×size cells), split into per-variant
  routes/actions like Input/Select/Table to keep the mount budget under the
  browser-test timeout — e.g. `:outline`/`:ghost`/`:solid` actions with separate
  routes and one `@fixtures` tuple each.

The axe test (`test/integration/a11y/axe_clean_test.exs`) auto-discovers fixtures
from `Components.fixtures()` and runs each in light + dark — no per-component test
to write. See `accessibility.md`.

## E. A11y documentation

| # | File | Action |
|---|------|--------|
| 14 | `docs/a11y/widget.md` | **Create** full WCAG 2.2 AA audit |
| 15 | `docs/a11y/README.md` | **Edit**: add the component's rows to the criteria grids |

See `accessibility.md` for the audit doc format.

## F. Interactive components only (keyboard)

If the component is interactive (has a keyboard interaction model per its APG
pattern):

| File | Action |
|------|--------|
| `test/support/dev_app/live/keyboard/widget_live.ex` | **Create** keyboard fixture |
| `test/support/dev_app/router.ex` | **Edit**: add `live "/keyboard/widget", Keyboard.WidgetLive, :index` |
| `test/integration/a11y/keyboard_test.exs` | **Edit**: add a `describe` block exercising the keys |

## G. Nice-to-have / check-if-present

- `test/mix/tasks/pulsar/gen/` — if per-component generator tests exist for
  similar components, mirror one for `widget`.
- `CLAUDE.md` — the directory-structure listing names each component; add a line
  if you're keeping it current.

---

## Quick self-check before claiming done

Grep for an existing simple component name across the repo to confirm you've
covered the same set of files:

```sh
grep -rl "badge" lib/ priv/ test/ docs/ --include="*.ex" --include="*.eex" \
  --include="*.exs" --include="*.md" | sort
```

Your new component should appear in an analogous set of files. Then run the full
verification command list in SKILL.md step 6.
