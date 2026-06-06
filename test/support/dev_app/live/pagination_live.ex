defmodule Pulsar.DevApp.PaginationLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Pagination

  @colors ~w(neutral primary secondary success danger warning info)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    variant = Atom.to_string(assigns.live_action)

    assigns =
      assign(assigns,
        variant: variant,
        colors: @colors,
        sizes: @sizes,
        href: fn p -> "/components/pagination/#{variant}?page=#{p}" end
      )

    ~H"""
    <.fixture_page name={"pagination-#{@variant}"} title={"Pagination (#{@variant})"}>
      <.fixture_section
        :for={color <- @colors}
        name={"#{@variant}-#{color}"}
        title={"#{@variant} · #{color}"}
      >
        <Pagination.pagination
          :for={size <- @sizes}
          page={6}
          total_pages={20}
          page_href={@href}
          link_type="href"
          variant={@variant}
          color={color}
          size={size}
          aria_label={"Pagination #{@variant} #{color} #{size}"}
          data-fixture-cell={"#{@variant}-#{color}-#{size}"}
        />
      </.fixture_section>

      <%!-- Variant-agnostic behaviors are rendered once (on the ghost route) to
            keep each per-variant fixture light enough to connect within the
            browser-a11y mount budget. --%>
      <.fixture_section :if={@variant == "ghost"} name="boundaries" title="disabled boundaries">
        <Pagination.pagination
          page={1}
          total_pages={5}
          page_href={@href}
          link_type="href"
          aria_label="Pagination first page"
          data-fixture-cell="first-page"
        />
        <Pagination.pagination
          page={5}
          total_pages={5}
          page_href={@href}
          link_type="href"
          aria_label="Pagination last page"
          data-fixture-cell="last-page"
        />
      </.fixture_section>

      <.fixture_section :if={@variant == "ghost"} name="summary" title="with summary">
        <Pagination.pagination
          page={3}
          total_pages={12}
          page_size={10}
          total_count={117}
          show_summary
          page_href={@href}
          link_type="href"
          aria_label="Pagination with summary"
          data-fixture-cell="summary"
        />
      </.fixture_section>

      <.fixture_section :if={@variant == "ghost"} name="cursor" title="cursor mode">
        <Pagination.pagination
          mode="cursor"
          prev_href="/components/pagination/ghost?before=abc"
          next_href="/components/pagination/ghost?after=xyz"
          link_type="href"
          aria_label="Pagination cursor both"
          data-fixture-cell="cursor-both"
        />
        <Pagination.pagination
          mode="cursor"
          prev_href={false}
          next_href="/components/pagination/ghost?after=xyz"
          link_type="href"
          aria_label="Pagination cursor start"
          data-fixture-cell="cursor-start"
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
