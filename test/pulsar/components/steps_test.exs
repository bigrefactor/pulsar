defmodule Pulsar.Components.StepsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Steps

  describe "structure & ARIA" do
    test "renders an ordered list labeled by aria_label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={2} aria_label="Checkout">
          <:step label="Cart" />
          <:step label="Pay" />
        </Steps.steps>
        """)

      assert html =~ ~s(<ol)
      assert html =~ ~s(aria-label="Checkout")
      assert html =~ ~s(<li)
      # non-interactive indicator: no nav landmark
      refute html =~ ~s(<nav)
    end

    test "defaults aria_label to Progress" do
      assigns = %{}

      html = rendered_to_string(~H[<Steps.steps current={1}><:step label="A" /></Steps.steps>])

      assert html =~ ~s(aria-label="Progress")
    end

    test "marks the current step with aria-current=step" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={2}>
          <:step label="One" />
          <:step label="Two" />
          <:step label="Three" />
        </Steps.steps>
        """)

      assert html =~ ~s(aria-current="step")
      # exactly one current
      assert length(String.split(html, ~s(aria-current="step"))) == 2
    end
  end

  describe "state derivation by index" do
    test "renders a checkmark for completed steps and a number for upcoming" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={2}>
          <:step label="Done one" />
          <:step label="Current two" />
          <:step label="Upcoming three" />
        </Steps.steps>
        """)

      assert html =~ "hero-check"
      # upcoming shows its number
      assert html =~ ">3</span>"
    end

    test "sr-only status text is present for screen readers" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={2} done_label="Completed" current_label="Current step" upcoming_label="Upcoming">
          <:step label="A" />
          <:step label="B" />
          <:step label="C" />
        </Steps.steps>
        """)

      assert html =~ "sr-only"
      assert html =~ "Completed"
      assert html =~ "Current step"
      assert html =~ "Upcoming"
    end
  end

  describe "explicit state override" do
    test "error step renders danger fill and an x icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={2}>
          <:step label="A" />
          <:step label="Failed" state="error" />
        </Steps.steps>
        """)

      assert html =~ "bg-danger"
      assert html =~ "hero-x-mark"
    end

    test "loading step renders a spinner" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={1}>
          <:step label="Provisioning" state="loading" />
        </Steps.steps>
        """)

      assert html =~ "animate-spin"
    end

    test "disabled step is de-emphasized but keeps legible text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={1}>
          <:step label="Locked" state="disabled" />
        </Steps.steps>
        """)

      # muted-foreground passes AA per project measurement; never below the floor
      assert html =~ "text-muted-foreground"
    end
  end

  describe "current clamping" do
    test "an out-of-range current does not crash and clamps to the last step" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={99}>
          <:step label="A" />
          <:step label="B" />
        </Steps.steps>
        """)

      # last step becomes current
      assert html =~ ~s(aria-current="step")
    end
  end

  describe "styling config" do
    test "variant + color + size compose onto the markers" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={1} variant="solid" color="success" size="lg">
          <:step label="A" />
        </Steps.steps>
        """)

      assert html =~ "bg-success"
      # lg marker dimension
      assert html =~ "h-10"
    end

    test "per-step color override wins over component color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={2} color="primary">
          <:step label="Green done" color="success" />
          <:step label="Current" />
        </Steps.steps>
        """)

      assert html =~ "bg-success"
    end

    test "per-step icon override shows on an upcoming step" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={1}>
          <:step label="Now" />
          <:step label="Ship" icon="hero-truck" />
        </Steps.steps>
        """)

      assert html =~ "hero-truck"
    end

    test "dot marker mode drops numbers" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={1} marker="dot">
          <:step label="A" />
          <:step label="B" />
        </Steps.steps>
        """)

      refute html =~ ">2</span>"
    end

    test "vertical orientation sets a vertical layout" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={1} orientation="vertical">
          <:step label="A" />
          <:step label="B" />
        </Steps.steps>
        """)

      assert html =~ "flex-col"
    end

    test "dashed connector style is applied" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={2} connector="dashed">
          <:step label="A" />
          <:step label="B" />
        </Steps.steps>
        """)

      assert html =~ "border-dashed"
    end
  end

  describe "content" do
    test "renders label, description, and rich slot body" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Steps.steps current={1}>
          <:step label="Account" description="Email & password" />
          <:step label="Team">
            <a href="/invite">Invite</a>
          </:step>
        </Steps.steps>
        """)

      assert html =~ "Account"
      assert html =~ "Email &amp; password"
      assert html =~ ~s(href="/invite")
    end
  end
end
