defmodule Pulsar.Components.PaginationTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Pulsar.Components.Pagination

  # A simple href builder used across page-mode tests.
  defp href_fun, do: fn page -> "/users?page=#{page}" end

  describe "page mode · structure & ARIA" do
    test "renders a nav landmark labeled Pagination by default" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={3} total_pages={10} page_href={@f} />])

      assert html =~ ~s(<nav)
      assert html =~ ~s(aria-label="Pagination")
      assert html =~ ~s(<ul)
      assert html =~ ~s(<li)
    end

    test "aria_label overrides the nav label" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(
          ~H[<Pagination.pagination page={3} total_pages={10} page_href={@f} aria_label="Results pages" />]
        )

      assert html =~ ~s(aria-label="Results pages")
      refute html =~ ~s(aria-label="Pagination")
    end

    test "current page carries aria-current=page" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={3} total_pages={10} page_href={@f} />])

      assert html =~ ~s(aria-current="page")
    end

    test "builds hrefs with the page_href function" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={3} total_pages={5} page_href={@f} />])

      assert html =~ ~s(/users?page=1)
      assert html =~ ~s(/users?page=5)
      # prev points at page 2, next at page 4
      assert html =~ ~s(/users?page=2)
      assert html =~ ~s(/users?page=4)
    end
  end

  describe "page mode · prev/next boundaries" do
    test "prev is disabled (span aria-disabled) on the first page" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(
          ~H[<Pagination.pagination page={1} total_pages={10} page_href={@f} previous_label="Previous" />]
        )

      assert html =~ ~s(aria-disabled="true")
      # The disabled control is a span, not a link, so no href to page 0.
      refute html =~ ~s(/users?page=0)
    end

    test "next is disabled on the last page" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={10} total_pages={10} page_href={@f} next_label="Next" />])

      assert html =~ ~s(aria-disabled="true")
      refute html =~ ~s(/users?page=11)
    end
  end

  describe "page mode · windowing" do
    test "shows all pages when total is small (no ellipsis)" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={2} total_pages={5} page_href={@f} />])

      refute html =~ "…"
      for n <- 1..5, do: assert(html =~ ~s(/users?page=#{n}))
    end

    test "inserts ellipsis for large totals with default siblings/boundaries" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={6} total_pages={20} page_href={@f} />])

      assert html =~ "…"
      # boundary pages and the current window are present
      assert html =~ ~s(/users?page=1)
      assert html =~ ~s(/users?page=20)
      assert html =~ ~s(/users?page=6)
      # a far page is hidden behind the ellipsis
      refute html =~ ~s(/users?page=12)
    end

    test "sibling_count widens the window" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={10} total_pages={20} page_href={@f} sibling_count={2} />])

      for n <- 8..12, do: assert(html =~ ~s(/users?page=#{n}))
    end
  end

  describe "page mode · link_type" do
    test "navigate renders data-phx-link push" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={2} total_pages={5} page_href={@f} link_type="navigate" />])

      assert html =~ ~s(data-phx-link="redirect")
    end

    test "patch renders a patch link" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={2} total_pages={5} page_href={@f} link_type="patch" />])

      assert html =~ ~s(data-phx-link="patch")
    end

    test "href renders a plain anchor (no phx-link)" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={2} total_pages={5} page_href={@f} link_type="href" />])

      refute html =~ ~s(data-phx-link)
      assert html =~ ~s(href="/users?page=1")
    end
  end

  describe "cursor mode" do
    test "renders only prev/next, no page numbers" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H[<Pagination.pagination mode="cursor" prev_href="/users?before=abc" next_href="/users?after=xyz" />]
        )

      assert html =~ ~s(/users?before=abc)
      assert html =~ ~s(/users?after=xyz)
      refute html =~ ~s(aria-current="page")
    end

    test "a falsy prev_href disables the prev control" do
      assigns = %{}

      html =
        rendered_to_string(~H[<Pagination.pagination mode="cursor" prev_href={false} next_href="/users?after=xyz" />])

      assert html =~ ~s(aria-disabled="true")
      assert html =~ ~s(/users?after=xyz)
    end
  end

  describe "summary" do
    test "show_summary renders Page N of M in page mode" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={3} total_pages={12} page_href={@f} show_summary />])

      assert html =~ "Page 3 of 12"
    end

    test "renders an item range when total_count and page_size are given" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(
          ~H[<Pagination.pagination page={3} total_pages={12} page_size={10} total_count={117} page_href={@f} show_summary />]
        )

      assert html =~ "21–30 of 117"
    end

    test "format_summary overrides the default text" do
      assigns = %{f: href_fun(), fmt: fn ctx -> "p#{ctx.page}/#{ctx.total_pages}" end}

      html =
        rendered_to_string(
          ~H[<Pagination.pagination page={3} total_pages={12} page_href={@f} show_summary format_summary={@fmt} />]
        )

      assert html =~ "p3/12"
    end

    test "format_page_number formats rendered page numbers" do
      assigns = %{f: href_fun(), fmt: fn n -> "##{n}" end}

      html =
        rendered_to_string(
          ~H[<Pagination.pagination page={2} total_pages={3} page_href={@f} format_page_number={@fmt} />]
        )

      assert html =~ "#1"
      assert html =~ "#3"
    end
  end

  describe "styling" do
    test "applies solid active fill to the current page" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(
          ~H[<Pagination.pagination page={2} total_pages={3} page_href={@f} variant="solid" color="primary" />]
        )

      assert html =~ "bg-primary"
      assert html =~ "text-primary-foreground"
    end

    test "size classes apply" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={1} total_pages={3} page_href={@f} size="lg" />])

      assert html =~ "h-10"
    end

    test "user class overrides defaults on the nav (Twm merge)" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination page={1} total_pages={3} page_href={@f} class="mt-8" />])

      assert html =~ "mt-8"
    end
  end

  describe "localization" do
    test "previous_label / next_label / go_to_label_prefix override the defaults" do
      assigns = %{f: href_fun()}

      html =
        rendered_to_string(~H[<Pagination.pagination
  page={3}
  total_pages={10}
  page_href={@f}
  previous_label="Précédent"
  next_label="Suivant"
  go_to_label_prefix="Aller à la page"
/>])

      assert html =~ "Précédent"
      assert html =~ "Suivant"
      assert html =~ ~s(aria-label="Aller à la page 1")
    end
  end
end
