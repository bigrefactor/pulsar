defmodule Pulsar.DevApp.AlertLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Alert

  @variants ~w(solid outline ghost)
  @colors ~w(neutral primary secondary success danger warning info)

  def render(assigns) do
    assigns = assign(assigns, variants: @variants, colors: @colors)

    ~H"""
    <.fixture_page name="alert" title="Alert">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <Alert.alert
          :for={color <- @colors}
          variant={variant}
          color={color}
          title={"#{color} title"}
          description={"A #{color} #{variant} alert."}
          data-fixture-cell={"#{variant}-#{color}"}
        />
      </.fixture_section>

      <.fixture_section name="sizes" title="Sizes">
        <Alert.alert
          :for={size <- ~w(sm md lg)}
          size={size}
          color="info"
          title="Heads up"
          description={"Size #{size}."}
          data-fixture-cell={"size-#{size}"}
        />
      </.fixture_section>

      <.fixture_section name="dismissible" title="Dismissible">
        <Alert.alert
          color="warning"
          title="Heads up"
          description="You can dismiss me."
          dismissible
          data-fixture-cell="dismissible"
        />
      </.fixture_section>

      <.fixture_section name="actions" title="With actions">
        <Alert.alert
          color="danger"
          title="Subscription expired"
          description="Renew to keep your data."
          data-fixture-cell="actions"
        >
          <:actions>
            <button type="button" class="text-sm font-medium underline">Renew</button>
          </:actions>
        </Alert.alert>
      </.fixture_section>

      <.fixture_section name="description-only" title="Description only (no title)">
        <Alert.alert
          color="success"
          description="Your changes have been saved."
          data-fixture-cell="description-only"
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
