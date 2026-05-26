defmodule Pulsar.DevApp.FormLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Field
  alias Pulsar.Components.Form, as: PulsarForm

  @plans [{"Free", "free"}, {"Pro", "pro"}, {"Enterprise", "enterprise"}]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: build_form(%{}, errors: []))}
  end

  def handle_event("validate", %{"signup" => params}, socket) do
    errors = validate(params)
    {:noreply, assign(socket, form: build_form(params, errors: errors))}
  end

  def handle_event("submit", %{"signup" => params}, socket) do
    case validate(params) do
      [] ->
        {:noreply, socket}

      errors ->
        # Phoenix tags inputs the user hasn't interacted with via
        # `_unused_<field>` keys; `Phoenix.Component.used_input?/1` then returns
        # false for them and the Field component's `:touched` default suppresses
        # the error UI. Drop those markers on submit so every field counts as
        # "used" and errors render across the whole form.
        params = drop_unused_markers(params)

        {:noreply, assign(socket, form: build_form(params, errors: errors, action: :validate))}
    end
  end

  defp drop_unused_markers(params) do
    Map.reject(params, fn {key, _} -> String.starts_with?(key, "_unused_") end)
  end

  defp build_form(params, opts) do
    to_form(params, [as: :signup] ++ opts)
  end

  defp validate(params) do
    []
    |> validate_required(params, "name", "can't be blank")
    |> validate_required(params, "email", "can't be blank")
    |> validate_email(params, "email")
    |> validate_required(params, "terms", "you must accept the terms")
  end

  defp validate_required(errors, params, field, message) do
    case Map.get(params, field) do
      nil -> [{String.to_atom(field), {message, []}} | errors]
      "" -> [{String.to_atom(field), {message, []}} | errors]
      "false" -> [{String.to_atom(field), {message, []}} | errors]
      _ -> errors
    end
  end

  defp validate_email(errors, params, field) do
    value = Map.get(params, field, "")

    cond do
      value in [nil, ""] -> errors
      String.contains?(value, "@") -> errors
      true -> [{String.to_atom(field), {"must include @", []}} | errors]
    end
  end

  def render(assigns) do
    assigns = assign(assigns, plans: @plans)

    ~H"""
    <.fixture_page name="form" title="Form (combined for form-a11y test)">
      <.fixture_section name="signup" title="Signup form">
        <PulsarForm.form
          for={@form}
          phx-change="validate"
          phx-submit="submit"
          novalidate
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
        </PulsarForm.form>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
