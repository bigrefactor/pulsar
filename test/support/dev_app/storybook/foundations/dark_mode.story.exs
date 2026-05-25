defmodule Pulsar.DevApp.Storybook.Foundations.DarkMode do
  use PhoenixStorybook.Story, :page

  alias Pulsar.Components.Button
  alias Pulsar.Components.Input
  alias Pulsar.Components.Label

  def doc, do: "Light + dark mode demo"

  @global_toggle_code """
  // Enable dark mode
  document.documentElement.dataset.theme = 'dark';

  // Return to light mode
  document.documentElement.dataset.theme = 'light';\
  """

  @subtree_code ~s(<div data-theme="dark">
  <!-- all Pulsar components here use dark tokens -->
  <.button variant="solid" color="primary">Dark button</.button>
</div>)

  @token_resolution_code """
  @custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *));

  /* Resulting component classes */
  "bg-primary text-primary-foreground dark:bg-dark-primary dark:text-dark-primary-foreground"\
  """

  @system_preference_code """
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  if (prefersDark) {
    document.documentElement.dataset.theme = 'dark';
  }\
  """

  def render(assigns) do
    assigns =
      assigns
      |> Map.put(:global_toggle_code, @global_toggle_code)
      |> Map.put(:subtree_code, @subtree_code)
      |> Map.put(:token_resolution_code, @token_resolution_code)
      |> Map.put(:system_preference_code, @system_preference_code)

    ~H"""
    <div class="psb:max-w-4xl psb:mx-auto psb:py-8 psb:px-4">
      <h1 class="psb:text-2xl psb:font-bold psb:text-slate-900 psb:mb-2">Dark Mode</h1>

      <p class="psb:text-base psb:leading-relaxed psb:text-slate-700 psb:mb-8">
        Pulsar uses a
        <code class="psb:font-mono psb:text-sm psb:bg-slate-100 psb:px-1 psb:rounded">
          data-theme="dark"
        </code>
        attribute strategy rather than a class-based toggle. Add the attribute to any ancestor
        element to flip all semantic color tokens for the subtree beneath it. Every Pulsar
        component automatically adapts — no extra classes required.
      </p>

      <div class="psb:space-y-12">
        <section>
          <h2 class="psb:text-lg psb:font-semibold psb:text-slate-700 psb:mb-6 psb:border-b psb:border-slate-200 psb:pb-2">
            Side-by-side comparison
          </h2>

          <div class="psb:grid psb:grid-cols-1 psb:md:grid-cols-2 psb:gap-6">
            <%!-- Light mode card --%>
            <div>
              <p class="psb:text-sm psb:font-semibold psb:text-slate-500 psb:uppercase psb:tracking-wide psb:mb-3">
                Light mode
              </p>
              <div class="pulsar-sandbox bg-surface-1 border border-border rounded-lg p-6 space-y-4">
                <div>
                  <h3 class="text-lg font-semibold text-foreground">Sign in to your account</h3>
                  <p class="text-sm text-muted-foreground mt-1">
                    Welcome back — enter your credentials below.
                  </p>
                </div>
                <div class="space-y-3">
                  <div>
                    <Label.label for="light_email">Email address</Label.label>
                    <Input.input
                      name="light_email"
                      type="email"
                      placeholder="you@example.com"
                      class="mt-1"
                    />
                  </div>
                  <div>
                    <Label.label for="light_password">Password</Label.label>
                    <Input.input
                      name="light_password"
                      type="password"
                      placeholder="••••••••"
                      class="mt-1"
                    />
                  </div>
                </div>
                <Button.button variant="solid" color="primary" class="w-full">
                  Sign in
                </Button.button>
                <p class="text-xs text-center text-muted-foreground">
                  Don't have an account? <Button.button variant="link" color="primary" size="xs">Create one</Button.button>
                </p>
              </div>
            </div>
            <%!-- Dark mode card --%>
            <div>
              <p class="psb:text-sm psb:font-semibold psb:text-slate-500 psb:uppercase psb:tracking-wide psb:mb-3">
                Dark mode
              </p>
              <div
                data-theme="dark"
                class="pulsar-sandbox bg-surface-1 border border-border rounded-lg p-6 space-y-4"
              >
                <div>
                  <h3 class="text-lg font-semibold text-foreground">Sign in to your account</h3>
                  <p class="text-sm text-muted-foreground mt-1">
                    Welcome back — enter your credentials below.
                  </p>
                </div>
                <div class="space-y-3">
                  <div>
                    <Label.label for="dark_email">Email address</Label.label>
                    <Input.input
                      name="dark_email"
                      type="email"
                      placeholder="you@example.com"
                      class="mt-1"
                    />
                  </div>
                  <div>
                    <Label.label for="dark_password">Password</Label.label>
                    <Input.input
                      name="dark_password"
                      type="password"
                      placeholder="••••••••"
                      class="mt-1"
                    />
                  </div>
                </div>
                <Button.button variant="solid" color="primary" class="w-full">
                  Sign in
                </Button.button>
                <p class="text-xs text-center text-muted-foreground">
                  Don't have an account? <Button.button variant="link" color="primary" size="xs">Create one</Button.button>
                </p>
              </div>
            </div>
          </div>
        </section>

        <section>
          <h2 class="psb:text-lg psb:font-semibold psb:text-slate-700 psb:mb-4 psb:border-b psb:border-slate-200 psb:pb-2">
            How it works
          </h2>

          <div class="psb:space-y-6">
            <div>
              <h3 class="psb:text-base psb:font-semibold psb:text-slate-800 psb:mb-2">
                1. Toggling dark mode globally
              </h3>
              <p class="psb:text-sm psb:text-slate-600 psb:mb-2">
                Set the attribute on the root element to flip the entire page:
              </p>
              <pre class="psb:bg-slate-800 psb:text-slate-100 psb:font-mono psb:text-sm psb:rounded-lg psb:px-5 psb:py-4"><code>{@global_toggle_code}</code></pre>
            </div>

            <div>
              <h3 class="psb:text-base psb:font-semibold psb:text-slate-800 psb:mb-2">
                2. Scoping dark mode to a subtree
              </h3>
              <p class="psb:text-sm psb:text-slate-600 psb:mb-2">
                Apply the attribute to any container to dark-theme just that section:
              </p>
              <pre class="psb:bg-slate-800 psb:text-slate-100 psb:font-mono psb:text-sm psb:rounded-lg psb:px-5 psb:py-4"><code>{@subtree_code}</code></pre>
            </div>

            <div>
              <h3 class="psb:text-base psb:font-semibold psb:text-slate-800 psb:mb-2">
                3. How tokens resolve
              </h3>
              <p class="psb:text-sm psb:text-slate-600 psb:mb-3">
                Each semantic token has both a light and a dark variant. The Tailwind custom variant
                <code class="psb:font-mono psb:text-xs psb:bg-slate-100 psb:px-1 psb:rounded">
                  dark:
                </code>
                matches elements inside a
                <code class="psb:font-mono psb:text-xs psb:bg-slate-100 psb:px-1 psb:rounded">
                  [data-theme="dark"]
                </code>
                ancestor. Components use both bare and <code class="psb:font-mono psb:text-xs psb:bg-slate-100 psb:px-1 psb:rounded">
                  dark:
                </code>-prefixed classes side by side:
              </p>
              <pre class="psb:bg-slate-800 psb:text-slate-100 psb:font-mono psb:text-sm psb:rounded-lg psb:px-5 psb:py-4"><code>{@token_resolution_code}</code></pre>
            </div>

            <div>
              <h3 class="psb:text-base psb:font-semibold psb:text-slate-800 psb:mb-2">
                4. Respecting system preference
              </h3>
              <p class="psb:text-sm psb:text-slate-600 psb:mb-2">
                Combine the strategy with
                <code class="psb:font-mono psb:text-xs psb:bg-slate-100 psb:px-1 psb:rounded">
                  prefers-color-scheme
                </code>
                to auto-initialize on first load:
              </p>
              <pre class="psb:bg-slate-800 psb:text-slate-100 psb:font-mono psb:text-sm psb:rounded-lg psb:px-5 psb:py-4"><code>{@system_preference_code}</code></pre>
            </div>
          </div>
        </section>
      </div>
    </div>
    """
  end
end
