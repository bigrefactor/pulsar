defmodule Pulsar.DevApp.Storybook.Foundations.Colors do
  use PhoenixStorybook.Story, :page

  def doc, do: "Semantic color tokens"

  def render(assigns) do
    ~H"""
    <div class="psb:max-w-5xl psb:mx-auto psb:py-8 psb:px-4">
      <h1 class="psb:text-2xl psb:font-bold psb:text-slate-900 psb:mb-2">Color Tokens</h1>

      <p class="psb:text-base psb:leading-relaxed psb:text-slate-700 psb:mb-8">
        Pulsar defines 7 semantic color tokens — each is a full 11-shade ladder (50–950) backed by a
        Tailwind palette color. Override any token in your generated
        <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          assets/css/theme.css
        </code>
        to retheme every component at once.
      </p>

      <div class="psb:space-y-12">
        <div>
          <h2 class="psb:text-xl psb:font-semibold psb:text-slate-900 psb:mb-6">
            Light mode
          </h2>
          <div class="pulsar-sandbox psb:space-y-4">
            {color_row("primary", "blue", assigns)}
            {color_row("secondary", "violet", assigns)}
            {color_row("success", "green", assigns)}
            {color_row("warning", "amber", assigns)}
            {color_row("danger", "red", assigns)}
            {color_row("info", "cyan", assigns)}
            {color_row("neutral", "gray", assigns)}
          </div>
        </div>

        <div>
          <h2 class="psb:text-xl psb:font-semibold psb:text-slate-900 psb:mb-6">
            Dark mode
          </h2>
          <div data-theme="dark" class="pulsar-sandbox psb:bg-gray-950 psb:rounded-lg psb:p-4 psb:space-y-4">
            {color_row("primary", "blue", assigns)}
            {color_row("secondary", "violet", assigns)}
            {color_row("success", "green", assigns)}
            {color_row("warning", "amber", assigns)}
            {color_row("danger", "red", assigns)}
            {color_row("info", "cyan", assigns)}
            {color_row("neutral", "gray", assigns)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp color_row(token, base, assigns) do
    shades = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950]

    assigns =
      assigns
      |> Map.put(:token, token)
      |> Map.put(:base, base)
      |> Map.put(:shades, shades)

    ~H"""
    <div>
      <p class="psb:text-xs psb:font-semibold psb:uppercase psb:tracking-wide psb:text-slate-500 psb:mb-2">
        {@token}
        <span class="psb:font-normal psb:normal-case psb:tracking-normal psb:text-slate-400">
          → {@base}
        </span>
      </p>
      <div class="psb:flex psb:gap-1">
        <div
          :for={shade <- @shades}
          class="psb:flex-1 psb:rounded psb:overflow-hidden psb:min-w-0"
          title={"#{@token}-#{shade} → #{@base}-#{shade}"}
        >
          <div class={[
            "psb:h-10",
            "bg-#{@token}-#{shade}"
          ]}>
          </div>
          <p class="psb:text-center psb:text-slate-500 psb:mt-1" style="font-size: 0.6rem; line-height: 1.2;">
            {shade}
          </p>
        </div>
      </div>
    </div>
    """
  end
end
