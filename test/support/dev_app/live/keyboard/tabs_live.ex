defmodule Pulsar.DevApp.Keyboard.TabsLive do
  @moduledoc """
  Keyboard-test fixture for `Pulsar.Components.Tabs`.

  Provides a horizontal group and a vertical group with stable tab ids so the
  keyboard suite can press arrow/Home/End keys and assert focus + selection
  move correctly, and that a disabled tab is skipped.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Tabs

  def render(assigns) do
    ~H"""
    <.fixture_page name="keyboard-tabs" title="Tabs keyboard fixture">
      <.fixture_section name="anchor" title="Anchor focusable">
        <button id="kbd-tabs-before" type="button">Anchor</button>
      </.fixture_section>

      <.fixture_section name="horizontal" title="Horizontal (tab 'mid' disabled)">
        <Tabs.tabs id="kbd-h" aria_label="Horizontal">
          <:tab id="kbd-h-one" label="One">One panel</:tab>
          <:tab id="kbd-h-mid" label="Mid" disabled>Mid panel</:tab>
          <:tab id="kbd-h-two" label="Two">Two panel</:tab>
        </Tabs.tabs>
      </.fixture_section>

      <.fixture_section name="vertical" title="Vertical">
        <Tabs.tabs id="kbd-v" orientation="vertical" aria_label="Vertical">
          <:tab id="kbd-v-one" label="One">One panel</:tab>
          <:tab id="kbd-v-two" label="Two">Two panel</:tab>
        </Tabs.tabs>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
