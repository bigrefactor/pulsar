defmodule Pulsar.DevApp.SkeletonLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Skeleton

  @circle_sizes ~w(xs sm md lg xl 2xl)

  def render(assigns) do
    assigns = assign(assigns, circle_sizes: @circle_sizes)

    ~H"""
    <.fixture_page name="skeleton" title="Skeleton">
      <.fixture_section name="kinds" title="Kinds">
        <Skeleton.skeleton kind="text" class="w-64" data-fixture-cell="kind-text" />
        <Skeleton.skeleton kind="circle" data-fixture-cell="kind-circle" />
        <Skeleton.skeleton kind="rect" class="h-24 w-64" data-fixture-cell="kind-rect" />
      </.fixture_section>

      <.fixture_section name="circle-sizes" title="Circle sizes">
        <Skeleton.skeleton
          :for={size <- @circle_sizes}
          kind="circle"
          size={size}
          data-fixture-cell={"circle-#{size}"}
        />
      </.fixture_section>

      <.fixture_section name="text-lines" title="Multi-line text">
        <Skeleton.skeleton kind="text" lines={3} class="w-64" data-fixture-cell="lines-3" />
      </.fixture_section>

      <.fixture_section name="animate-text" title="Streaming text">
        <Skeleton.skeleton animate_text data-fixture-cell="animate-text">
          AI is thinking harder…
        </Skeleton.skeleton>
      </.fixture_section>

      <.fixture_section name="labelled" title="Announced loading status">
        <Skeleton.skeleton
          kind="text"
          lines={2}
          class="w-64"
          label="Loading profile"
          data-fixture-cell="labelled"
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
