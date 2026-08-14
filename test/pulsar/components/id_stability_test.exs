defmodule Pulsar.Components.IdStabilityTest do
  @moduledoc """
  Renders every component twice and asserts the markup is byte-identical, so a
  component that starts minting a fresh id per render fails here immediately.

  Six branches are left uncovered, because they still generate an id on every
  render. Adding a case for any of them produces a red test — check it against
  this list before filing a bug or "completing the matrix".

  Four are settled trade-offs, where the churn is understood to cost nothing:

    * `alert` when `dismissible` — the id exists only so the dismiss button can
      point `aria-controls` at it, within the same render.
    * `menu_section` with a `label` — same, for the label's `aria-labelledby`.
    * `dropdown_menu_group` with a `label` — same.
    * `button` with `as={:a}` or `as={:div}` — LiveView requires an id on a
      `phx-hook` root, and these branches accept `href`/`navigate`, so the id
      cannot be made required. The hook attaches listeners and holds no client
      state, so remounting it on a churned id costs nothing.

  The other two are known gaps, not decisions — do not read either as settled.
  Both land a generated id on a `phx-hook` root, which is exactly the churn the
  rest of this file exists to prevent. Neither is reachable from a wired-up
  call, and closing either is a contract change:

    * `input_otp` with neither a `field`, a `name`, nor an `id` — its hook root
      is `"<id>-otp"`, so remounting it on a churned id discards a partially
      typed code. The case is degenerate in the same way `radio_group`'s is:
      `on_complete` runs a `%JS{}` command and never sends the field value, so
      an `input_otp` with no field and no name has no path to the server for
      the code either.
    * `radio_group` with neither a `field` nor a `name` — `resolve_id/2` falls
      through to a generated id. The other five form inputs raise when unbound
      without a `name`; `radio_group` has no such check. It was left as-is
      because the case is degenerate (a group with no field and no name submits
      nowhere).

  For both, the covered case supplies a `name`; passing either a `name` or an
  explicit `id` makes the id stable.

  Every one of these is a branch of a component that IS covered here in its
  other form, so a regression that reintroduces a generated id elsewhere in the
  same component still fails.

  The later describes cover the other half of the contract: that an id derived
  from a `name` is *id-shaped*. A raw name is not — `switch` interpolates its
  resolved id into a CSS selector, where `#user[notifications]` parses as
  `#user` plus an attribute selector and matches nothing. Normalization does not
  make the id unique, and the final describe pins that: siblings sharing a name
  share an id, and only an explicit per-instance `id` separates them.
  """

  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Accordion
  alias Pulsar.Components.Alert
  alias Pulsar.Components.AlertDialog
  alias Pulsar.Components.Button
  alias Pulsar.Components.Calendar
  alias Pulsar.Components.Checkbox
  alias Pulsar.Components.Collapsible
  alias Pulsar.Components.Command
  alias Pulsar.Components.DatePicker
  alias Pulsar.Components.Drawer
  alias Pulsar.Components.DropdownMenu
  alias Pulsar.Components.Flash
  alias Pulsar.Components.FlashGroup
  alias Pulsar.Components.Input
  alias Pulsar.Components.InputOtp
  alias Pulsar.Components.Menu
  alias Pulsar.Components.Modal
  alias Pulsar.Components.Navbar
  alias Pulsar.Components.Popover
  alias Pulsar.Components.RadioGroup
  alias Pulsar.Components.Select
  alias Pulsar.Components.Sidebar
  alias Pulsar.Components.Switch
  alias Pulsar.Components.Table
  alias Pulsar.Components.Tabs
  alias Pulsar.Components.Textarea
  alias Pulsar.Components.Tooltip
  alias Pulsar.CoreComponents

  describe "rendering twice produces identical markup" do
    test "button" do
      assigns = %{}
      m = ~H"<Button.button>Go</Button.button>"
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "navbar" do
      assigns = %{}
      m = ~H|<Navbar.navbar label="Main">Content</Navbar.navbar>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "alert, not dismissible" do
      assigns = %{}
      m = ~H|<Alert.alert color="info" title="Heads up" />|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "accordion" do
      assigns = %{}

      m = ~H"""
      <Accordion.accordion id="faq">
        <:item title="One">Content</:item>
      </Accordion.accordion>
      """

      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "collapsible" do
      assigns = %{}
      m = ~H|<Collapsible.collapsible id="d"><:trigger>More</:trigger>Body</Collapsible.collapsible>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "popover" do
      assigns = %{}
      m = ~H|<Popover.popover id="tips"><:trigger>Open</:trigger>Body</Popover.popover>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "tabs" do
      assigns = %{}
      m = ~H|<Tabs.tabs id="s">
  <:tab label="One">Content</:tab>
