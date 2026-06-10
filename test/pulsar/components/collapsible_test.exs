defmodule Pulsar.Components.CollapsibleTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Collapsible

  defp basic(assigns \\ %{}) do
    assigns = Map.merge(%{id: "col", extra: []}, assigns)

    rendered_to_string(~H"""
    <Collapsible.collapsible id={@id} {@extra}>
      <:trigger>Show details</:trigger>
      <p>Hidden details</p>
    </Collapsible.collapsible>
    """)
  end

  describe "collapsible/1 structure & ARIA" do
    test "renders the trigger and panel content" do
      html = basic()
      assert html =~ "Show details"
      assert html =~ "Hidden details"
    end

    test "trigger is a button wired to the panel, closed by default" do
      html = basic()
      assert html =~ ~r/<button[^>]*data-collapsible-trigger/s
      assert html =~ ~s(aria-controls="col-panel")
      assert html =~ ~r/data-collapsible-trigger[^>]*aria-expanded="false"/s
      assert html =~ ~s(id="col-panel")
      refute html =~ "data-expanded"
    end

    test "open renders expanded state" do
      html = basic(%{extra: [open: true]})
      assert html =~ "data-expanded"
      assert html =~ ~r/data-collapsible-trigger[^>]*aria-expanded="true"/s
    end

    test "auto-generates an id when omitted" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Collapsible.collapsible>
          <:trigger>T</:trigger>
          Body
        </Collapsible.collapsible>
        """)

      assert html =~ ~r/aria-controls="collapsible-\d+-panel"/
    end

    test "attaches the colocated hook via a static literal" do
      assert basic() =~ "PulsarCollapsible"
    end
  end

  describe "collapsible/1 styling" do
    test "applies the open-trigger tint for the chosen color" do
      assert basic(%{extra: [color: "primary"]}) =~ "group-data-[expanded]/collapsible:text-primary"
    end

    test "renders the chevron + grid-rows disclosure animation" do
      html = basic()
      assert html =~ "hero-chevron-down"
      assert html =~ "group-data-[expanded]/collapsible:rotate-180"
      assert html =~ "grid-rows-[0fr]"
      assert html =~ "group-data-[expanded]/collapsible:grid-rows-[1fr]"
      assert html =~ "transition-[grid-template-rows]"
    end

    test "custom class merges onto the container" do
      assert basic(%{extra: [class: "mt-8"]}) =~ "mt-8"
    end
  end
end
