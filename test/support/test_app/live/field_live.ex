defmodule Pulsar.TestApp.FieldLive do
  @moduledoc false
  use Pulsar.TestApp.Web, :live_view

  alias Pulsar.Components.Field

  @types ~w(text email password number tel url search date textarea checkbox switch select radio)

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       form:
         to_form(
           %{
             "text" => "value",
             "email" => "user@example.com",
             "checkbox" => true,
             "switch" => true,
             "select" => "1",
             "radio" => "1",
             "textarea" => "multi line"
           },
           as: :demo
         )
     )}
  end

  def render(assigns) do
    assigns = assign(assigns, types: @types)

    ~H"""
    <.fixture_page name="field" title="Field">
      <.fixture_section name="types" title="All field types (canonical wrapper)">
        <.form for={@form} class="grid w-full grid-cols-1 gap-4 md:grid-cols-2">
          <Field.field
            :for={type <- @types}
            field={@form[type]}
            type={type}
            options={if type in ["select", "radio"], do: [{"One", "1"}, {"Two", "2"}], else: nil}
            data-fixture-cell={"type-#{type}"}
          >
            <:label>{type}</:label>
            <:description>Help text for {type}</:description>
          </Field.field>
        </.form>
      </.fixture_section>
      <.fixture_section name="states" title="Required, disabled, readonly, error">
        <.form for={@form} class="grid w-full grid-cols-1 gap-4 md:grid-cols-2">
          <Field.field
            field={@form[:required]}
            type="text"
            required
            data-fixture-cell="state-required"
          >
            <:label>Required</:label>
          </Field.field>
          <Field.field
            field={@form[:disabled]}
            type="text"
            disabled
            data-fixture-cell="state-disabled"
          >
            <:label>Disabled</:label>
          </Field.field>
          <Field.field
            field={@form[:readonly]}
            type="text"
            readonly
            data-fixture-cell="state-readonly"
          >
            <:label>Readonly</:label>
          </Field.field>
        </.form>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
