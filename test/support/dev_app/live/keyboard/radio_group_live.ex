defmodule Pulsar.DevApp.Keyboard.RadioGroupLive do
  @moduledoc """
  Keyboard-test fixture for `Pulsar.Components.RadioGroup`.

  Provides what `radio_group_live.ex` (`/components/radio_group`) lacks:

    * an `<button>` anchor *before* the first group so a test can Tab
      INTO the group from a known starting element; and
    * a group with a pre-checked option (`value="2"`) so backward/forward
      tab into the group lands on the checked radio rather than the first
      DOM-order radio — this is the browser-native APG Radio Group
      tab-into-checked behavior the keyboard test suite exercises.

  The horizontal group has no pre-check so the test can press
  `ArrowRight` from option 0 and assert selection moves to option 1.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.RadioGroup

  @options [{"One", "1"}, {"Two", "2"}, {"Three", "3"}]

  def render(assigns) do
    assigns = assign(assigns, options: @options)

    ~H"""
    <.fixture_page name="keyboard-radio-group" title="RadioGroup keyboard fixture">
      <.fixture_section name="anchor" title="Anchor focusable">
        <button id="kbd-rg-before" type="button">Anchor</button>
      </.fixture_section>

      <.fixture_section name="checked" title="Vertical group with option 2 pre-checked">
        <RadioGroup.radio_group
          id="kbd-rg-checked"
          name="kbd_rg_checked"
          value="2"
        >
          <:option :for={{label, value} <- @options} value={value}>{label}</:option>
        </RadioGroup.radio_group>
      </.fixture_section>

      <.fixture_section name="horizontal" title="Horizontal group (no pre-check)">
        <RadioGroup.radio_group
          id="kbd-rg-horiz"
          name="kbd_rg_horiz"
          orientation="horizontal"
        >
          <:option :for={{label, value} <- @options} value={value}>{label}</:option>
        </RadioGroup.radio_group>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
