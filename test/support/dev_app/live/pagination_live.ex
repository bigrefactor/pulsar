defmodule Pulsar.DevApp.PaginationLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Pagination

  @variants ~w(ghost solid outline)
  @colors ~w(neutral primary secondary success danger warning info)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    assigns =
      assign(assigns,
        variants: @variants,
        colors: @colors,
        sizes: @sizes,
        href: fn p -> "/components/pagination?page=#{p}" end
      )

    ~H"""
    <.fixture_page name="pagination" title="Pagination">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <%= for color <- @colors, size <- @sizes do %>
          <Pagination.pagination
            page={6}
            total_pages={20}
            page_href={@href}
            link_type="href"
            variant={variant}
            color={color}
            size={size}
            data-fixture-cell={"#{variant}-#{color}-#{size}"}
          />
        <% end %>
      </.fixture_section>

      <.fixture_section name="boundaries" title="disabled boundaries">
        <Pagination.pagination page={1} total_pages={5} page_href={@href} link_type="href" data-fixture-cell="first-page" />
        <Pagination.pagination page={5} total_pages={5} page_href={@href} link_type="href" data-fixture-cell="last-page" />
      </.fixture_section>

      <.fixture_section name="summary" title="with summary">
        <Pagination.pagination
          page={3}
          total_pages={12}
          page_size={10}
          total_count={117}
          show_summary
          page_href={@href}
          link_type="href"
          data-fixture-cell="summary"
        />
      </.fixture_section>

      <.fixture_section name="cursor" title="cursor mode">
        <Pagination.pagination
          mode="cursor"
          prev_href="/components/pagination?before=abc"
          next_href="/components/pagination?after=xyz"
          link_type="href"
          data-fixture-cell="cursor-both"
        />
        <Pagination.pagination
          mode="cursor"
          prev_href={false}
          next_href="/components/pagination?after=xyz"
          link_type="href"
          data-fixture-cell="cursor-start"
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
