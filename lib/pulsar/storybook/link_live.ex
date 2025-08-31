defmodule Pulsar.Storybook.LinkLive do
  @moduledoc """
  Phoenix LiveView component for showcasing Pulsar link components.
  
  Demonstrates all variants, colors, sizes, and states of the link component
  with interactive examples and code snippets.
  """

  use Phoenix.LiveView
  import Pulsar.Storybook.CatalogLayout

  alias Pulsar.Components.Link

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       selected_component: "link",
       page_title: "Link Component"
     )}
  end

  def render(assigns) do
    ~H"""
    <.catalog_layout selected_component={@selected_component}>
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
          <h2 class="text-xl font-semibold mb-4">Size Scaling with Icons</h2>
          <p class="text-muted-foreground dark:text-dark-muted-foreground mb-6">
            Icons automatically scale with text size using em-based sizing for perfect proportional scaling.
          </p>
          <div class="space-y-4">
            <div>
              <h3 class="text-lg font-medium mb-2">External Icon Scaling</h3>
              <div class="space-y-3">
                <div class="text-xs"><Link.a href="https://example.com" size="xs">Extra Small Link</Link.a></div>
                <div class="text-sm"><Link.a href="https://example.com" size="sm">Small Link</Link.a></div>
                <div class="text-base"><Link.a href="https://example.com" size="md">Medium Link</Link.a></div>
                <div class="text-lg"><Link.a href="https://example.com" size="lg">Large Link</Link.a></div>
                <div class="text-xl"><Link.a href="https://example.com" size="xl">Extra Large Link</Link.a></div>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Custom Icon Scaling</h3>
              <div class="space-y-3">
                <div class="text-xs">
                  <Link.a href="#" size="xs">
                    <:start_icon>📝</:start_icon>
                    Extra Small with Start Icon
                  </Link.a>
                </div>
                <div class="text-sm">
                  <Link.a href="#" size="sm">
                    <:start_icon>🔍</:start_icon>
                    Small with Start Icon
                  </Link.a>
                </div>
                <div class="text-base">
                  <Link.a href="#" size="md">
                    <:start_icon>⚙️</:start_icon>
                    Medium with Start Icon
                  </Link.a>
                </div>
                <div class="text-lg">
                  <Link.a href="#" size="lg">
                    <:start_icon>📊</:start_icon>
                    Large with Start Icon
                  </Link.a>
                </div>
                <div class="text-xl">
                  <Link.a href="#" size="xl">
                    <:start_icon>🎯</:start_icon>
                    Extra Large with Start Icon
                  </Link.a>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">Layout Shift Demo</h2>
          <p class="text-muted-foreground dark:text-dark-muted-foreground mb-6">
            Ghost variant uses transparent borders to prevent layout shift on hover.
          </p>
          <div class="space-y-4">
            <div>
              <h3 class="text-lg font-medium mb-2">No Layout Shift</h3>
              <div class="space-y-2">
                <p>Hover these ghost links - notice no jumping:</p>
                <div><Link.a href="#" variant="ghost">First ghost link</Link.a></div>
                <div><Link.a href="#" variant="ghost">Second ghost link</Link.a></div>
                <div><Link.a href="#" variant="ghost">Third ghost link</Link.a></div>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Mixed Content</h3>
              <div class="space-y-2">
                <p>
                  This paragraph contains multiple <Link.a href="#" variant="ghost">ghost links</Link.a> that should not 
                  cause layout shift when you <Link.a href="#" variant="ghost">hover over them</Link.a> in the middle of text flow.
                </p>
              </div>
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">Icon Spacing Examples</h2>
          <p class="text-muted-foreground dark:text-dark-muted-foreground mb-6">
            Consistent spacing between text and icons using margin utilities.
          </p>
          <div class="space-y-4">
            <div>
              <h3 class="text-lg font-medium mb-2">Start Icon Spacing</h3>
              <div class="space-y-2">
                <div><Link.a href="#"><:start_icon>📁</:start_icon>Documents</Link.a></div>
                <div><Link.a href="#"><:start_icon>🔧</:start_icon>Settings</Link.a></div>
                <div><Link.a href="#"><:start_icon>👤</:start_icon>Profile</Link.a></div>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">End Icon Spacing</h3>
              <div class="space-y-2">
                <div><Link.a href="#">Downloads<:end_icon>📥</:end_icon></Link.a></div>
                <div><Link.a href="#">Export<:end_icon>📤</:end_icon></Link.a></div>
                <div><Link.a href="#">Share<:end_icon>🔗</:end_icon></Link.a></div>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Both Icons Spacing</h3>
              <div class="space-y-2">
                <div>
                  <Link.a href="#">
                    <:start_icon>🔍</:start_icon>
                    Search Results
                    <:end_icon>📊</:end_icon>
                  </Link.a>
                </div>
                <div>
                  <Link.a href="#">
                    <:start_icon>💼</:start_icon>
                    Business Plan
                    <:end_icon>📈</:end_icon>
                  </Link.a>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-xl font-semibold mb-4">Edge Cases</h2>
          <p class="text-muted-foreground dark:text-dark-muted-foreground mb-6">
            Testing various edge cases and combinations to ensure robustness.
          </p>
          <div class="space-y-4">
            <div>
              <h3 class="text-lg font-medium mb-2">External Link Override</h3>
              <div class="space-y-2">
                <p>External links with custom end icons don't show automatic icon:</p>
                <div>
                  <Link.a href="https://github.com">
                    GitHub
                    <:end_icon>🐙</:end_icon>
                  </Link.a>
                </div>
                <div>
                  <Link.a href="https://docs.example.com">
                    Documentation
                    <:end_icon>📚</:end_icon>
                  </Link.a>
                </div>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Color Inheritance</h3>
              <div class="space-y-2">
                <p class="text-success dark:text-dark-success">
                  Links with inherit color: <Link.a href="#" color="inherit">inherit parent color</Link.a>
                </p>
                <p class="text-warning dark:text-dark-warning">
                  Another example: <Link.a href="#" color="inherit">matches this warning text</Link.a>
                </p>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Long Text Wrapping</h3>
              <div class="max-w-xs">
                <Link.a href="#" variant="outline">
                  This is a very long link text that should wrap nicely and maintain proper spacing
                </Link.a>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Complex Icon Content</h3>
              <div class="space-y-2">
                <div>
                  <Link.a href="#">
                    <:start_icon>
                      <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                      </svg>
                    </:start_icon>
                    Custom SVG Icon
                  </Link.a>
                </div>
                <div>
                  <Link.a href="#">
                    <:start_icon>
                      <span class="text-green-500">✓</span>
                    </:start_icon>
                    Styled Icon Element
                  </Link.a>
                </div>
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
    </.catalog_layout>
    """
  end
end