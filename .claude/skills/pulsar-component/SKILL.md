---
name: pulsar-component
description: >-
  Create a new component in the Pulsar Phoenix LiveView component library
  (the repo at lib/pulsar/components/). Use this whenever the user wants to add,
  build, scaffold, or generate a new Pulsar component — e.g. "add an avatar
  component to Pulsar", "let's build a tooltip", "scaffold a new badge-like
  component", "create a breadcrumb component" — even if they don't say the word
  "Pulsar" but are clearly working in this component library. Pulsar components
  are GENERATED into user apps (no shared runtime code), so a new component is
  never just one file: it requires a source module, a synced EEx template, a
  generator task, install/sync registrations, unit tests, a storybook story
  (+ template), an a11y fixture LiveView, and a WCAG 2.2 AA audit doc. This skill
  enforces that full surface so the build, sync tests, storybook smoke test, and
  axe a11y gate all stay green. Do NOT use for editing an existing component's
  behavior, theme/CSS work, or generator infrastructure changes.
---

# Creating a Pulsar component

Pulsar is a **generator-first** library: every component is copied verbatim into
the user's app by `mix pulsar.install`. There is **no shared runtime module** to
extend — each component is self-contained (only `Twm` for class merging). That
single fact drives everything here:

- A component's source lives in `lib/pulsar/components/<name>.ex` **and** a
  byte-identical EEx template in `priv/templates/<name>.ex.eex`. A test
  (`Pulsar.TemplateSyncTest`) fails the build if they drift.
- "Done" is not one file. A component is wired into ~12–15 files across source,
  generator, install, sync test, unit tests, storybook (3 places), a11y fixtures
  (3 places), and docs. **The test suite is the safety net that catches every
  missed registration** — so the completion gate is "the specific test files
  below pass," not "I wrote the component."
- Don't propose extracting shared helpers across components. Duplication between
  components is intentional (each is generated standalone). A component MAY depend
  on *another whole component* (e.g. button uses link) — that's declared, not
  inlined. See "Component dependencies" below.

## Workflow

Follow these phases in order. They map to the superpowers skills the repo uses;
invoke those skills when noted.

### 1. Brainstorm the API (before any code)

Invoke `superpowers:brainstorming`. Pin down, with the user:

- **Public function name & element** — `def <name>(assigns)` rendering what root
  element (`<span>`, `<button>`, `<div>`, native form control, …).
- **Attrs** — each with `default:`, `values:` (for enums), `doc:`. Decide the
  variant/color/size axes. Mirror existing conventions: `variant`, `color`,
  `size` (`xs sm md lg xl`), `class` (default `""`), `rest :global`. The standard
  axis vocabulary, when to add a new axis, and the full token palette to dress it
  in are in `references/theming-and-variants.md` — read it while choosing axes.
- **Slots** — `inner_block` (required?), addon slots, named slots.
- **WAI-ARIA pattern** — which APG pattern governs it (button, switch, radio
  group, disclosure, tooltip…). This determines roles, states, keyboard map, and
  focus management. If interactive, it needs a keyboard fixture (see testing ref).
- **Component dependencies** — does it compose another Pulsar component (icon,
  link)? That changes the template alias and the install dependency map.
- **Form integration** — is it a form input? If so it routes through `Field`
  (the canonical label/error/aria wrapper) — read `lib/pulsar/components/field.ex`
  before designing aria; don't reinvent describedby/labelledby on the leaf.

Write the decisions down. Read 2–3 of the closest existing components in
`lib/pulsar/components/` to match idiom (badge = simplest display; checkbox/input
= form; button = colocated JS + component dependency).

**Look at daisyUI and shadcn/ui for design inspiration.** Pulsar's component
design draws on both — daisyUI for its semantic variant/size vocabulary and the
breadth of component types, shadcn/ui for its composition patterns, anatomy, and
accessibility defaults. Before settling the API, check how each implements the
equivalent component (search the web or their docs: daisyui.com/components,
ui.shadcn.com/docs/components) and borrow what fits: the set of variants, sizes,
and states worth supporting; sensible slot/part breakdown; and a11y affordances
they bake in. Then translate it into Pulsar's idiom — semantic tokens (not
daisyUI's `btn-*` classes or shadcn's CSS-var-via-`cn()` setup), Twm merging,
Phoenix-native behavior, and the generator-first structure. Inspiration for the
*shape* of the API; never copy their CSS or JS wholesale.

### 2. Write tests first (TDD)

