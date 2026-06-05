defmodule Pulsar.DevApp.Storybook.Components.Pagination do
  use PhoenixStorybook.Story, :component

  alias Pulsar.Components.Pagination

  def function, do: &Pagination.pagination/1
  def render_source, do: :function

  def attributes do
    [
      %Attr{id: :mode, type: :string, values: ~w(page cursor), default: "page", doc: "page = numbered; cursor = prev/next only"},
      %Attr{id: :variant, type: :string, values: ~w(solid outline ghost), default: "ghost", doc: "How the current page is emphasized"},
      %Attr{
        id: :color,
        type: :string,
        values: ~w(neutral primary secondary success danger warning info),
        default: "primary",
        doc: "Accent color for the active page"
      },
      %Attr{id: :size, type: :string, values: ~w(xs sm md lg xl), default: "md", doc: "Control size"},
      %Attr{id: :sibling_count, type: :integer, default: 1, doc: "Pages on each side of current"},
      %Attr{id: :boundary_count, type: :integer, default: 1, doc: "Pages pinned at each end"},
      %Attr{id: :show_summary, type: :boolean, default: false, doc: "Render the page/range summary"}
    ]
  end

  def variations do
    href = fn p -> "/storybook-demo?page=#{p}" end

    [
      %Variation{
        id: :default,
        description: "Page 3 of 10",
        attributes: %{page: 3, total_pages: 10, page_href: href, link_type: "href"}
      },
      %Variation{
        id: :truncated,
        description: "Windowed with ellipses",
        attributes: %{page: 6, total_pages: 20, page_href: href, link_type: "href"}
      },
      %Variation{
        id: :solid_primary,
        description: "Solid active fill",
        attributes: %{page: 4, total_pages: 10, variant: "solid", color: "primary", page_href: href, link_type: "href"}
      },
      %Variation{
        id: :outline,
        description: "Outline (boxed)",
        attributes: %{page: 4, total_pages: 10, variant: "outline", page_href: href, link_type: "href"}
      },
      %Variation{
        id: :with_summary,
        description: "Item-range summary",
        attributes: %{
          page: 3,
          total_pages: 12,
          page_size: 10,
          total_count: 117,
          show_summary: true,
          page_href: href,
          link_type: "href"
        }
      },
      %Variation{
        id: :cursor,
        description: "Cursor mode (prev/next only)",
        attributes: %{mode: "cursor", prev_href: "/storybook-demo?before=abc", next_href: "/storybook-demo?after=xyz", link_type: "href"}
      }
    ]
  end
end
