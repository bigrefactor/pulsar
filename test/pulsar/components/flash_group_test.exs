defmodule Pulsar.Components.FlashGroupTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.FlashGroup

  describe "flash_group/1 stagger delay functionality" do
    test "applies transition-delay for stagger animation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group
          flash={%{info: "Message 1", success: "Message 2"}}
          stagger_delay={100}
        />
        """)

      # Should use transition-delay, not animation-delay
      assert html =~ "transition-delay: 0ms"
      assert html =~ "transition-delay: 100ms"
      refute html =~ "animation-delay"
    end

    test "applies pointer-events for click-through behavior" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Test message"}} />
        """)

      # Container should have pointer-events-none for click-through
      assert html =~ "pointer-events-none"
      # Individual flashes should have pointer-events-auto to remain interactive
      assert html =~ "pointer-events-auto"
    end
  end

  describe "flash_group/1 basic functionality" do
    test "renders empty when no flash messages" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{}} />
        """)

      # Should not render anything when no messages
      assert String.trim(html) == ""
    end

    test "renders container with flash messages" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Test message"}} />
        """)

      assert html =~ ~s(<div)
      assert html =~ "Test message"
      # Default position (top-right)
      assert html =~ "top-4"
      assert html =~ "right-4"
      # Should render Flash component with unique ID format: flash-{component_id}-{type}
      assert html =~ ~r/id="flash-\d+-info"/
    end

    test "renders multiple flash messages" do
      assigns = %{}

      flash = %{
        error: "Error message",
        info: "Info message",
        success: "Success message"
      }

      assigns = Map.put(assigns, :flash, flash)

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={@flash} />
        """)

      assert html =~ "Info message"
      assert html =~ "Error message"
      assert html =~ "Success message"

      # Debug: print the HTML to understand the output
      # Should have multiple flash components
      matches = Regex.scan(~r/id=\"flash-[^\"]+\"/, html)
      flash_count = length(matches)
      assert flash_count == 3
    end

    test "applies variant to all flashes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group
          flash={%{info: "Message", error: "Error"}}
          variant="outline"
        />
        """)

      # Both flashes should use outline variant
      assert html =~ "border-info"
      assert html =~ "border-danger"
    end

    test "applies size to all flashes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group
          flash={%{info: "Message"}}
          size="lg"
        />
        """)

      # Should use large size classes
      assert html =~ "p-4"
      assert html =~ "text-base"
    end
  end

  describe "flash_group/1 type-to-color mapping" do
    test "maps error type to danger color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{error: "Error message"}} />
        """)

      assert html =~ "bg-danger"
      assert html =~ "Error message"
    end

    test "maps warning type to warning color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{warning: "Warning message"}} />
        """)

      assert html =~ "bg-warning"
      assert html =~ "Warning message"
    end

    test "maps info type to info color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Info message"}} />
        """)

      assert html =~ "bg-info"
      assert html =~ "Info message"
    end

    test "maps success type to success color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{success: "Success message"}} />
        """)

      assert html =~ "bg-success"
      assert html =~ "Success message"
    end

    test "maps custom types to neutral color" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{custom: "Custom message"}} />
        """)

      assert html =~ "bg-neutral"
      assert html =~ "Custom message"
    end

    test "maps multiple types correctly" do
      assigns = %{}

      flash = %{
        custom: "Custom",
        error: "Error",
        info: "Info",
        success: "Success",
        warning: "Warning"
      }

      assigns = Map.put(assigns, :flash, flash)

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={@flash} />
        """)

      # error -> danger
      assert html =~ "bg-danger"
      # warning -> warning
      assert html =~ "bg-warning"
      # info -> info
      assert html =~ "bg-info"
      # success -> success
      assert html =~ "bg-success"
      # custom -> neutral
      assert html =~ "bg-neutral"
    end
  end

  describe "flash_group/1 ARIA role mapping" do
    test "maps error and warning to alert role" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{error: "Error", warning: "Warning"}} />
        """)

      # Should have alert roles
      alert_count = html |> String.split(~s(role="alert")) |> length() |> Kernel.-(1)
      assert alert_count == 2
    end

    test "maps other types to status role" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Info", success: "Success"}} />
        """)

      # Should have status roles and polite live region behavior
      status_count = html |> String.split(~s(role="status")) |> length() |> Kernel.-(1)
      assert status_count == 2
      assert html =~ ~s(aria-live="polite")
    end
  end

  describe "flash_group/1 positioning" do
    test "renders with default top-right position" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Message"}} />
        """)

      assert html =~ "top-4"
      assert html =~ "right-4"
      assert html =~ "items-end"
      assert html =~ "flex-col"
    end

    test "renders with top-center position" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Message"}} position="top-center" />
        """)

      assert html =~ "top-4"
      assert html =~ "left-1/2"
      assert html =~ "-translate-x-1/2"
      assert html =~ "items-center"
    end

    test "renders with bottom-right position" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Message"}} position="bottom-right" />
        """)

      assert html =~ "bottom-4"
      assert html =~ "right-4"
      assert html =~ "flex-col-reverse"
      assert html =~ "items-end"
    end

    test "renders with bottom-center position" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Message"}} position="bottom-center" />
        """)

      assert html =~ "bottom-4"
      assert html =~ "left-1/2"
      assert html =~ "-translate-x-1/2"
      assert html =~ "flex-col-reverse"
      assert html =~ "items-center"
    end

    test "renders with left positions" do
      assigns = %{}

      html_top_left =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Message"}} position="top-left" />
        """)

      assert html_top_left =~ "top-4"
      assert html_top_left =~ "left-4"
      assert html_top_left =~ "items-start"

      html_bottom_left =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Message"}} position="bottom-left" />
        """)

      assert html_bottom_left =~ "bottom-4"
      assert html_bottom_left =~ "left-4"
      assert html_bottom_left =~ "flex-col-reverse"
      assert html_bottom_left =~ "items-start"
    end

    test "includes animation transitions based on position" do
      assigns = %{}

      # Top positions should slide from top
      html_top =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Message"}} position="top-center" />
        """)

      assert html_top =~ "phx-mounted="
      assert html_top =~ "ease-decelerate"
      refute html_top =~ "ease-standard duration-normal"
      assert html_top =~ "-translate-y-full"
      assert html_top =~ "translate-y-0"

      # Bottom positions should slide from bottom
      html_bottom =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Message"}} position="bottom-center" />
        """)

      assert html_bottom =~ "translate-y-full"
      assert html_bottom =~ "translate-y-0"
    end
  end

  describe "flash_group/1 max_items limiting" do
    test "respects max_items limit" do
      assigns = %{}

      flash = %{
        error: "Error message",
        warning: "Warning message",
        info: "Info message",
        success: "Success message",
        custom1: "Custom message 1",
        # Should be excluded with max_items=3
        custom2: "Custom message 2"
      }

      assigns = Map.put(assigns, :flash, flash)

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={@flash} max_items={3} />
        """)

      # Should only have 3 flash components
      flash_count = Regex.scan(~r/id=\"flash-[^\"]+\"/, html) |> length()
      assert flash_count == 3

      # Should contain first 3 messages by priority (error, warning, info)
      assert html =~ "Error message"
      assert html =~ "Warning message"
      assert html =~ "Info message"
    end

    test "handles empty and nil messages" do
      assigns = %{}

      flash = %{
        error: "Error message",
        # Empty string should be filtered
        info: "",
        # Nil should be filtered
        warning: nil,
        success: "Success message"
      }

      assigns = Map.put(assigns, :flash, flash)

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={@flash} />
        """)

      # Should only render non-empty messages
      flash_count = Regex.scan(~r/id=\"flash-[^\"]+\"/, html) |> length()
      assert flash_count == 2

      assert html =~ "Error message"
      assert html =~ "Success message"
      refute html =~ ~r/id="flash-\d+-info"/
      refute html =~ ~r/id="flash-\d+-warning"/
    end
  end

  describe "flash_group/1 event handling" do
    test "defaults to pushing clear_flash with the dismissed key" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{error: "Error"}} />
        """)

      # Default dismiss callback: JS.push("clear_flash", value: %{key: "error"})
      assert html =~ ~s(data-on-dismiss=)
      assert html =~ "clear_flash"
      assert html =~ ~s(&quot;key&quot;:&quot;error&quot;)
    end

    test "supports a custom on_dismiss function per flash key" do
      assigns = %{
        on_dismiss: fn key -> JS.push("custom_clear", value: %{key: key}) end
      }

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{error: "Error"}} on_dismiss={@on_dismiss} />
        """)

      assert html =~ "custom_clear"
      assert html =~ ~s(&quot;key&quot;:&quot;error&quot;)
    end

    test "supports a bare %JS{} on_dismiss applied to every flash" do
      assigns = %{on_dismiss: JS.push("custom_clear")}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{error: "Error"}} on_dismiss={@on_dismiss} />
        """)

      assert html =~ ~s(data-on-dismiss=)
      assert html =~ "custom_clear"
    end

    test "renders dismiss button with accessible label by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Info message"}} />
        """)

      assert html =~ ~s(<button)
      assert html =~ ~s(type="button")
      assert html =~ ~s(aria-label="Dismiss")
    end
  end

  describe "flash_group/1 configuration options" do
    test "applies auto_dismiss setting to all flashes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group
          flash={%{info: "Message"}}
          auto_dismiss={false}
        />
        """)

      assert html =~ ~s(data-auto-dismiss="false")
    end

    test "without explicit auto_dismiss, alert-role flashes do not auto-dismiss (WCAG 2.2.1)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{error: "Boom"}} />
        """)

      assert html =~ ~s(role="alert")
      assert html =~ ~s(data-auto-dismiss="false")
    end

    test "without explicit auto_dismiss, status-role flashes auto-dismiss by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Hi"}} />
        """)

      assert html =~ ~s(role="status")
      assert html =~ ~s(data-auto-dismiss="true")
    end

    test "explicit auto_dismiss=true overrides role-aware default for alerts" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{error: "Boom"}} auto_dismiss={true} />
        """)

      assert html =~ ~s(role="alert")
      assert html =~ ~s(data-auto-dismiss="true")
    end

    test "applies custom dismiss_after to all flashes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group
          flash={%{info: "Message"}}
          dismiss_after={10000}
        />
        """)

      assert html =~ ~s(data-dismiss-after="10000")
    end

    test "applies dismissible setting to all flashes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group
          flash={%{info: "Message"}}
          dismissible={false}
        />
        """)

      # Should not have dismiss button
      refute html =~ ~s(<button)
      refute html =~ ~s(aria-label="Dismiss")
    end
  end

  describe "flash_group/1 custom attributes" do
    test "passes through custom HTML attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group
          flash={%{info: "Message"}}
          class="custom-container"
          data-testid="flash-group"
        />
        """)

      assert html =~ "custom-container"
      assert html =~ ~s(data-testid="flash-group")
    end

    test "merges custom classes with position classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group
          flash={%{info: "Message"}}
          class="custom-spacing"
        />
        """)

      # Should have both custom and position classes
      assert html =~ "custom-spacing"
      # Default position
      assert html =~ "top-4"
      assert html =~ "right-4"
    end
  end

  describe "flash_group/1 ID collision prevention" do
    test "generates different component IDs for multiple flash groups" do
      assigns = %{}

      # Render two flash groups
      html1 =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Message 1"}} />
        """)

      html2 =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={%{info: "Message 2"}} />
        """)

      # Extract the component IDs from both rendered HTML
      [_, id1] = Regex.run(~r/id="flash-(\d+)-info"/, html1)
      [_, id2] = Regex.run(~r/id="flash-(\d+)-info"/, html2)

      # Component IDs should be different
      assert id1 != id2
    end
  end

  describe "flash_group/1 flash message ordering" do
    test "renders flash messages in priority order" do
      assigns = %{}

      # Mix flash types to test ordering
      flash = %{
        custom: "Custom message",
        error: "Error message",
        info: "Info message",
        success: "Success message",
        warning: "Warning message"
      }

      assigns = Map.put(assigns, :flash, flash)

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={@flash} />
        """)

      # Extract flash elements in order they appear in HTML
      flash_elements = Regex.scan(~r/id="flash-\d+-(\w+)"/, html, capture: :all_but_first)
      flash_types = Enum.map(flash_elements, fn [type] -> type end)

      # Should be in priority order: error, warning, info, success, custom
      assert flash_types == ["error", "warning", "info", "success", "custom"]
    end

    test "maintains consistent ordering across multiple renders" do
      assigns = %{}

      flash = %{
        error: "Error",
        success: "Success",
        warning: "Warning"
      }

      assigns = Map.put(assigns, :flash, flash)

      # Render multiple times to ensure consistent ordering
      html1 =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={@flash} />
        """)

      html2 =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={@flash} />
        """)

      html3 =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={@flash} />
        """)

      # Extract types from each render (ignoring the unique component IDs)
      extract_types = fn html ->
        Regex.scan(~r/id="flash-\d+-(\w+)"/, html, capture: :all_but_first)
        |> Enum.map(fn [type] -> type end)
      end

      types1 = extract_types.(html1)
      types2 = extract_types.(html2)
      types3 = extract_types.(html3)

      # All renders should have the same order
      assert types1 == types2
      assert types2 == types3
      # Should be in priority order
      assert types1 == ["error", "warning", "success"]
    end
  end

  describe "flash_group/1 edge cases" do
    test "handles non-map flash gracefully" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={nil} />
        """)

      # Should render nothing
      refute html =~ ~s(<div)
    end

    test "handles flash with atom values" do
      assigns = %{}

      # Phoenix.Flash can store any term, not just strings
      flash = %{info: :some_atom}

      assigns = Map.put(assigns, :flash, flash)

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={@flash} />
        """)

      assert html =~ "some_atom"
    end

    test "generates unique flash IDs" do
      assigns = %{}

      flash = %{error: "Error", info: "Info"}

      assigns = Map.put(assigns, :flash, flash)

      html =
        rendered_to_string(~H"""
        <FlashGroup.flash_group flash={@flash} />
        """)

      # Should have unique IDs for each flash with component ID
      assert html =~ ~r/id="flash-\d+-error"/
      assert html =~ ~r/id="flash-\d+-info"/
    end

    test "falls back to default position for invalid position" do
      assigns = %{}

      # This test assumes the component handles invalid positions gracefully
      # The actual behavior depends on the implementation
      log =
        capture_log(fn ->
          html =
            rendered_to_string(~H"""
            <FlashGroup.flash_group flash={%{info: "Message"}} position="invalid" />
            """)

          # Should fall back to top-right (default)
          assert html =~ "top-4"
          assert html =~ "right-4"
        end)

      # Should log a warning about invalid position
      assert log =~ "Invalid flash group position 'invalid', falling back to 'top-right'"
    end
  end
end
