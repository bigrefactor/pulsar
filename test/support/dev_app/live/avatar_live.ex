defmodule Pulsar.DevApp.AvatarLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Avatar

  @variants ~w(solid outline)
  @sizes ~w(xs sm md lg xl 2xl)
  @sample_image "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='80' height='80'><rect width='80' height='80' fill='%234f46e5'/><text x='50%' y='54%' font-family='system-ui, -apple-system, sans-serif' font-size='32' fill='white' text-anchor='middle' dominant-baseline='middle'>JD</text></svg>"

  def render(assigns) do
    assigns =
      assign(assigns, variants: @variants, sizes: @sizes, sample_image: @sample_image)

    ~H"""
    <.fixture_page name="avatar" title="Avatar">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <Avatar.avatar
          :for={size <- @sizes}
          name="Jane Doe"
          variant={variant}
          size={size}
          data-fixture-cell={"#{variant}-initials-#{size}"}
        />
        <Avatar.avatar
          :for={size <- @sizes}
          src={@sample_image}
          name="Jane Doe"
          variant={variant}
          size={size}
          data-fixture-cell={"#{variant}-image-#{size}"}
        />
        <Avatar.avatar
          :for={size <- @sizes}
          variant={variant}
          size={size}
          data-fixture-cell={"#{variant}-icon-#{size}"}
        />
      </.fixture_section>

      <.fixture_section name="linked" title="Linked avatars">
        <Avatar.avatar
          name="Jane Doe"
          navigate="/components/avatar"
          data-fixture-cell="linked-initials"
        />
        <Avatar.avatar
          src={@sample_image}
          name="Jane Doe"
          navigate="/components/avatar"
          data-fixture-cell="linked-image"
        />
      </.fixture_section>

      <.fixture_section name="group" title="Avatar group with overflow">
        <Avatar.avatar_group max={3} data-fixture-cell="group-overflow">
          <:item><Avatar.avatar name="Ann Lee" /></:item>
          <:item><Avatar.avatar name="Bob Roy" /></:item>
          <:item><Avatar.avatar name="Cy Ng" /></:item>
          <:item><Avatar.avatar name="Di Fox" /></:item>
          <:item><Avatar.avatar name="Ed Vo" /></:item>
        </Avatar.avatar_group>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
