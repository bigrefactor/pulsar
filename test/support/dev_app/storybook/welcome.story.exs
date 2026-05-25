defmodule Pulsar.DevApp.Storybook.Welcome do
  # See https://hexdocs.pm/phoenix_storybook/PhoenixStorybook.Story.html for full story
  # documentation.
  use PhoenixStorybook.Story, :page

  def doc, do: "Welcome to Pulsar"

  def render(assigns) do
    ~H"""
    <div class="psb:max-w-3xl psb:mx-auto psb:py-8 psb:px-4">
      <h1 class="psb:text-3xl psb:font-bold psb:text-slate-900 psb:mb-6">
        Welcome to Pulsar
      </h1>

      <p class="psb:text-base psb:leading-relaxed psb:text-slate-700 psb:mb-8">
        Pulsar is a production-ready component library for Phoenix LiveView. It ships
        accessible, styled components with all WAI-ARIA behavior built in, using only
        <a
          class="psb:text-indigo-600 psb:underline psb:hover:text-indigo-800"
          href="https://hex.pm/packages/twm"
          target="_blank"
          rel="noopener noreferrer"
        >
          Twm
        </a>
        as a runtime dependency. Components are generator-first: running
        <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          mix pulsar.install
        </code>
        copies each component's full source into your
        application, giving you complete ownership, predictable Tailwind class purging, and the
        freedom to customize without fighting a library abstraction.
      </p>

      <h2 class="psb:text-xl psb:font-semibold psb:text-slate-900 psb:mb-3">
        Quick install
      </h2>

      <pre class="psb:bg-slate-800 psb:text-slate-100 psb:font-mono psb:text-sm psb:rounded-lg psb:px-5 psb:py-4 psb:mb-3"><code>mix pulsar.install</code></pre>

      <p class="psb:text-sm psb:text-slate-600 psb:mb-8">
        Components are copied into your
        <code class="psb:font-mono psb:text-xs psb:bg-slate-100 psb:px-1 psb:rounded">
          lib/&lt;app&gt;_web/components/
        </code>
        directory alongside a generated theme CSS file.
      </p>

      <h2 class="psb:text-xl psb:font-semibold psb:text-slate-900 psb:mb-3">
        Theme philosophy
      </h2>

      <p class="psb:text-base psb:leading-relaxed psb:text-slate-700 psb:mb-8">
        Pulsar uses a semantic color system built on CSS custom properties: <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          primary
        </code>, <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          secondary
        </code>, <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          success
        </code>, <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          warning
        </code>, <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          danger
        </code>, <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          info
        </code>, and <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          neutral
        </code>.
        Light and dark mode are supported via a
        <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          data-theme="dark"
        </code>
        attribute on the root element — no separate class-based toggle required. To remap any
        token to a different palette color or a custom hex value, override the corresponding
        CSS custom property in your generated <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          assets/css/theme.css
        </code>:
        for example, changing
        <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          --color-primary-500
        </code>
        to
        <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          var(--color-indigo-500)
        </code>
        switches every component that uses the primary token in a single edit.
      </p>

      <h2 class="psb:text-xl psb:font-semibold psb:text-slate-900 psb:mb-3">
        Links
      </h2>

      <ul class="psb:space-y-2 psb:text-base psb:text-slate-700">
        <li>
          <a
            class="psb:text-indigo-600 psb:underline psb:hover:text-indigo-800"
            href="https://github.com/bigrefactor/pulsar"
            target="_blank"
            rel="noopener noreferrer"
          >
            GitHub — bigrefactor/pulsar
          </a>
        </li>
        <li>
          <a
            class="psb:text-indigo-600 psb:underline psb:hover:text-indigo-800"
            href="https://hex.pm/packages/pulsar"
            target="_blank"
            rel="noopener noreferrer"
          >
            Hex package — hex.pm/packages/pulsar
          </a>
        </li>
        <li>
          <span class="psb:text-slate-700">
            Accessibility audits — see
            <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
              docs/a11y/README.md
            </code>
            in the repository
          </span>
        </li>
        <li>
          <a
            class="psb:text-indigo-600 psb:underline psb:hover:text-indigo-800"
            href="https://hexdocs.pm/phoenix_storybook"
            target="_blank"
            rel="noopener noreferrer"
          >
            phoenix_storybook docs — hexdocs.pm/phoenix_storybook
          </a>
        </li>
      </ul>
    </div>
    """
  end
end
