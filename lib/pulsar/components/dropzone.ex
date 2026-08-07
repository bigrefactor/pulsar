defmodule Pulsar.Components.Dropzone do
  @moduledoc """
  Dropzone component — drag-and-drop file upload area for LiveView uploads.

  Renders a clickable, keyboard-operable upload zone for a LiveView upload
  configured with `allow_upload/3`, including per-entry progress bars, image
  previews, and upload error messages. Dropping files and browsing via the file
  picker both go through the standard LiveView upload machinery.

  The dropzone must be rendered inside a form bound with `phx-change` (and
  `phx-submit` when consuming uploads on submit), the same requirement as
  `Phoenix.Component.live_file_input/1`.

  ## Examples

      # In the LiveView:
      #     allow_upload(:avatar, accept: ~w(.jpg .png), max_entries: 3)
      #
      # In the template:
      <form phx-change="validate" phx-submit="save">
        <.dropzone upload={@uploads.avatar} hint="JPG or PNG, up to 8 MB" />
      </form>

      # Custom copy (i18n) and a custom cancel event
      <.dropzone
        upload={@uploads.documents}
        prompt={gettext("Click to upload or drag and drop")}
        on_cancel={fn entry -> JS.push("remove-file", value: %{ref: entry.ref}) end}
      />

  ## Cancelling entries

  Each entry renders a cancel button. By default it pushes a `"cancel-upload"`
  event carrying the entry ref:

      def handle_event("cancel-upload", %{"ref" => ref}, socket) do
        {:noreply, cancel_upload(socket, :avatar, ref)}
      end

  Pass `on_cancel` to override — either a `%JS{}` applied to every entry or a
  1-arity function receiving the entry and returning a `%JS{}`.
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Phoenix.LiveView.UploadConfig
  alias Pulsar.Components.Icon
  alias Pulsar.Components.Progress

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Zone padding, prompt icon size, and preview thumbnail size per size.
  @size_config %{
    "lg" => %{icon: "lg", preview: "h-12 w-12", zone: "p-10 gap-2.5"},
    "md" => %{icon: "md", preview: "h-10 w-10", zone: "p-8 gap-2"},
    "sm" => %{icon: "md", preview: "h-9 w-9", zone: "p-6 gap-2"},
    "xl" => %{icon: "xl", preview: "h-14 w-14", zone: "p-12 gap-3"},
    "xs" => %{icon: "sm", preview: "h-8 w-8", zone: "p-4 gap-1.5"}
  }

  @zone_base_classes "flex w-full cursor-pointer flex-col items-center justify-center " <>
                       "border-2 border-dashed text-center " <>
                       "transition-colors duration-fast ease-standard " <>
                       "focus-within:ring-2 focus-within:ring-primary focus-within:ring-offset-2"

  @valid_variants ~w(solid outline ghost elevated)
  @valid_colors ~w(neutral primary secondary success danger warning info)

  # Zone surface per variant and color (border style stays dashed from base).
  @color_config %{
    "elevated" => %{
      "danger" => "bg-surface-1 border-transparent shadow-dropdown rounded-box",
      "info" => "bg-surface-1 border-transparent shadow-dropdown rounded-box",
      "neutral" => "bg-surface-1 border-transparent shadow-dropdown rounded-box",
      "primary" => "bg-surface-1 border-transparent shadow-dropdown rounded-box",
      "secondary" => "bg-surface-1 border-transparent shadow-dropdown rounded-box",
      "success" => "bg-surface-1 border-transparent shadow-dropdown rounded-box",
      "warning" => "bg-surface-1 border-transparent shadow-dropdown rounded-box"
    },
    "ghost" => %{
      "danger" => "bg-transparent border-transparent rounded-box",
      "info" => "bg-transparent border-transparent rounded-box",
      "neutral" => "bg-transparent border-transparent rounded-box",
      "primary" => "bg-transparent border-transparent rounded-box",
      "secondary" => "bg-transparent border-transparent rounded-box",
      "success" => "bg-transparent border-transparent rounded-box",
      "warning" => "bg-transparent border-transparent rounded-box"
    },
    "outline" => %{
      "danger" => "bg-surface-1 border-danger rounded-box",
      "info" => "bg-surface-1 border-info rounded-box",
      "neutral" => "bg-surface-1 border-border-strong rounded-box",
      "primary" => "bg-surface-1 border-primary rounded-box",
      "secondary" => "bg-surface-1 border-secondary rounded-box",
      "success" => "bg-surface-1 border-success rounded-box",
      "warning" => "bg-surface-1 border-warning rounded-box"
    },
    "solid" => %{
      "danger" => "bg-danger/10 border-danger/20 rounded-box",
      "info" => "bg-info/10 border-info/20 rounded-box",
      "neutral" => "bg-surface-1 border-border-strong rounded-box",
      "primary" => "bg-primary/10 border-primary/20 rounded-box",
      "secondary" => "bg-secondary/10 border-secondary/20 rounded-box",
      "success" => "bg-success/10 border-success/20 rounded-box",
      "warning" => "bg-warning/10 border-warning/20 rounded-box"
    }
  }

  # Drag-over emphasis per color. LiveView (1.2+) toggles the
  # phx-drop-target-active class on the phx-drop-target element while files
  # are dragged over it.
  @dragover_config %{
    "danger" =>
      "group-[.phx-drop-target-active]/dropzone:border-danger group-[.phx-drop-target-active]/dropzone:bg-danger/5",
    "info" => "group-[.phx-drop-target-active]/dropzone:border-info group-[.phx-drop-target-active]/dropzone:bg-info/5",
    "neutral" =>
      "group-[.phx-drop-target-active]/dropzone:border-border-strong group-[.phx-drop-target-active]/dropzone:bg-surface-2",
    "primary" =>
      "group-[.phx-drop-target-active]/dropzone:border-primary group-[.phx-drop-target-active]/dropzone:bg-primary/5",
    "secondary" =>
      "group-[.phx-drop-target-active]/dropzone:border-secondary group-[.phx-drop-target-active]/dropzone:bg-secondary/5",
    "success" =>
      "group-[.phx-drop-target-active]/dropzone:border-success group-[.phx-drop-target-active]/dropzone:bg-success/5",
    "warning" =>
      "group-[.phx-drop-target-active]/dropzone:border-warning group-[.phx-drop-target-active]/dropzone:bg-warning/5"
  }

  for variant <- @valid_variants,
      color <- @valid_colors do
    if !get_in(@color_config, [variant, color]) do
      raise CompileError,
        description: "Missing color config for variant=#{variant}, color=#{color}"
    end
  end

  # ============================================================================
  # DROPZONE COMPONENT
  # ============================================================================

  attr(:upload, UploadConfig,
    required: true,
    doc: "The upload config from `@uploads.<name>` (configured with `allow_upload/3`)"
  )

  attr(:id, :string, doc: "DOM id (defaults to \"dropzone-<upload name>\")")

  attr(:on_cancel, :any,
    default: nil,
    doc: """
    Cancel callback: a `%JS{}` applied to every entry, or a 1-arity function
    `(entry) -> %JS{}`. Defaults to pushing `"cancel-upload"` with the entry ref.
    """
  )

  attr(:variant, :string,
    default: "outline",
    values: ~w(solid outline ghost elevated),
    doc: "Visual style variant of the zone"
  )

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the zone"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the zone (padding, icon, and preview sizing)"
  )

  attr(:prompt, :string,
    default: "Click to upload or drag and drop",
    doc: ~s{Zone prompt text. Use with i18n: gettext("Click to upload or drag and drop")}
  )

  attr(:drop_prompt, :string,
    default: "Drop files here",
    doc: ~s{Prompt shown while dragging files over the zone. Use with i18n: gettext("Drop files here")}
  )

  attr(:hint, :string,
    default: nil,
    doc: "Optional helper text under the prompt, e.g. \"PNG or JPG, up to 8 MB\""
  )

  attr(:cancel_label, :string,
    default: "Cancel upload",
    doc: ~s{Accessible-name base for entry cancel buttons. Use with i18n: gettext("Cancel upload")}
  )

  attr(:format_size, :any,
    default: nil,
    doc: "1-arity function formatting an entry's byte count for display (default: built-in B/KB/MB formatter)"
  )

  attr(:too_large_message, :string,
    default: "File is too large",
    doc: ~s{Message for the :too_large upload error. Use with i18n: gettext("File is too large")}
  )

  attr(:not_accepted_message, :string,
    default: "File type not accepted",
    doc: ~s{Message for the :not_accepted upload error. Use with i18n: gettext("File type not accepted")}
  )

  attr(:too_many_files_message, :string,
    default: "Too many files",
    doc: ~s{Message for the :too_many_files upload error. Use with i18n: gettext("Too many files")}
  )

  attr(:external_client_failure_message, :string,
    default: "Upload failed",
    doc: ~s{Message for the :external_client_failure upload error. Use with i18n: gettext("Upload failed")}
  )

  attr(:class, :string, default: "", doc: "Additional CSS classes for the root element")

  attr(:rest, :global, doc: "Additional HTML attributes including phx-* event handlers")

  @doc """
  Renders a file-upload dropzone for a LiveView upload.
  """
  @spec dropzone(map()) :: Rendered.t()
  def dropzone(assigns) do
    assigns = assign_new(assigns, :id, fn -> "dropzone-" <> to_string(assigns.upload.name) end)

    prepared =
      Enum.map(assigns.upload.entries, fn entry ->
        %{
          entry: entry,
          errors: upload_errors(assigns.upload, entry),
          image?: String.starts_with?(entry.client_type || "", "image/")
        }
      end)

    entry_errors =
      for item <- prepared, error <- item.errors, do: {item.entry, error}

    assigns =
      assigns
      |> assign(:prepared, prepared)
      |> assign(:entry_errors, entry_errors)
      |> assign(:config_errors, upload_errors(assigns.upload))
      |> assign(:zone_class, zone_classes(assigns.variant, assigns.color, assigns.size))
      |> assign(:preview_class, @size_config[assigns.size].preview)
      |> assign(:icon_size, @size_config[assigns.size].icon)

    ~H"""
    <div
      id={@id}
      phx-drop-target={@upload.ref}
      class={merge(["group/dropzone", @class])}
      {@rest}
    >
      <label for={@upload.ref} class={@zone_class}>
        <Icon.icon name="hero-arrow-up-tray" size={@icon_size} color="neutral" />
        <span class="text-sm font-medium text-foreground group-[.phx-drop-target-active]/dropzone:hidden">
          {@prompt}
        </span>
        <span
          id={@id <> "-drop-prompt"}
          class="hidden text-sm font-medium text-foreground group-[.phx-drop-target-active]/dropzone:inline"
        >
          {@drop_prompt}
        </span>
        <span :if={@hint} id={@id <> "-hint"} class="text-xs text-muted-foreground">{@hint}</span>
        <.live_file_input
          upload={@upload}
          class="sr-only"
          aria-describedby={@hint && @id <> "-hint"}
        />
      </label>
      <div aria-live="polite">
        <p :for={error <- @config_errors} class="mt-2 text-sm text-danger">
          {error_message(error, assigns)}
        </p>
      </div>
      <div aria-live="polite" class="sr-only">
        <p :for={{entry, error} <- @entry_errors}>
          {entry.client_name}: {error_message(error, assigns)}
        </p>
      </div>
      <ul :if={@prepared != []} class="mt-3 flex flex-col gap-2">
        <li :for={item <- @prepared} class={entry_classes(item.errors)}>
          <.live_img_preview
            :if={item.image?}
            entry={item.entry}
            alt=""
            class={merge([@preview_class, "shrink-0 rounded-field object-cover"])}
          />
          <span
            :if={!item.image?}
            class={merge([@preview_class, "flex shrink-0 items-center justify-center rounded-field bg-surface-2"])}
          >
            <Icon.icon name="hero-document" size="sm" color="neutral" />
          </span>
          <div class="min-w-0 flex-1">
            <p class="truncate text-sm text-foreground">
              {item.entry.client_name}
              <span class="text-muted-foreground">
                · {format_bytes(@format_size, item.entry.client_size)}
              </span>
            </p>
            <div>
              <p :for={error <- item.errors} class="mt-0.5 text-sm text-danger">
                {error_message(error, assigns)}
              </p>
            </div>
            <Progress.progress
              :if={item.errors == []}
              value={item.entry.progress}
              size="xs"
              color={@color}
              class="mt-1.5"
              aria-label={item.entry.client_name}
            />
          </div>
          <button
            type="button"
            class="shrink-0 rounded-field p-1 text-muted-foreground transition-colors duration-fast hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            aria-label={@cancel_label <> ": " <> item.entry.client_name}
            phx-click={cancel_callback(@on_cancel, item.entry)}
          >
            <Icon.icon name="hero-x-mark" size="sm" />
          </button>
        </li>
      </ul>
    </div>
    """
  end

  # ============================================================================
  # HELPERS
  # ============================================================================

  defp zone_classes(variant, color, size) do
    merge([
      @zone_base_classes,
      @color_config[variant][color] || "",
      @dragover_config[color] || "",
      @size_config[size].zone
    ])
  end

  defp entry_classes([]) do
    "flex items-center gap-3 rounded-field border border-border bg-surface-1 p-3"
  end

  defp entry_classes(_errors) do
    "flex items-center gap-3 rounded-field border border-danger bg-surface-1 p-3"
  end

  defp cancel_callback(nil, entry), do: JS.push("cancel-upload", value: %{ref: entry.ref})
  defp cancel_callback(%JS{} = js, _entry), do: js
  defp cancel_callback(fun, entry) when is_function(fun, 1), do: fun.(entry)

  defp error_message(:too_large, assigns), do: assigns.too_large_message
  defp error_message(:not_accepted, assigns), do: assigns.not_accepted_message
  defp error_message(:too_many_files, assigns), do: assigns.too_many_files_message
  defp error_message(_other, assigns), do: assigns.external_client_failure_message

  defp format_bytes(fun, bytes) when is_function(fun, 1), do: fun.(bytes)
  defp format_bytes(nil, nil), do: ""

  defp format_bytes(nil, bytes) when bytes >= 1_048_576, do: "#{Float.round(bytes / 1_048_576, 1)} MB"

  defp format_bytes(nil, bytes) when bytes >= 1024, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_bytes(nil, bytes), do: "#{bytes} B"
end
