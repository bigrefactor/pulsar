defmodule Pulsar.DevApp.Keyboard.PopoverLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Button
  alias Pulsar.Components.Popover

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0, applied: nil)}
  end

  def handle_event("bump", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("apply", %{"query" => query}, socket) do
    {:noreply, assign(socket, applied: query)}
  end

  def render(assigns) do
    ~H"""
    <main class="space-y-8 p-8">
      <button id="kbd-pop-before" type="button">before</button>

      <Popover.popover id="kbd-pop">
        <:trigger>
          <button id="kbd-pop-trigger" type="button">Open popover</button>
        </:trigger>
        <a id="kbd-pop-inside" href="#">Inside link</a>
      </Popover.popover>

      <button id="kbd-pop-after" type="button">after</button>

      <button id="kbd-pop-patch-bump" type="button" phx-click="bump">bump</button>

      <Popover.popover id="kbd-pop-patch">
        <:trigger>
          <Button.button id="kbd-pop-patch-trigger">Patched {@count}</Button.button>
        </:trigger>
        <a id="kbd-pop-patch-inside" href="#">Inside patched link</a>
      </Popover.popover>

      <button id="kbd-pop-form-show-outside" type="button" phx-click={Popover.show("kbd-pop-form")}>
        open from outside
      </button>

      <Popover.popover id="kbd-pop-form">
        <:trigger>
          <button id="kbd-pop-form-trigger" type="button">Open filters</button>
        </:trigger>
        <form phx-submit={JS.push("apply") |> Popover.hide("kbd-pop-form")}>
          <input id="kbd-pop-form-query" type="text" name="query" value="blue" aria-label="Query" />
          <button id="kbd-pop-form-submit" type="submit">Apply</button>
        </form>
      </Popover.popover>

      <p id="kbd-pop-form-applied">{@applied}</p>

      <div class="text-right cursor-pointer">
        <Popover.popover id="kbd-pop-aligned">
          <:trigger>
            <button id="kbd-pop-aligned-trigger" type="button">Open aligned popover</button>
          </:trigger>
          Popover body
        </Popover.popover>
      </div>
    </main>
    """
  end
end
