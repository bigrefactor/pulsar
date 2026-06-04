defmodule Pulsar.DevApp.AlertDialogLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.AlertDialog

  @variants ~w(solid outline ghost elevated)
  @colors ~w(neutral primary secondary success danger warning info)
  @sizes ~w(sm md lg xl)

  def render(assigns) do
    assigns =
      assign(assigns,
        variants: @variants,
        colors: @colors,
        sizes: @sizes
      )

    # These cells are a static showcase (rendered with `open`, in flow), not live
    # openings, so `style="animation: none"` suppresses the `animate-scale-in`
    # entrance. Without it the axe gate scans mid-fade and composites the opaque
    # button fills against the page, producing false sub-4.5:1 contrast readings;
    # the settled colors pass AA (see button.md / modal.md measured audits).
    ~H"""
    <.fixture_page name="alert_dialog" title="AlertDialog">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <AlertDialog.alert_dialog
          :for={color <- @colors}
          id={"alert-#{variant}-#{color}"}
          variant={variant}
          color={color}
          title={"#{variant} #{color}"}
          open
          style="animation: none"
          class="static m-0 w-72"
          data-fixture-cell={"#{variant}-#{color}"}
        >
          This action can't be undone.
        </AlertDialog.alert_dialog>
      </.fixture_section>

      <.fixture_section name="sizes" title="sizes">
        <AlertDialog.alert_dialog
          :for={size <- @sizes}
          id={"alert-size-#{size}"}
          size={size}
          title={"size #{size}"}
          open
          style="animation: none"
          class="static m-0"
          data-fixture-cell={"size-#{size}"}
        >
          This action can't be undone.
        </AlertDialog.alert_dialog>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
