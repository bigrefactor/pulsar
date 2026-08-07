defmodule Pulsar.Components.DropzoneTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.UploadConfig
  alias Phoenix.LiveView.UploadEntry
  alias Pulsar.Components.Dropzone

  defp upload_config(attrs \\ []) do
    defaults = [
      name: :files,
      ref: "phx-upload",
      entries: [],
      errors: [],
      max_entries: 3,
      max_file_size: 8_000_000,
      accept: ".jpg,.png"
    ]

    struct(UploadConfig, Keyword.merge(defaults, attrs))
  end

  defp entry(attrs \\ []) do
    defaults = [
      ref: "0",
      upload_ref: "phx-upload",
      upload_config: :files,
      client_name: "photo.jpg",
      client_size: 1_048_576,
      client_type: "image/jpeg",
      progress: 40,
      valid?: true,
      done?: false,
      cancelled?: false
    ]

    struct(UploadEntry, Keyword.merge(defaults, attrs))
  end

  describe "dropzone/1 basic functionality" do
    test "renders zone with file input, drop target, and hook" do
      assigns = %{upload: upload_config()}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} />])

      assert html =~ ~s(type="file")
      assert html =~ ~s(phx-drop-target="phx-upload")
      assert html =~ "phx-hook"
      assert html =~ ~s(id="dropzone-files")
      assert html =~ "Click to upload or drag and drop"
      assert html =~ "Drop files here"
    end

    test "label points at the file input's id" do
      assigns = %{upload: upload_config()}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} />])

      # live_file_input renders id={@upload.ref}; the zone <label for> must match
      assert html =~ ~s(for="phx-upload")
      assert html =~ ~s(id="phx-upload")
    end

    test "explicit id wins over the derived one" do
      assigns = %{upload: upload_config()}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} id="custom" />])
      assert html =~ ~s(id="custom")
    end

    test "hint renders and is wired via aria-describedby" do
      assigns = %{upload: upload_config()}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} hint="PNG up to 8 MB" />])

      assert html =~ "PNG up to 8 MB"
      assert html =~ ~s(id="dropzone-files-hint")
      assert html =~ ~s(aria-describedby="dropzone-files-hint")
    end

    test "no hint means no aria-describedby" do
      assigns = %{upload: upload_config()}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} />])
      refute html =~ "aria-describedby"
    end
  end

  describe "entries" do
    test "renders name, formatted size, progress, and cancel button" do
      assigns = %{upload: upload_config(entries: [entry()])}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} />])

      assert html =~ "photo.jpg"
      assert html =~ "1.0 MB"
      assert html =~ ~s(role="progressbar")
      assert html =~ ~s(aria-valuenow="40")
      assert html =~ ~s(aria-label="Cancel upload: photo.jpg")
    end

    test "image entries render live_img_preview" do
      assigns = %{upload: upload_config(entries: [entry()])}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} />])
      assert html =~ "data-phx-entry-ref"
    end

    test "non-image entries render the document icon instead of a preview" do
      e = entry(client_name: "report.pdf", client_type: "application/pdf")
      assigns = %{upload: upload_config(entries: [e])}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} />])

      assert html =~ "hero-document"
      refute html =~ "data-phx-entry-ref"
    end

    test "no entries renders no list" do
      assigns = %{upload: upload_config()}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} />])
      refute html =~ "<li"
    end

    test "format_size attr overrides the byte formatter" do
      assigns = %{upload: upload_config(entries: [entry()]), fmt: fn _bytes -> "ONE MB" end}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} format_size={@fmt} />])
      assert html =~ "ONE MB"
    end
  end

  describe "errors" do
    test "config-level :too_many_files renders under the zone" do
      cfg = upload_config(errors: [{"phx-upload", :too_many_files}])
      assigns = %{upload: cfg}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} />])

      assert html =~ "Too many files"
      assert html =~ ~s(aria-live="polite")
    end

    test "per-entry :too_large replaces the progress bar" do
      cfg = upload_config(entries: [entry()], errors: [{"0", :too_large}])
      assigns = %{upload: cfg}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} />])

      assert html =~ "File is too large"
      refute html =~ ~s(role="progressbar")
    end

    test "per-entry :not_accepted renders its message" do
      cfg = upload_config(entries: [entry()], errors: [{"0", :not_accepted}])
      assigns = %{upload: cfg}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} />])
      assert html =~ "File type not accepted"
    end

    test "unknown error atoms fall back to the external failure message" do
      cfg = upload_config(entries: [entry()], errors: [{"0", :some_future_error}])
      assigns = %{upload: cfg}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} />])
      assert html =~ "Upload failed"
    end

    test "error messages are overridable" do
      cfg = upload_config(errors: [{"phx-upload", :too_many_files}])
      assigns = %{upload: cfg}

      html =
        rendered_to_string(~H[<Dropzone.dropzone upload={@upload} too_many_files_message="Zu viele Dateien" />])

      assert html =~ "Zu viele Dateien"
    end
  end

  describe "cancel callback" do
    test "default pushes cancel-upload with the entry ref" do
      assigns = %{upload: upload_config(entries: [entry()])}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} />])

      assert html =~ "cancel-upload"
      assert html =~ ~s("ref":"0")
    end

    test "a plain %JS{} applies to every entry" do
      assigns = %{upload: upload_config(entries: [entry()]), js: JS.push("custom-cancel")}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} on_cancel={@js} />])

      assert html =~ "custom-cancel"
      refute html =~ "cancel-upload"
    end

    test "a 1-arity function receives the entry" do
      assigns = %{
        upload: upload_config(entries: [entry()]),
        fun: fn e -> JS.push("drop-entry", value: %{ref: e.ref}) end
      }

      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} on_cancel={@fun} />])
      assert html =~ "drop-entry"
      assert html =~ ~s("ref":"0")
    end
  end

  describe "variants, colors, sizes" do
    test "renders every variant" do
      for variant <- ~w(solid outline ghost elevated) do
        assigns = %{upload: upload_config(), variant: variant}
        html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} variant={@variant} />])
        assert html =~ ~s(type="file")
      end
    end

    test "renders every color" do
      for color <- ~w(neutral primary secondary success danger warning info) do
        assigns = %{upload: upload_config(), color: color}
        html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} color={@color} />])
        assert html =~ ~s(type="file")
      end
    end

    test "outline primary carries the primary border" do
      assigns = %{upload: upload_config()}

      html =
        rendered_to_string(~H[<Dropzone.dropzone upload={@upload} variant="outline" color="primary" />])

      assert html =~ "border-primary"
      assert html =~ "border-dashed"
    end

    test "renders every size" do
      for size <- ~w(xs sm md lg xl) do
        assigns = %{upload: upload_config(), size: size}
        html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} size={@size} />])
        assert html =~ ~s(type="file")
      end
    end
  end

  describe "customization (Twm merge) and strings" do
    test "user class overrides defaults" do
      assigns = %{upload: upload_config()}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} class="rounded-none" />])
      assert html =~ "rounded-none"
    end

    test "prompt and drop_prompt are overridable" do
      assigns = %{upload: upload_config()}

      html =
        rendered_to_string(~H[<Dropzone.dropzone upload={@upload} prompt="Dateien wählen" drop_prompt="Loslassen" />])

      assert html =~ "Dateien wählen"
      assert html =~ "Loslassen"
    end

    test "global attributes pass through" do
      assigns = %{upload: upload_config()}
      html = rendered_to_string(~H[<Dropzone.dropzone upload={@upload} data-testid="dz" />])
      assert html =~ ~s(data-testid="dz")
    end
  end
end
