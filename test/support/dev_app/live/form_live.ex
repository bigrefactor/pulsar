defmodule Pulsar.DevApp.FormLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Field

  @plans [{"Free", "free"}, {"Pro", "pro"}, {"Enterprise", "enterprise"}]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: build_form(%{}))}
  end

  def handle_event("validate", %{"signup" => params}, socket) do
    {:noreply, assign(socket, form: build_form(params))}
  end

  def handle_event("submit", _params, socket), do: {:noreply, socket}

  defp build_form(params) do
    to_form(params, as: :signup)
  end

  def render(assigns) do
    assigns = assign(assigns, plans: @plans)

    ~H"""
    <.fixture_page name="form" title="Form (combined for form-a11y test)">
      <.fixture_section name="signup" title="Signup form">
        <.form
          for={@form}
          phx-change="validate"
          phx-submit="submit"
          class="grid w-full max-w-2xl grid-cols-1 gap-4"
        >
          <Field.field field={@form[:name]} type="text" required data-fixture-cell="name">
            <:label>Full name</:label>
            <:description>Use your real name</:description>
          </Field.field>
          <Field.field field={@form[:email]} type="email" required data-fixture-cell="email">
            <:label>Email address</:label>
          </Field.field>
          <Field.field
            field={@form[:plan]}
            type="select"
            options={@plans}
            prompt="Pick a plan"
            data-fixture-cell="plan"
          >
            <:label>Plan</:label>
          </Field.field>
          <Field.field
            field={@form[:role]}
            type="radio"
            options={[{"Admin", "admin"}, {"Member", "member"}]}
            data-fixture-cell="role"
          >
            <:label>Role</:label>
          </Field.field>
          <Field.field
            field={@form[:notifications]}
            type="switch"
            data-fixture-cell="notifications"
          >
            <:label>Email notifications</:label>
          </Field.field>
          <Field.field field={@form[:terms]} type="checkbox" required data-fixture-cell="terms">
            <:label>I agree to the terms</:label>
          </Field.field>
          <Field.field field={@form[:notes]} type="textarea" data-fixture-cell="notes">
            <:label>Notes</:label>
          </Field.field>
          <div>
            <Pulsar.Components.Button.button type="submit" variant="solid" color="primary">
              Sign up
            </Pulsar.Components.Button.button>
          </div>
        </.form>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
