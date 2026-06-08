defmodule Pulsar.Components.TableTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.LiveStream
  alias Pulsar.Components.Table

  describe "table/1 basic functionality" do
    test "renders basic table with defaults" do
      assigns = %{
        users: [%{email: "alice@example.com", name: "Alice"}]
      }

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
          <:col :let={user} label="Email">{user.email}</:col>
        </Table.table>
        """)

      assert html =~ ~s(<table)
      assert html =~ ~s(<thead)
      assert html =~ ~s(<tbody)
      assert html =~ "Alice"
      assert html =~ "alice@example.com"
      # Default color
      assert html =~ ~s(bg-neutral)
    end

    test "renders table headers correctly" do
      assigns = %{users: []}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col label="Full Name" />
          <:col label="Email Address" />
        </Table.table>
        """)

      assert html =~ ~s(Full Name)
      assert html =~ ~s(Email Address)
      assert html =~ ~s(scope="col")
    end

    test "renders empty state correctly" do
      assigns = %{users: []}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col label="Name" />
          <:col label="Email" />
        </Table.table>
        """)

      assert html =~ ~s(No data available)
      assert html =~ ~s(text-center py-12)
    end
  end

  describe "row motion tokens" do
    test "rows use the fast color-transition motion tokens" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~s(transition-colors)
      assert html =~ ~s(duration-fast)
      assert html =~ ~s(ease-standard)
      refute html =~ ~s(duration-normal)
    end
  end

  describe "table variants" do
    test "renders solid variant (default)" do
      assigns = %{users: []}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} variant="solid">
          <:col label="Name" />
        </Table.table>
        """)

      assert html =~ ~s(rounded-box overflow-hidden)
      assert html =~ ~s(bg-neutral)
    end

    test "renders outline variant" do
      assigns = %{users: []}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} variant="outline">
          <:col label="Name" />
        </Table.table>
        """)

      assert html =~ ~s(rounded-box border)
      assert html =~ ~s(border-border)
      assert html =~ ~s(border-b-2)
    end

    test "renders ghost variant" do
      assigns = %{users: []}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} variant="ghost">
          <:col label="Name" />
        </Table.table>
        """)

      assert html =~ ~s(border-b border-border/30)
    end
  end

  describe "table colors" do
    test "renders primary color" do
      assigns = %{users: []}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} color="primary">
          <:col label="Name" />
        </Table.table>
        """)

      assert html =~ ~s(bg-primary text-primary-foreground)
    end

    test "renders danger color" do
      assigns = %{users: []}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} color="danger">
          <:col label="Name" />
        </Table.table>
        """)

      assert html =~ ~s(bg-danger text-danger-foreground)
    end
  end

  describe "table sizes" do
    test "renders xs size" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} size="xs">
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      # Header
      assert html =~ ~s(px-2 py-1 text-xs font-medium)
      # Cell
      assert html =~ ~s(px-2 py-1 text-xs)
    end

    test "renders md size (default)" do
      assigns = %{users: [%{name: "Charlie"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} size="md">
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~s(px-4 py-2 text-base font-medium)
      assert html =~ ~s(px-4 py-2 text-base)
    end
  end

  describe "action slots" do
    test "renders action column when actions present" do
      assigns = %{users: [%{id: 1, name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
          <:action :let={user}>
            <button>Edit {user.id}</button>
          </:action>
        </Table.table>
        """)

      assert html =~ ~s(Actions)
      assert html =~ ~s(sr-only)
      assert html =~ ~s(Edit 1)
      assert html =~ ~s(flex items-center gap-2 justify-end)
    end

    test "no action header when no actions" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      refute html =~ ~s(Actions)
    end
  end

  describe "row click handling" do
    test "adds cursor-pointer class when row_click provided" do
      assigns = %{
        handle_click: fn _user -> nil end,
        users: [%{id: 1, name: "Alice"}]
      }

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} row_click={@handle_click}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~s(cursor-pointer)
      assert html =~ ~s(hover:bg-surface-1-hover)
    end

    test "no clickable styling when row_click not provided" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      refute html =~ ~s(cursor-pointer)
      refute html =~ ~s(hover:bg-surface-1-hover)
    end
  end

  describe "striped rows" do
    test "applies striped classes when enabled" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} striped={true}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ "[&amp;_tbody_tr:nth-child(even)]:bg-surface-1/50"
    end

    test "no striped classes when disabled" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} striped={false}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      refute html =~ "[&amp;_tbody_tr:nth-child(even)]"
    end
  end

  describe "sticky header" do
    test "applies sticky classes when enabled" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} sticky_header={true}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ "[&amp;_thead_th]:sticky"
      assert html =~ "[&amp;_thead_th]:top-0"
      assert html =~ "[&amp;_thead_th]:z-docked"
    end

    test "applies size-appropriate scroll-margin on rows so focus is not obscured" do
      for {size, expected} <- [
            {"xs", "[&amp;_tbody_tr]:scroll-mt-6"},
            {"sm", "[&amp;_tbody_tr]:scroll-mt-8"},
            {"md", "[&amp;_tbody_tr]:scroll-mt-10"},
            {"lg", "[&amp;_tbody_tr]:scroll-mt-14"},
            {"xl", "[&amp;_tbody_tr]:scroll-mt-16"}
          ] do
        assigns = %{users: [%{name: "Alice"}], size: size}

        html =
          rendered_to_string(~H"""
          <Table.table id="users" rows={@users} size={@size} sticky_header={true}>
            <:col :let={user} label="Name">{user.name}</:col>
          </Table.table>
          """)

        assert html =~ expected,
               "expected size=#{size} sticky table to include #{expected}"
      end
    end

    test "no scroll-margin when sticky_header is disabled" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} size="md" sticky_header={false}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      refute html =~ "scroll-mt"
    end

    test "no sticky classes when disabled" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} sticky_header={false}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      refute html =~ "[&amp;_thead_th]:sticky"
    end
  end

  describe "loading state" do
    test "shows skeleton rows when loading" do
      assigns = %{users: []}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} loading={true}>
          <:col label="Name" />
          <:col label="Email" />
        </Table.table>
        """)

      assert html =~ ~s(animate-pulse-subtle)
      assert html =~ ~s(bg-surface-1)
      refute html =~ ~s(No data available)
    end

    test "hides actual data when loading" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} loading={true}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      refute html =~ ~s(Alice)
      assert html =~ ~s(animate-pulse-subtle)
    end
  end

  describe "empty state" do
    test "shows custom empty content when provided" do
      assigns = %{users: []}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col label="Name" />
          <:empty>
            <div class="custom-empty">Nothing to see here</div>
          </:empty>
        </Table.table>
        """)

      assert html =~ ~s(custom-empty)
      assert html =~ ~s(Nothing to see here)
      refute html =~ ~s(No data available)
    end

    test "shows default empty state when no custom content" do
      assigns = %{users: []}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col label="Name" />
        </Table.table>
        """)

      assert html =~ ~s(No data available)
      assert html =~ ~s(Data will appear here when available)
    end
  end

  describe "accessibility" do
    test "includes proper semantic markup" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~s(<table)
      assert html =~ ~s(<thead)
      assert html =~ ~s(<tbody)
      assert html =~ ~s(scope="col")
    end

    test "includes screen reader text for actions" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
          <:action :let={_user}>
            <button>Edit</button>
          </:action>
        </Table.table>
        """)

      assert html =~ ~s(sr-only)
      assert html =~ ~s(Actions)
    end

    test "adds keyboard accessibility attributes when row_click provided" do
      assigns = %{
        handle_click: fn _user -> nil end,
        users: [%{id: 1, name: "Alice"}]
      }

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} row_click={@handle_click}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(role="button")
      assert html =~ ~s(phx-hook=".PulsarTableRow")
      assert html =~ ~s(focus-visible:outline-none focus-visible:ring-2)
    end

    test "decorative SVG has aria-hidden" do
      assigns = %{users: []}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col label="Name" />
        </Table.table>
        """)

      assert html =~ ~s(aria-hidden="true")
    end
  end

  describe "ID handling" do
    test "generates ID when not provided" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      # Should have generated ID on tbody for stream updates
      assert html =~ ~r/id="table-\d+-tbody"/
    end

    test "uses provided ID when given" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="my-custom-table" rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~s(id="my-custom-table-tbody")
    end
  end

  describe "global attributes" do
    test "forwards global attributes to table element" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table
          id="users"
          rows={@users}
          data-testid="user-table"
          aria-label="User listing"
        >
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~s(data-testid="user-table")
      assert html =~ ~s(aria-label="User listing")
    end
  end

  describe "LiveStream support" do
    test "adds phx-update stream when rows is a LiveStream" do
      stream = %LiveStream{
        deletes: [],
        dom_id: fn {id, _} -> "users-#{id}" end,
        inserts: [],
        name: :users
      }

      assigns = %{users: stream}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col :let={{_id, user}} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~s(phx-update="stream")
      assert html =~ ~s(id="users-tbody")
    end

    test "handles LiveStream tuple data with automatic row_id" do
      stream = %LiveStream{
        deletes: [],
        dom_id: fn {id, _} -> "users-#{id}" end,
        inserts: [{1, %{id: 1, name: "Alice"}}],
        name: :users
      }

      assigns = %{users: stream}

      # Note: LiveStream rendering is handled by Phoenix LiveView
      # We're mainly testing that the component detects and sets up for streams
      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:col :let={{_id, user}} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~s(phx-update="stream")
    end
  end

  describe "table/1 accessible name (WCAG 2.4.6)" do
    test ":caption slot renders <caption> as the first child of <table>" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users}>
          <:caption>Active users this week</:caption>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~s(<caption)
      assert html =~ "Active users this week"
      assert html =~ ~r/<table[^>]*>\s*<caption/
    end

    test "aria_label attr renders aria-label on <table>" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} aria_label="Active users this week">
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~r/<table[^>]*aria-label="Active users this week"/
      refute html =~ ~s(<caption)
    end

    test "aria_labelledby attr renders aria-labelledby on <table>" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table id="users" rows={@users} aria_labelledby="users-heading">
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~r/<table[^>]*aria-labelledby="users-heading"/
    end

    test "emits Logger.warning when no accessible name is provided" do
      assigns = %{users: []}

      log =
        capture_log(fn ->
          rendered_to_string(~H"""
          <Table.table id="users" rows={@users}>
            <:col label="Name" />
          </Table.table>
          """)
        end)

      assert log =~ "rendered without an accessible name"
    end

    test "Logger.warning is suppressed when :caption slot is provided" do
      assigns = %{users: []}

      log =
        capture_log(fn ->
          rendered_to_string(~H"""
          <Table.table id="users" rows={@users}>
            <:caption>Users</:caption>
            <:col label="Name" />
          </Table.table>
          """)
        end)

      refute log =~ "rendered without an accessible name"
    end

    test "Logger.warning is suppressed when aria_label attr is provided" do
      assigns = %{users: []}

      log =
        capture_log(fn ->
          rendered_to_string(~H"""
          <Table.table id="users" rows={@users} aria_label="Users">
            <:col label="Name" />
          </Table.table>
          """)
        end)

      refute log =~ "rendered without an accessible name"
    end

    test "Logger.warning is suppressed when aria_labelledby attr is provided" do
      assigns = %{users: []}

      log =
        capture_log(fn ->
          rendered_to_string(~H"""
          <Table.table id="users" rows={@users} aria_labelledby="users-heading">
            <:col label="Name" />
          </Table.table>
          """)
        end)

      refute log =~ "rendered without an accessible name"
    end

    test "Logger.warning is suppressed when aria-label passes through global @rest" do
      assigns = %{users: []}

      log =
        capture_log(fn ->
          rendered_to_string(~H"""
          <Table.table id="users" rows={@users} aria-label="Users">
            <:col label="Name" />
          </Table.table>
          """)
        end)

      refute log =~ "rendered without an accessible name"
    end

    test "Logger.warning is NOT suppressed when aria_label is blank" do
      assigns = %{users: []}

      log =
        capture_log(fn ->
          rendered_to_string(~H"""
          <Table.table id="users" rows={@users} aria_label="   ">
            <:col label="Name" />
          </Table.table>
          """)
        end)

      assert log =~ "rendered without an accessible name"
    end

    test "Logger.warning is NOT suppressed when aria-label via @rest is blank" do
      assigns = %{users: []}

      log =
        capture_log(fn ->
          rendered_to_string(~H"""
          <Table.table id="users" rows={@users} aria-label="">
            <:col label="Name" />
          </Table.table>
          """)
        end)

      assert log =~ "rendered without an accessible name"
    end

    test "all three affordances can coexist without crashing" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.table
          id="users"
          rows={@users}
          aria_label="Hidden name"
          aria_labelledby="users-heading"
        >
          <:caption>Visible caption</:caption>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.table>
        """)

      assert html =~ ~s(<caption)
      assert html =~ "Visible caption"
      assert html =~ ~s(aria-label="Hidden name")
      assert html =~ ~s(aria-labelledby="users-heading")
    end
  end
end