Invoke `superpowers:test-driven-development`. Write the failing unit test file
`test/pulsar/components/<name>_test.exs` covering every variant/color/size, slot,
Twm class-merge override, a11y attributes, and (if a form input) field
integration. See `references/testing.md` for the exact structure and assertion
style. Run it; watch it fail for the right reason (component doesn't exist yet).

### 3. Implement the component + its template

Write `lib/pulsar/components/<name>.ex` to pass the tests, following the anatomy
in `references/anatomy.md` (module-attribute config maps, `import Twm, only:
[merge: 1]`, semantic color tokens — **no `dark:` variants**, private
`*_classes` helpers, `@spec`, `@moduledoc` with examples). For the variant→class
lookup-map structure and which semantic/design tokens to use for each part, follow
`references/theming-and-variants.md` — build only from existing tokens; a token
that doesn't exist is a theme change, not a hard-coded value.

Then create `priv/templates/<name>.ex.eex` — the **module body only** (no
`defmodule … do/end` wrapper), with sibling-component aliases written as
`alias <%= @component_namespace %>.Icon`. The sync test reconstructs the module
from the template; see `references/registries.md` for the exact transform rule.
Run `mix test test/pulsar/template_sync_test.exs` after adding the `@pairs` entry
(step 4) — it must pass.

### 4. Wire every registry

This is where components silently break. Work through the **complete manifest in
`references/registries.md`** — it lists every file to create or edit (generator
task, install `@components` map + `composes:` list, sync-test `@pairs`, storybook
template + generator list + dev_app story + smoke-test counts, fixture LiveView +
router + `@fixtures`, a11y docs). Don't skip any; each has a test that enforces it.

### 5. Accessibility audit + fixtures

Pulsar's published target is **WCAG 2.2 AA**. Create:

- The a11y **fixture LiveView** + route + `@fixtures` entry so the axe gate covers
  it (every fixture cell needs `data-fixture-cell="..."`).
- `docs/a11y/<name>.md` — a full per-criterion WCAG 2.2 A/AA audit (PASS / GAP /
  N-A with `file:line` evidence), plus the row updates in `docs/a11y/README.md`.

See `references/accessibility.md` for the audit doc format, the keyboard-fixture
requirement for interactive components, and the rules below.

**A11y rules (from project conventions):**
- Never reference Linear tickets (PUL-XX, linear.app) in `lib/`, `priv/`, or
  `docs/` — tag gaps by severity (`blocker`/`serious`/`minor`) instead.
- If a measured result disagrees with the AA claim, **remeasure** — the claim is
  the target; don't soften it to match a stale number.
- When an audit surfaces many gaps, those hand off to tickets (the
  `ticket-breakdown` skill), not one giant inline plan.

### 6. Verify (evidence before "done")

Invoke `superpowers:verification-before-completion`. Run and show output for:

```sh
mix format
mix compile --warnings-as-errors
mix test test/pulsar/components/<name>_test.exs
mix test test/pulsar/template_sync_test.exs        # source⇄template sync gate
mix test test/pulsar/dev_app/storybook_test.exs    # storybook leaf-count gate
mix credo --strict
mix test --only integration                         # axe a11y gate (browser)
```

The integration/a11y browser gate is brittle (Playwright cold-start, pool
starvation, mount budget). If it flakes, read the project note on its three levers
before touching `config/test.exs` or the fixtures — don't "fix" it by loosening
the gate. A new heavy fixture (many variant cells) may need a variant-split route
like Input/Select/Table.

## Reference files

Read these as you reach the relevant phase:

- `references/registries.md` — **the complete file-by-file manifest** of what to
  create/edit, the template sync transform, and the storybook/a11y registries.
  This is the load-bearing checklist; consult it in step 4.
- `references/anatomy.md` — component module structure, Twm merge pattern,
  semantic tokens, attrs/slots, colocated JS, component dependencies.
- `references/theming-and-variants.md` — the semantic theme model, the full
  available token inventory (colors, radius, shadow, motion, z-index, spacing),
  the standard variant/color/size axes, the variant→class lookup-map pattern, and
  what to do when a needed token doesn't exist. Read in design (step 1) and
  implementation (step 3).
- `references/testing.md` — unit test structure, storybook story format, fixture
  LiveView pattern, the sync relationships between template/dev_app story.
- `references/accessibility.md` — WCAG 2.2 audit doc format, keyboard fixtures for
  interactive components, the axe gate.
