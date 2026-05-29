# Tests, storybook, and fixtures

Three test surfaces back a component. Copy the closest existing example for each.

## 1. Unit tests — `test/pulsar/components/widget_test.exs`

Written **first** (TDD). Structure:

```elixir
defmodule Pulsar.Components.WidgetTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Widget

  describe "widget/1 basic functionality" do
    test "renders with default props" do
      assigns = %{}
      html = rendered_to_string(~H"<Widget.widget>Hi</Widget.widget>")
      assert html =~ "<span"
      assert html =~ "Hi"
    end
  end

  describe "variants and colors" do
    test "applies solid primary classes" do
      assigns = %{}
      html = rendered_to_string(~H[<Widget.widget variant="solid" color="primary">X</Widget.widget>])
      assert html =~ ~s(bg-primary)
      assert html =~ ~s(text-primary-foreground)
    end
  end

  describe "sizes" do
    # one test per size axis, asserting the size class
  end

  describe "customization (Twm merge)" do
    test "user class overrides defaults" do
      assigns = %{}
      html = rendered_to_string(~H[<Widget.widget class="rounded-none">X</Widget.widget>])
      assert html =~ "rounded-none"
    end
  end

  describe "accessibility" do
    test "passes through global/aria attributes" do
      assigns = %{}
      html = rendered_to_string(~H[<Widget.widget aria-label="Status">X</Widget.widget>])
      assert html =~ ~s(aria-label="Status")
    end
    # assert roles/states required by the component's APG pattern
  end
end
```

Coverage checklist: every variant, every color, every size, each slot,
Twm override, global/aria pass-through, and — for form inputs — `Field`
integration with a real `Phoenix.HTML.FormField` (see `checkbox_test.exs` /
`input_test.exs`). Assertion style is substring: `assert html =~ ~s(class-name)`.

## 2. Storybook (two synced files + a generator-list edit + a count-test edit)

### Story template — `priv/templates/storybook/components/widget.story.exs.eex`

```elixir
defmodule <%= @web_module %>.Storybook.Components.Widget do
  use PhoenixStorybook.Story, :component

  alias <%= @components_module %>.Widget

  def function, do: &Widget.widget/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{id: :variant, type: :string, values: ~w(solid outline ghost),
        default: "solid", doc: "Visual style variant"},
      %Attr{id: :color, type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "neutral", doc: "Color scheme"},
      %Attr{id: :size, type: :string, values: ~w(xs sm md lg xl),
        default: "md", doc: "Size"},
      %Attr{id: :class, type: :string, default: "", doc: "Additional CSS classes"}
    ]
  end

  def slots do
    [%Slot{id: :inner_block, required: true, doc: "Content"}]
  end

  def variations do
    [
      %Variation{id: :default, description: "Default", attributes: %{}, slots: ["New"]},
      %Variation{id: :primary_solid, description: "Primary solid",
        attributes: %{variant: "solid", color: "primary"}, slots: ["Primary"]}
      # ... a handful covering the key variant/color/size combinations
    ]
  end
end
```

The `%Attr{}` set should mirror the component's `attr` declarations (same
values/defaults/docs). Variations should showcase the meaningful combinations.

### dev_app story — `test/support/dev_app/storybook/components/widget.story.exs`

This file is the template **rendered** with the dev_app namespaces. It must equal
the template after substituting:
- `<%= @web_module %>` → `Pulsar.DevApp`
- `<%= @components_module %>` → `Pulsar.Components`

Verify with:
```sh
diff <(sed 's/<%= @web_module %>/Pulsar.DevApp/; s/<%= @components_module %>/Pulsar.Components/' \
  priv/templates/storybook/components/widget.story.exs.eex) \
  test/support/dev_app/storybook/components/widget.story.exs
```
Empty diff = in sync. Keep them in lockstep on every edit.

### Generator list + count test

- Add `:widget` to `@components` in `lib/pulsar/generator/storybook.ex`.
- Update `test/pulsar/dev_app/storybook_test.exs`: add `/components/widget` to
  `@expected_component_paths`, bump the leaf-count assertion, and fix the
  human-readable counts ("19 components"/"28 leaves"). See `registries.md` §C.

## 3. A11y fixture LiveView — `test/support/dev_app/live/widget_live.ex`

Renders every visual permutation so the axe gate can scan it. Each rendered
instance carries a unique `data-fixture-cell`.

```elixir
defmodule Pulsar.DevApp.WidgetLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Widget

  @variants ~w(solid outline ghost)
  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="widget" title="Widget">
      <.fixture_section :for={variant <- @variants} name={"variant-#{variant}"} title={"variant: #{variant}"}>
        <%= for color <- @colors, size <- @sizes do %>
          <Widget.widget variant={variant} color={color} size={size}
            data-fixture-cell={"#{variant}-#{color}-#{size}"}>
            {color}/{size}
          </Widget.widget>
        <% end %>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
```

`fixture_page`/`fixture_section` come from `Pulsar.DevApp.Components` (already
imported via `use Pulsar.DevApp.Web, :live_view`). For form inputs, set up a form
in `mount/3` and render the field; see `input_live.ex`. Then add the route and the
`@fixtures` entry (see `registries.md` §D).

**Heavy fixtures:** a full variant×color×size grid can blow the browser-test mount
budget. If the component has many cells, split into per-variant `live_action`
routes (like Input/Select/Table) — one route + one `@fixtures` tuple per variant.
