defmodule Pulsar.Storybook.LinkLive do
  use Phoenix.LiveView

  alias Pulsar.Components.Link

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <div class="max-w-4xl mx-auto space-y-12">
        <div>
          <h1 class="text-3xl font-bold mb-2">Link</h1>
          <p class="text-muted-foreground dark:text-dark-muted-foreground">
            Styled link component for navigation with semantic variants and consistent colors.
            Built on Phoenix.Component.link with automatic external link handling.
          </p>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-6">All Variant & Color Combinations</h2>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div>
              <h3 class="text-lg font-medium mb-4">solid Variant (Default)</h3>
              <div class="space-y-3">
                <div><Link.a href="#" color="primary">Primary Link</Link.a></div>
                <div><Link.a href="#" color="secondary">Secondary Link</Link.a></div>
                <div><Link.a href="#" color="muted">Muted Link</Link.a></div>
                <div><Link.a href="#" color="success">Success Link</Link.a></div>
                <div><Link.a href="#" color="danger">Danger Link</Link.a></div>
                <div><Link.a href="#" color="warning">Warning Link</Link.a></div>
                <div><Link.a href="#" color="info">Info Link</Link.a></div>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-4">ghost Variant</h3>
              <div class="space-y-3">
                <div><Link.a href="#" variant="ghost" color="primary">Primary Link</Link.a></div>
                <div><Link.a href="#" variant="ghost" color="secondary">Secondary Link</Link.a></div>
                <div><Link.a href="#" variant="ghost" color="muted">Muted Link</Link.a></div>
                <div><Link.a href="#" variant="ghost" color="success">Success Link</Link.a></div>
                <div><Link.a href="#" variant="ghost" color="danger">Danger Link</Link.a></div>
                <div><Link.a href="#" variant="ghost" color="warning">Warning Link</Link.a></div>
                <div><Link.a href="#" variant="ghost" color="info">Info Link</Link.a></div>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-4">outline Variant</h3>
              <div class="space-y-3">
                <div><Link.a href="#" variant="outline" color="primary">Primary Link</Link.a></div>
                <div><Link.a href="#" variant="outline" color="secondary">Secondary Link</Link.a></div>
                <div><Link.a href="#" variant="outline" color="muted">Muted Link</Link.a></div>
                <div><Link.a href="#" variant="outline" color="success">Success Link</Link.a></div>
                <div><Link.a href="#" variant="outline" color="danger">Danger Link</Link.a></div>
                <div><Link.a href="#" variant="outline" color="warning">Warning Link</Link.a></div>
                <div><Link.a href="#" variant="outline" color="info">Info Link</Link.a></div>
              </div>
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">Sizes</h2>
          <p class="text-muted-foreground dark:text-dark-muted-foreground mb-4">
            Links can inherit parent text size or use explicit sizing.
          </p>
          <div class="space-y-4">
            <div class="flex items-end gap-4">
              <Link.a href="#" size="xs">Extra Small</Link.a>
              <Link.a href="#" size="sm">Small</Link.a>
              <Link.a href="#" size="md">Medium</Link.a>
              <Link.a href="#" size="lg">Large</Link.a>
              <Link.a href="#" size="xl">Extra Large</Link.a>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Inherit Parent Size</h3>
              <div class="space-y-2">
                <p class="text-sm">Small paragraph with <Link.a href="#" size="inherit">inherited link</Link.a> that matches.</p>
                <p class="text-lg">Large paragraph with <Link.a href="#" size="inherit">inherited link</Link.a> that scales.</p>
                <p class="text-xl">Extra large paragraph with <Link.a href="#" size="inherit">inherited link</Link.a> maintaining flow.</p>
              </div>
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">External Links</h2>
          <p class="text-muted-foreground dark:text-dark-muted-foreground mb-6">
            External links automatically get security attributes and visual indicators.
          </p>
          <div class="space-y-4">
            <div>
              <h3 class="text-lg font-medium mb-2">Automatic External Icon</h3>
              <div class="space-y-2">
                <div><Link.a href="https://example.com">Visit Example.com</Link.a></div>
                <div><Link.a href="https://phoenix-framework.org" color="secondary">Phoenix Framework</Link.a></div>
                <div><Link.a href="https://tailwindcss.com" variant="ghost">Tailwind CSS</Link.a></div>
                <div><Link.a href="https://elixir-lang.org" variant="outline" color="success">Elixir Language</Link.a></div>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Custom End Icons</h3>
              <div class="space-y-2">
                <div>
                  <Link.a href="https://github.com">
                    GitHub Repository
                    <:end_icon>🔗</:end_icon>
                  </Link.a>
                </div>
                <div>
                  <Link.a href="https://docs.example.com" color="info">
                    Documentation
                    <:end_icon>📖</:end_icon>
                  </Link.a>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">With Icons</h2>
          <div class="space-y-4">
            <div>
              <h3 class="text-lg font-medium mb-2">Start Icons</h3>
              <div class="space-y-2">
                <div>
                  <Link.a navigate="/catalog/input">
                    <:start_icon>📝</:start_icon>
                    Input Component
                  </Link.a>
                </div>
                <div>
                  <Link.a navigate="/catalog/button" color="secondary">
                    <:start_icon>🔘</:start_icon>
                    Button Component
                  </Link.a>
                </div>
                <div>
                  <Link.a href="#" variant="ghost" color="muted">
                    <:start_icon>⚙️</:start_icon>
                    Settings
                  </Link.a>
                </div>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Both Icons</h3>
              <div class="space-y-2">
                <div>
                  <Link.a href="#" variant="outline" color="info">
                    <:start_icon>🔍</:start_icon>
                    Search Documentation
                    <:end_icon>📚</:end_icon>
                  </Link.a>
                </div>
                <div>
                  <Link.a href="#" color="success">
                    <:start_icon>✅</:start_icon>
                    Complete Setup
                    <:end_icon>→</:end_icon>
                  </Link.a>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">Phoenix Navigation</h2>
          <div class="space-y-4">
            <div>
              <h3 class="text-lg font-medium mb-2">LiveView Navigation</h3>
              <div class="space-y-2">
                <div><Link.a navigate="/catalog/button">Button Component (navigate)</Link.a></div>
                <div><Link.a navigate="/catalog/input" color="secondary">Input Component (navigate)</Link.a></div>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Patch Navigation</h3>
              <div class="space-y-2">
                <div><Link.a patch="/catalog/link" variant="ghost">Patch Current Page</Link.a></div>
                <div><Link.a patch="/catalog/link" color="muted">Patch with Muted Color</Link.a></div>
              </div>
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">Usage Examples</h2>
          <div class="space-y-6">
            <div class="bg-surface-1 dark:bg-dark-surface-1 p-4 rounded-lg border border-border dark:border-dark-border">
              <h3 class="text-lg font-medium mb-2">Basic Links</h3>
              <div class="space-y-2 mb-4">
                <div><Link.a href="/profile">View Profile</Link.a></div>
                <div><Link.a href="/settings" color="muted">Account Settings</Link.a></div>
              </div>
              <pre class="text-sm text-muted-foreground dark:text-dark-muted-foreground overflow-x-auto"><code>                    # Default (solid variant, primary color)
                    &lt;Link.a href="/profile"&gt;View Profile&lt;/Link.a&gt;

                    # Muted color
                    &lt;Link.a href="/settings" color="muted"&gt;Account Settings&lt;/Link.a&gt;</code></pre>
            </div>

            <div class="bg-surface-1 dark:bg-dark-surface-1 p-4 rounded-lg border border-border dark:border-dark-border">
              <h3 class="text-lg font-medium mb-2">External Link</h3>
              <div class="mb-4">
                <Link.a href="https://elixir-lang.org">Visit Elixir Website</Link.a>
              </div>
              <pre class="text-sm text-muted-foreground dark:text-dark-muted-foreground overflow-x-auto"><code>                # Automatic external handling
                &lt;Link.a href="https://elixir-lang.org"&gt;
                  Visit Elixir Website
                &lt;/Link.a&gt;</code></pre>
            </div>

            <div class="bg-surface-1 dark:bg-dark-surface-1 p-4 rounded-lg border border-border dark:border-dark-border">
              <h3 class="text-lg font-medium mb-2">Contextual Usage</h3>
              <div class="mb-4">
                <p class="text-base">
                  Welcome to our platform! Please 
                  <Link.a href="/register" color="success">create an account</Link.a>
                  or <Link.a href="/login">sign in</Link.a> to continue.
                  Need help? <Link.a href="/support" variant="ghost" color="muted">Contact support</Link.a>
                </p>
              </div>
              <pre class="text-sm text-muted-foreground dark:text-dark-muted-foreground overflow-x-auto"><code>                &lt;p&gt;
                  Welcome to our platform! Please 
                  &lt;Link.a href="/register" color="success"&gt;create an account&lt;/Link.a&gt;
                  or &lt;Link.a href="/login"&gt;sign in&lt;/Link.a&gt; to continue.
                  Need help? &lt;Link.a href="/support" variant="ghost" color="muted"&gt;Contact support&lt;/Link.a&gt;
                &lt;/p&gt;</code></pre>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end