</Tabs.tabs>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "flash" do
      assigns = %{}
      m = ~H|<Flash.flash id="notice" color="info">Saved</Flash.flash>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "flash_group" do
      assigns = %{flash: %{"info" => "Saved"}}
      m = ~H|<FlashGroup.flash_group flash={@flash} />|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "sidebar" do
      assigns = %{}
      m = ~H|<Sidebar.sidebar id="nav">Links</Sidebar.sidebar>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "menu" do
      assigns = %{}
      m = ~H|<Menu.menu id="a">
  <Menu.menu_item>Edit</Menu.menu_item>
</Menu.menu>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "menu_group" do
      assigns = %{}

      m = ~H"""
      <Menu.menu_group id="g" label="Actions">
        <Menu.menu_item>Edit</Menu.menu_item>
      </Menu.menu_group>
      """

      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "menu_section, unlabelled" do
      assigns = %{}
      m = ~H|<Menu.menu_section>
  <Menu.menu_item>Edit</Menu.menu_item>
</Menu.menu_section>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "dropdown_menu" do
      assigns = %{}

      m = ~H"""
      <DropdownMenu.dropdown_menu id="a">
        <:trigger>Open</:trigger>
        <DropdownMenu.dropdown_menu_item>Edit</DropdownMenu.dropdown_menu_item>
      </DropdownMenu.dropdown_menu>
      """

      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "dropdown_menu_submenu" do
      assigns = %{}

      m = ~H"""
      <DropdownMenu.dropdown_menu_submenu id="sub" label="More">
        <DropdownMenu.dropdown_menu_item>Edit</DropdownMenu.dropdown_menu_item>
      </DropdownMenu.dropdown_menu_submenu>
      """

      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "dropdown_menu_group, unlabelled" do
      assigns = %{}

      m = ~H"""
      <DropdownMenu.dropdown_menu_group>
        <DropdownMenu.dropdown_menu_item>Edit</DropdownMenu.dropdown_menu_item>
      </DropdownMenu.dropdown_menu_group>
      """

      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "modal" do
      assigns = %{}
      m = ~H|<Modal.modal id="c" title="Confirm">Body</Modal.modal>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "table" do
      assigns = %{}

      m = ~H"""
      <Table.table id="users" rows={[%{name: "Ada"}]} aria_label="Users">
        <:col :let={u} label="Name">{u.name}</:col>
      </Table.table>
      """

      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "drawer" do
      assigns = %{}
      m = ~H|<Drawer.drawer id="filters" title="Filters">Body</Drawer.drawer>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "alert_dialog" do
      assigns = %{}
      m = ~H|<AlertDialog.alert_dialog id="del" title="Delete?">Body</AlertDialog.alert_dialog>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "tooltip" do
      assigns = %{}
      m = ~H|<Tooltip.tooltip id="tip"><:trigger>Save</:trigger>Saves</Tooltip.tooltip>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "input, unbound with a name" do
      assigns = %{}
      m = ~H|<Input.input name="email" value="" />|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "checkbox, unbound with a name" do
      assigns = %{}
      m = ~H|<Checkbox.checkbox name="agree" />|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "switch, unbound with a name" do
      assigns = %{}
      m = ~H|<Switch.switch name="notify" />|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "radio_group, unbound with a name" do
      assigns = %{}

      m = ~H"""
      <RadioGroup.radio_group name="plan">
        <:option value="free">Free</:option>
      </RadioGroup.radio_group>
      """

      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "select, unbound with an explicit id" do
      assigns = %{}
      m = ~H|<Select.select id="country-select" name="country" options={[{"US", "us"}]} />|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "textarea, unbound with a name" do
      assigns = %{}
      m = ~H|<Textarea.textarea name="bio" />|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "calendar" do
      assigns = %{}
      m = ~H|<Calendar.calendar id="cal" />|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "date_picker" do
      assigns = %{}
      m = ~H|<DatePicker.date_picker id="dp" />|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "core_components button" do
      assigns = %{}
      m = ~H|<CoreComponents.button>Go</CoreComponents.button>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "core_components header" do
      assigns = %{}
      m = ~H|<CoreComponents.header>Title</CoreComponents.header>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "core_components table" do
      assigns = %{}

      m = ~H"""
      <CoreComponents.table id="users" rows={[%{name: "Ada"}]} aria_label="Users">
        <:col :let={u} label="Name">{u.name}</:col>
      </CoreComponents.table>
      """

      assert rendered_to_string(m) == rendered_to_string(m)
    end

    test "core_components list" do
      assigns = %{}
      m = ~H|<CoreComponents.list>
  <:item title="Name">Ada</:item>
