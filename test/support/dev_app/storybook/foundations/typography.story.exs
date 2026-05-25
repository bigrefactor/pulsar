defmodule Pulsar.DevApp.Storybook.Foundations.Typography do
  use PhoenixStorybook.Story, :page

  def doc, do: "Typography scale"

  def render(assigns) do
    ~H"""
    <div class="psb:max-w-4xl psb:mx-auto psb:py-8 psb:px-4">
      <h1 class="psb:text-2xl psb:font-bold psb:text-slate-900 psb:mb-2">Typography Scale</h1>

      <p class="psb:text-base psb:leading-relaxed psb:text-slate-700 psb:mb-10">
        Pulsar's typography tokens map to a consistent scale shared across the design system.
        The size axis — <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">xs</code>, <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">sm</code>, <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">md</code>, <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">lg</code>,
        <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">xl</code>
        — is reused identically for headings, labels, inputs, and buttons.
      </p>

      <div class="psb:space-y-12">
        <section>
          <h2 class="psb:text-lg psb:font-semibold psb:text-slate-700 psb:mb-4 psb:border-b psb:border-slate-200 psb:pb-2">
            Heading scale
          </h2>
          <div class="pulsar-sandbox psb:space-y-6">
            <div class="psb:flex psb:items-baseline psb:gap-4">
              <span class="psb:w-8 psb:shrink-0 psb:text-xs psb:font-mono psb:text-slate-400">xl</span>
              <p class="text-2xl font-bold text-foreground leading-tight">
                The quick brown fox jumps over the lazy dog
              </p>
            </div>
            <div class="psb:flex psb:items-baseline psb:gap-4">
              <span class="psb:w-8 psb:shrink-0 psb:text-xs psb:font-mono psb:text-slate-400">lg</span>
              <p class="text-xl font-bold text-foreground leading-tight">
                The quick brown fox jumps over the lazy dog
              </p>
            </div>
            <div class="psb:flex psb:items-baseline psb:gap-4">
              <span class="psb:w-8 psb:shrink-0 psb:text-xs psb:font-mono psb:text-slate-400">md</span>
              <p class="text-lg font-semibold text-foreground leading-snug">
                The quick brown fox jumps over the lazy dog
              </p>
            </div>
            <div class="psb:flex psb:items-baseline psb:gap-4">
              <span class="psb:w-8 psb:shrink-0 psb:text-xs psb:font-mono psb:text-slate-400">sm</span>
              <p class="text-base font-semibold text-foreground leading-snug">
                The quick brown fox jumps over the lazy dog
              </p>
            </div>
            <div class="psb:flex psb:items-baseline psb:gap-4">
              <span class="psb:w-8 psb:shrink-0 psb:text-xs psb:font-mono psb:text-slate-400">xs</span>
              <p class="text-sm font-semibold text-foreground leading-normal">
                The quick brown fox jumps over the lazy dog
              </p>
            </div>
          </div>
        </section>

        <section>
          <h2 class="psb:text-lg psb:font-semibold psb:text-slate-700 psb:mb-4 psb:border-b psb:border-slate-200 psb:pb-2">
            Label scale
          </h2>
          <div class="pulsar-sandbox psb:space-y-3">
            <div class="psb:flex psb:items-center psb:gap-4">
              <span class="psb:w-8 psb:shrink-0 psb:text-xs psb:font-mono psb:text-slate-400">xl</span>
              <label class="text-xl font-medium text-foreground">Field label (xl)</label>
            </div>
            <div class="psb:flex psb:items-center psb:gap-4">
              <span class="psb:w-8 psb:shrink-0 psb:text-xs psb:font-mono psb:text-slate-400">lg</span>
              <label class="text-lg font-medium text-foreground">Field label (lg)</label>
            </div>
            <div class="psb:flex psb:items-center psb:gap-4">
              <span class="psb:w-8 psb:shrink-0 psb:text-xs psb:font-mono psb:text-slate-400">md</span>
              <label class="text-base font-medium text-foreground">Field label (md — default)</label>
            </div>
            <div class="psb:flex psb:items-center psb:gap-4">
              <span class="psb:w-8 psb:shrink-0 psb:text-xs psb:font-mono psb:text-slate-400">sm</span>
              <label class="text-sm font-medium text-foreground">Field label (sm)</label>
            </div>
            <div class="psb:flex psb:items-center psb:gap-4">
              <span class="psb:w-8 psb:shrink-0 psb:text-xs psb:font-mono psb:text-slate-400">xs</span>
              <label class="text-xs font-medium text-foreground">Field label (xs)</label>
            </div>
          </div>
        </section>

        <section>
          <h2 class="psb:text-lg psb:font-semibold psb:text-slate-700 psb:mb-4 psb:border-b psb:border-slate-200 psb:pb-2">
            Body text
          </h2>
          <div class="pulsar-sandbox psb:space-y-4">
            <p class="text-base text-foreground leading-normal">
              Body text — regular weight, 1rem. Used for paragraph content throughout forms and
              descriptive copy inside UI regions.
            </p>
            <p class="text-sm text-muted-foreground leading-relaxed">
              Helper / muted text — 0.875rem, muted-foreground token. Used for field descriptions,
              secondary notes, and supporting copy that should recede behind the primary label.
            </p>
            <p class="text-xs text-muted-foreground leading-relaxed">
              Caption / hint text — 0.75rem, muted-foreground. Used for character counts, tooltips,
              and very brief supplementary information.
            </p>
          </div>
        </section>

        <section>
          <h2 class="psb:text-lg psb:font-semibold psb:text-slate-700 psb:mb-4 psb:border-b psb:border-slate-200 psb:pb-2">
            Font weights
          </h2>
          <div class="pulsar-sandbox psb:space-y-3">
            <p class="text-base font-normal text-foreground">
              Regular (400) — body copy, input values
            </p>
            <p class="text-base font-medium text-foreground">
              Medium (500) — labels, secondary actions
            </p>
            <p class="text-base font-semibold text-foreground">
              Semibold (600) — primary actions, section headings
            </p>
            <p class="text-base font-bold text-foreground">
              Bold (700) — page headings, strong emphasis
            </p>
          </div>
        </section>

        <section>
          <h2 class="psb:text-lg psb:font-semibold psb:text-slate-700 psb:mb-4 psb:border-b psb:border-slate-200 psb:pb-2">
            Monospace
          </h2>
          <div class="pulsar-sandbox">
            <code class="text-sm font-mono text-foreground bg-muted px-2 py-1 rounded-md">
              mix pulsar.install --component Button
            </code>
          </div>
        </section>
      </div>
    </div>
    """
  end
end
