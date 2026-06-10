defmodule Pulsar.Components.AccordionTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Accordion

  defp basic(assigns \\ %{}) do
    assigns = Map.merge(%{id: "acc", extra: []}, assigns)

    rendered_to_string(~H"""
    <Accordion.accordion id={@id} {@extra}>
      <:item id="one" title="First">First panel</:item>
      <:item id="two" title="Second">Second panel</:item>
    </Accordion.accordion>
    """)
  end

  describe "accordion/1 structure & ARIA" do
    test "renders each item's title and panel content" do
      html = basic()
      assert html =~ "First"
      assert html =~ "First panel"
      assert html =~ "Second panel"
    end

    test "wires aria-controls/aria-labelledby between header and region" do
      html = basic()
      assert html =~ ~s(id="one-header")
      assert html =~ ~s(aria-controls="one-panel")
      assert html =~ ~s(role="region")
      assert html =~ ~s(id="one-panel")
      assert html =~ ~s(aria-labelledby="one-header")
    end

    test "headers are buttons with aria-expanded, default closed" do
      html = basic()
      assert html =~ ~r/<button[^>]*data-accordion-header[^>]*aria-expanded="false"/s
    end

    test "uses the configured heading level" do
      assert basic(%{extra: [heading_level: "h2"]}) =~ "<h2"
      assert basic() =~ "<h3"
    end

    test "auto-generates item ids when omitted" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion id="auto">
          <:item title="Only">Body</:item>
        </Accordion.accordion>
        """)

      assert html =~ ~s(id="auto-item-0-header")
      assert html =~ ~s(aria-controls="auto-item-0-panel")
    end

    test "exposes type + collapsible config to the hook" do
      assert basic() =~ ~s(data-type="single")
      assert basic() =~ ~s(data-collapsible="true")
      assert basic(%{extra: [type: "multiple"]}) =~ ~s(data-type="multiple")
      assert basic(%{extra: [collapsible: false]}) =~ ~s(data-collapsible="false")
    end

    test "attaches the colocated hook via a static literal" do
      assert basic() =~ "PulsarAccordion"
    end
  end

  describe "accordion/1 initial open state" do
    test "no section is open by default" do
      refute basic() =~ "data-expanded"
      assert basic() =~ ~r/aria-expanded="false".*aria-expanded="false"/s
    end

    test "value opens the named section (single)" do
      html = basic(%{extra: [value: "two"]})
      assert html =~ ~r/id="two-header"[^>]*aria-expanded="true"/s
      assert html =~ ~r/id="one-header"[^>]*aria-expanded="false"/s
    end

    test "single honors only the first id when given a list" do
      html = basic(%{extra: [type: "single", value: ["one", "two"]]})
      assert html =~ ~r/id="one-header"[^>]*aria-expanded="true"/s
      assert html =~ ~r/id="two-header"[^>]*aria-expanded="false"/s
    end

    test "multiple opens every named section" do
      html = basic(%{extra: [type: "multiple", value: ["one", "two"]]})
      assert html =~ ~r/id="one-header"[^>]*aria-expanded="true"/s
      assert html =~ ~r/id="two-header"[^>]*aria-expanded="true"/s
    end
  end

  describe "accordion/1 items" do
    test "renders a leading icon when given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion id="ic">
          <:item id="a" title="With icon" icon="hero-user">Body</:item>
        </Accordion.accordion>
        """)

      assert html =~ "hero-user"
    end

    test "disabled item is a disabled button with aria-disabled and never open" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion id="d" value="a">
          <:item id="a" title="Off" disabled>Body</:item>
        </Accordion.accordion>
        """)

      assert html =~ ~r/data-accordion-header[^>]*aria-disabled="true"/s
      assert html =~ ~r/data-accordion-header[^>]*disabled/s
      assert html =~ ~r/id="a-header"[^>]*aria-expanded="false"/s
    end
  end

  describe "accordion/1 styling" do
    test "applies the open-header color tint for the chosen color" do
      assert basic(%{extra: [color: "primary"]}) =~ "group-data-[expanded]/item:text-primary"
    end

    test "custom class merges onto the container" do
      assert basic(%{extra: [class: "mt-8"]}) =~ "mt-8"
    end

    test "renders the chevron indicator" do
      assert basic() =~ "hero-chevron-down"
      assert basic() =~ "group-data-[expanded]/item:rotate-180"
    end

    test "uses the disclosure grid-rows animation wrapper" do
      html = basic()
      assert html =~ "grid-rows-[0fr]"
      assert html =~ "group-data-[expanded]/item:grid-rows-[1fr]"
      assert html =~ "transition-[grid-template-rows]"
    end

    test "item wrapper carries the group/item root the disclosure variants key off" do
      # Every `group-data-[expanded]/item:*` utility (panel expand, chevron
      # rotate, header tint, panel visibility) is inert without a `group/item`
      # root on the same element that carries `data-accordion-item`/`data-expanded`.
      assert basic() =~ ~r/data-accordion-item[^>]*class="[^"]*group\/item/s
    end
  end
end
