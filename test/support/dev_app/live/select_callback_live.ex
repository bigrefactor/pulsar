defmodule Pulsar.DevApp.SelectCallbackLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Select

  def mount(_params, _session, socket) do
    {:ok, assign(socket, last_removed: nil)}
  end

  def handle_event("remove-badge", %{"option" => option}, socket) do
    {:noreply, assign(socket, last_removed: option)}
  end

  def render(assigns) do
    ~H"""
    <.fixture_page name="select-callback" title="Select badge callback">
      <p>Last removed: <span id="sel-callback-option">{@last_removed || "none"}</span></p>
      <Select.select
        id="callback-skills"
        name="callback_skills"
        multiple
        options={[{"Elixir", "elixir"}]}
        value={["elixir"]}
        on_remove_badge={fn option -> JS.push("remove-badge", value: %{option: option}) end}
      />
    </.fixture_page>
    """
  end
end
