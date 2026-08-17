defmodule Pulsar.DevApp.Keyboard.ComboboxLive do
  @moduledoc """
  Interaction-test fixture for `Pulsar.Components.Combobox`.

  Four comboboxes: one single-select inside a form with `phx-change`, one
  single-select standalone with no form at all, one multi-select also inside a
  form with `phx-change`, and one whose options come from a slow async source
  behind a debounce. Behavior comes from the `.PulsarCombobox` colocated hook.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Combobox

  @options [
    {"Alpha", "alpha"},
    {"Beta", "beta"},
    [key: "Gamma", value: "gamma", disabled: true],
    {"Betamax", "betamax"}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:validations, 0)
     |> assign(:form, build_form("", 0))
     |> assign(:received, "")
     |> assign(:received_tags, "")}
  end

  # Every validate rebuilds the form with a changed revision, the way a
  # changeset-backed host does: the rebuilt form is a genuinely new assign, so
  # the change reaches the combobox's `update/2` instead of being skipped as
  # structurally equal.
  def handle_event("validate", %{"picked" => %{"owner" => owner}}, socket) do
    validations = socket.assigns.validations + 1

    {:noreply,
     socket
     |> assign(:received, owner)
     |> assign(:validations, validations)
     |> assign(:form, build_form(owner, validations))}
  end

  # The multi-select writes into a hidden <select multiple>, so an empty
  # selection drops the key from the params entirely.
  def handle_event("validate_tags", params, socket) do
    {:noreply, assign(socket, :received_tags, params |> Map.get("tags", []) |> Enum.join(" "))}
  end

  defp build_form(owner, revision) do
    to_form(%{"owner" => owner, "revision" => to_string(revision)}, as: :picked)
  end

  # Slow enough that the results cannot arrive in the same round trip as the
  # query, and returning values `options` never held so they can only have come
  # from here.
  def slow_search(query, _options) do
    Process.sleep(150)

    Enum.filter(
      [{"Remote One", "r1"}, {"Remote Two", "r2"}],
      fn {label, _value} -> String.contains?(String.downcase(label), String.downcase(query)) end
    )
  end

  def render(assigns) do
    assigns = assign(assigns, :options, @options)

    ~H"""
    <.fixture_page name="keyboard-combobox" title="Combobox interaction fixture">
      <.fixture_section name="form" title="Single-select inside a form">
        <.form for={@form} phx-change="validate">
          <Combobox.combobox
            id="kbd-form"
            field={@form[:owner]}
            label="Pick an owner"
            options={@options}
          />
        </.form>
        <p id="kbd-form-received">{@received}</p>
        <p id="kbd-form-validations">{@validations}</p>
      </.fixture_section>

      <.fixture_section name="standalone" title="Single-select with no form">
        <Combobox.combobox id="kbd-solo" label="Pick a value" options={@options} />
      </.fixture_section>

      <.fixture_section name="multiple" title="Multi-select inside a form">
        <.form for={%{}} phx-change="validate_tags">
          <Combobox.combobox
            id="kbd-multi"
            name="tags[]"
            label="Pick tags"
            options={@options}
            multiple
          />
        </.form>
        <p id="kbd-multi-received">{@received_tags}</p>
      </.fixture_section>

      <.fixture_section name="async" title="Async source behind a debounce">
        <Combobox.combobox
          id="kbd-async"
          label="Search remotely"
          options={[]}
          filter={&__MODULE__.slow_search/2}
          async
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
