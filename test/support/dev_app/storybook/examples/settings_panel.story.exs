defmodule Pulsar.DevApp.Storybook.Examples.SettingsPanel do
  use PhoenixStorybook.Story, :example

  alias Pulsar.Components.Button
  alias Pulsar.Components.Divider
  alias Pulsar.Components.Field
  alias Pulsar.Components.Header

  def doc, do: "Settings panel"

  @frequency_options [
    {"Immediate", "immediate"},
    {"Daily digest", "daily"},
    {"Weekly summary", "weekly"}
  ]

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       form: Phoenix.Component.to_form(%{}, as: :settings),
       frequency_options: @frequency_options
     )}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <Header.header variant="outline" color="neutral">
        Account settings
        <:subtitle>Manage your profile, notifications, and preferences.</:subtitle>
        <:breadcrumb>Home</:breadcrumb>
        <:breadcrumb>Settings</:breadcrumb>
        <:actions>
          <Button.button variant="outline" color="neutral" phx-click="cancel">Cancel</Button.button>
          <Button.button variant="solid" color="primary" phx-click="save">
            Save changes
          </Button.button>
        </:actions>
      </Header.header>

      <.form
        for={@form}
        phx-submit="save"
        class="mt-8 space-y-6"
      >
        <section>
          <h2 class="mb-4 text-lg font-semibold text-neutral-900 dark:text-neutral-100">Profile</h2>
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field.field field={@form[:display_name]} type="text">
              <:label>Display name</:label>
              <:description>This is how others will see you.</:description>
            </Field.field>

            <Field.field field={@form[:email]} type="email" required>
              <:label>Email address</:label>
            </Field.field>
          </div>

          <div class="mt-4">
            <Field.field field={@form[:bio]} type="textarea">
              <:label>Bio</:label>
              <:description>A short description about yourself.</:description>
            </Field.field>
          </div>
        </section>

        <Divider.divider />

        <section>
          <h2 class="mb-4 text-lg font-semibold text-neutral-900 dark:text-neutral-100">
            Notifications
          </h2>
          <div class="space-y-4">
            <Field.field field={@form[:email_notifications]} type="switch">
              <:label>Email notifications</:label>
              <:description>Receive updates and alerts via email.</:description>
            </Field.field>

            <Field.field field={@form[:sms_notifications]} type="switch">
              <:label>SMS notifications</:label>
              <:description>Receive text messages for urgent alerts.</:description>
            </Field.field>

            <Field.field
              field={@form[:notification_frequency]}
              type="select"
              options={@frequency_options}
              prompt="Choose frequency"
            >
              <:label>Preferred frequency</:label>
              <:description>How often you want to receive notification digests.</:description>
            </Field.field>
          </div>
        </section>

        <Divider.divider />

        <div class="flex items-center justify-end gap-3">
          <Button.button variant="outline" color="neutral" phx-click="cancel">Cancel</Button.button>
          <Button.button type="submit" variant="solid" color="primary">Save changes</Button.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("save", _params, socket), do: {:noreply, socket}
  def handle_event("cancel", _params, socket), do: {:noreply, socket}
end
