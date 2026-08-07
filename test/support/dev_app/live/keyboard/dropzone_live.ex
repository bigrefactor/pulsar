defmodule Pulsar.DevApp.Keyboard.DropzoneLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Dropzone

  def mount(_params, _session, socket) do
    {:ok, allow_upload(socket, :files, accept: ~w(.png .jpg), max_entries: 2, max_file_size: 2_000_000)}
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  def render(assigns) do
    ~H"""
    <form id="kbd-dz-form" phx-change="validate">
      <Dropzone.dropzone id="kbd-dz" upload={@uploads.files} hint="PNG or JPG, up to 2 MB" />
    </form>
    """
  end
end