</CoreComponents.list>|
      assert rendered_to_string(m) == rendered_to_string(m)
    end
  end

  describe "the required-id contract" do
    @required_id [
      {Accordion, :accordion},
      {AlertDialog, :alert_dialog},
      {Collapsible, :collapsible},
      {Command, :command},
      {Drawer, :drawer},
      {DropdownMenu, :dropdown_menu},
      {DropdownMenu, :dropdown_menu_submenu},
      {Flash, :flash},
      {Menu, :menu},
      {Menu, :menu_group},
      {Modal, :modal},
      {Popover, :popover},
      {Sidebar, :sidebar},
      {Table, :table},
      {Tabs, :tabs},
      {Tooltip, :tooltip}
    ]

    for {module, function} <- @required_id do
      test "#{inspect(module)}.#{function}/1 requires :id" do
        attrs = unquote(module).__components__()[unquote(function)].attrs
        id_attr = Enum.find(attrs, &(&1.name == :id))

        assert id_attr, "#{unquote(function)}/1 declares no :id attr"
        assert id_attr.required, "#{unquote(function)}/1's :id is not required"
      end
    end
  end

  describe "components that must NOT require an id" do
    @optional_id [
      {Alert, :alert},
      {Button, :button},
      {Calendar, :calendar},
      {Checkbox, :checkbox},
      {DatePicker, :date_picker},
      {DropdownMenu, :dropdown_menu_group},
      {FlashGroup, :flash_group},
      {Input, :input},
      {InputOtp, :input_otp},
      {Menu, :menu_section},
      {Navbar, :navbar},
      {RadioGroup, :radio_group},
      {Select, :select},
      {Switch, :switch},
      {Textarea, :textarea}
    ]

    for {module, function} <- @optional_id do
      test "#{inspect(module)}.#{function}/1 leaves :id optional" do
        attrs = unquote(module).__components__()[unquote(function)].attrs
        id_attr = Enum.find(attrs, &(&1.name == :id))

        assert id_attr, "#{unquote(function)}/1 declares no :id attr"
        refute id_attr.required, "#{unquote(function)}/1's :id became required"
      end
    end
  end

  describe "a name-derived id is id-shaped" do
    test "checkbox" do
      assigns = %{}
      html = rendered_to_string(~H|<Checkbox.checkbox name="user[terms]" />|)
      assert html =~ ~s(id="user_terms")
      refute html =~ ~s(id="user[terms]")
    end

    test "input" do
      assigns = %{}
      html = rendered_to_string(~H|<Input.input name="user[email]" />|)
      assert html =~ ~s(id="user_email")
      refute html =~ ~s(id="user[email]")
    end

    test "switch" do
      assigns = %{}
      html = rendered_to_string(~H|<Switch.switch name="user[notifications]" />|)
      assert html =~ ~s(id="user_notifications")
      refute html =~ ~s(id="user[notifications]")
    end

    test "textarea" do
      assigns = %{}
      html = rendered_to_string(~H|<Textarea.textarea name="user[bio]" />|)
      assert html =~ ~s(id="user_bio")
      refute html =~ ~s(id="user[bio]")
    end

    test "radio_group" do
      assigns = %{}

      m = ~H"""
      <RadioGroup.radio_group name="user[plan]">
        <:option value="basic">Basic</:option>
      </RadioGroup.radio_group>
      """

      html = rendered_to_string(m)
      assert html =~ ~s(id="user_plan")
      refute html =~ ~s(id="user[plan]")
    end

    test "an array name loses its brackets too" do
      assigns = %{}
      html = rendered_to_string(~H|<Checkbox.checkbox name="tags[]" value="a" />|)
      assert html =~ ~s(id="tags_")
    end
  end

  describe "switch's click-target overlay" do
    test "dispatches to the id the switch actually rendered" do
      assigns = %{}
      html = rendered_to_string(~H|<Switch.switch name="user[notifications]" />|)

      assert [id] = Regex.run(~r/id="([^"]+)"/, html, capture: :all_but_first)
      assert html =~ "##{id}"
      refute id =~ ~r/[^\w-]/
    end
  end

  describe "siblings sharing a name share an id" do
    test "the caller must disambiguate them with an explicit id" do
      assigns = %{}

      shared =
        rendered_to_string(~H"""
        <Checkbox.checkbox :for={t <- ["a", "b"]} name="tags[]" value={t} />
        """)

      assert length(Regex.scan(~r/id="tags_"/, shared)) == 2

      distinct =
        rendered_to_string(~H"""
        <Checkbox.checkbox :for={t <- ["a", "b"]} name="tags[]" value={t} id={"tags-#{t}"} />
        """)

      assert distinct =~ ~s(id="tags-a")
      assert distinct =~ ~s(id="tags-b")
    end
  end
end
