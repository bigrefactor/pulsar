defmodule Pulsar.DevApp.StepsLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Steps

  @colors ~w(neutral primary secondary success danger warning info)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    variant = Atom.to_string(assigns.live_action)

    assigns =
      assign(assigns,
        variant: variant,
        colors: @colors,
        sizes: @sizes
      )

    ~H"""
    <.fixture_page name={"steps-#{@variant}"} title={"Steps (#{@variant})"}>
      <.fixture_section
        :for={color <- @colors}
        name={"#{@variant}-#{color}"}
        title={"#{@variant} · #{color}"}
      >
        <Steps.steps
          :for={size <- @sizes}
          variant={@variant}
          color={color}
          size={size}
          current={2}
          aria_label={"Steps #{@variant} #{color} #{size}"}
          data-fixture-cell={"#{@variant}-#{color}-#{size}"}
        >
          <:step label="Cart" description="3 items" />
          <:step label="Shipping" />
          <:step label="Payment" />
        </Steps.steps>
      </.fixture_section>

      <%!-- Variant-agnostic states rendered once (on the solid route) to keep
            each per-variant fixture within the browser-a11y mount budget. --%>
      <.fixture_section :if={@variant == "solid"} name="states" title="states">
        <Steps.steps current={3} aria_label="Steps state vocabulary" data-fixture-cell="states">
          <:step label="Account" />
          <:step label="Email" />
          <:step label="Payment" state="error" />
          <:step label="Provisioning" state="loading" />
          <:step label="Done" />
          <:step label="Locked" state="disabled" />
        </Steps.steps>
      </.fixture_section>

      <.fixture_section :if={@variant == "solid"} name="vertical" title="vertical">
        <Steps.steps
          current={2}
          orientation="vertical"
          aria_label="Steps vertical onboarding"
          data-fixture-cell="vertical"
        >
          <:step label="Create account" description="Email & password" />
          <:step label="Invite your team" description="Add teammates" />
          <:step label="Connect a repo" description="GitHub or GitLab" />
        </Steps.steps>
      </.fixture_section>

      <.fixture_section :if={@variant == "solid"} name="dot" title="dot markers">
        <Steps.steps current={2} marker="dot" aria_label="Steps dot markers" data-fixture-cell="dot">
          <:step label="One" />
          <:step label="Two" />
          <:step label="Three" />
        </Steps.steps>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
