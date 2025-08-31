defmodule Pulsar.Storybook.InputLive do
  @moduledoc """
  Phoenix LiveView component for showcasing Pulsar input components.

  Demonstrates all input variants, colors, sizes, decorator patterns, and error handling.
  """

  use Phoenix.LiveView
  import Pulsar.Components.Input
  import Pulsar.Storybook.CatalogLayout

  def mount(_params, _session, socket) do
    # Create form changeset for demonstration with validation errors
    form_data = %{
      "email" => "",
      "password" => "",
      "website" => "",
      "amount" => "",
      "search" => ""
    }

    form = to_form(form_data, as: "demo")
    
    # Simulate form with errors for demonstration
    error_form = to_form(
      form_data
      |> Map.put("email", "invalid-email")
      |> Map.put("password", "short"),
      as: "error_demo",
      errors: [
        email: {"must be a valid email format", []},
        password: {"must be at least 8 characters", []}
      ]
    )

    {:ok,
     assign(socket,
       selected_component: "input",
       page_title: "Input Component",
       form: form,
       error_form: error_form,
       show_dark_mode: false
     )}
  end

  def render(assigns) do
    ~H"""
    <.catalog_layout selected_component={@selected_component}>
      <div class="max-w-4xl mx-auto space-y-12">
        <div>
          <h1 class="text-3xl font-bold mb-2">Input</h1>
          <p class="text-muted dark:text-dark-muted">
            Accessible input component with full variant and color support, decorator system, and automatic error handling.
          </p>
        </div>
        
        <!-- Variants & Colors Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Variants & Colors</h2>
            <p class="text-muted dark:text-dark-muted mb-6">
              Three variants with full color palette support. Error states automatically override colors.
            </p>
            
            <div class="space-y-8">
              <!-- Outline Variant -->
              <div>
                <h3 class="text-lg font-medium mb-4">Outline</h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <.input variant="outline" color="neutral" name="outline_neutral" placeholder="Neutral (default)" />
                  <.input variant="outline" color="primary" name="outline_primary" placeholder="Primary" />
                  <.input variant="outline" color="secondary" name="outline_secondary" placeholder="Secondary" />
                  <.input variant="outline" color="success" name="outline_success" placeholder="Success" />
                  <.input variant="outline" color="danger" name="outline_danger" placeholder="Danger" />
                  <.input variant="outline" color="warning" name="outline_warning" placeholder="Warning" />
                  <.input variant="outline" color="info" name="outline_info" placeholder="Info" />
                  <.input field={@error_form[:email]} placeholder="Error override" />
                </div>
              </div>

              <!-- Ghost Variant -->
              <div>
                <h3 class="text-lg font-medium mb-4">Ghost</h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <.input variant="ghost" color="neutral" name="ghost_neutral" placeholder="Neutral" />
                  <.input variant="ghost" color="primary" name="ghost_primary" placeholder="Primary" />
                  <.input variant="ghost" color="secondary" name="ghost_secondary" placeholder="Secondary" />
                  <.input variant="ghost" color="success" name="ghost_success" placeholder="Success" />
                  <.input variant="ghost" color="danger" name="ghost_danger" placeholder="Danger" />
                  <.input variant="ghost" color="warning" name="ghost_warning" placeholder="Warning" />
                  <.input variant="ghost" color="info" name="ghost_info" placeholder="Info" />
                  <.input variant="ghost" field={@error_form[:password]} placeholder="Error override" />
                </div>
              </div>

              <!-- Solid Variant -->
              <div>
                <h3 class="text-lg font-medium mb-4">Solid</h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <.input variant="solid" color="neutral" name="solid_neutral" placeholder="Neutral" />
                  <.input variant="solid" color="primary" name="solid_primary" placeholder="Primary" />
                  <.input variant="solid" color="secondary" name="solid_secondary" placeholder="Secondary" />
                  <.input variant="solid" color="success" name="solid_success" placeholder="Success" />
                  <.input variant="solid" color="danger" name="solid_danger" placeholder="Danger" />
                  <.input variant="solid" color="warning" name="solid_warning" placeholder="Warning" />
                  <.input variant="solid" color="info" name="solid_info" placeholder="Info" />
                  <.input variant="solid" field={@error_form[:website]} placeholder="Error override" />
                </div>
              </div>
            </div>
          </div>
        </section>
        
        <!-- Sizes Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Sizes</h2>
            <div class="space-y-3">
              <.input size="xs" name="size_xs" placeholder="Extra small input" />
              <.input size="sm" name="size_sm" placeholder="Small input" />
              <.input size="md" name="size_md" placeholder="Medium input (default)" />
              <.input size="lg" name="size_lg" placeholder="Large input" />
              <.input size="xl" name="size_xl" placeholder="Extra large input" />
            </div>
          </div>
        </section>
        
        <!-- Decorators Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Decorators</h2>
            <p class="text-muted dark:text-dark-muted mb-4">
              Add icons, text, or interactive elements to inputs.
            </p>
            <div class="space-y-6">
              <div>
                <h3 class="text-lg font-medium mb-3">Outline with Colors</h3>
                <div class="space-y-3">
                  <.input variant="outline" color="primary" name="email_primary" placeholder="Enter email">
                    <:start_decorator>
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">
                        <path d="M3 4a2 2 0 00-2 2v1.161l8.441 4.221a1.25 1.25 0 001.118 0L19 7.162V6a2 2 0 00-2-2H3z" />
                        <path d="M19 8.839l-7.77 3.885a2.75 2.75 0 01-2.46 0L1 8.839V14a2 2 0 002 2h14a2 2 0 002-2V8.839z" />
                      </svg>
                    </:start_decorator>
                  </.input>

                  <.input variant="outline" color="success" name="price_success" placeholder="0.00">
                    <:start_decorator>$</:start_decorator>
                    <:end_decorator>USD</:end_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-3">Solid Variant</h3>
                <div class="space-y-3">
                  <.input variant="solid" color="secondary" name="website_solid" placeholder="yoursite">
                    <:start_decorator>https://</:start_decorator>
                    <:end_decorator>.com</:end_decorator>
                  </.input>

                  <.input variant="solid" color="info" name="code_solid" placeholder="Enter code">
                    <:start_decorator>CODE-</:start_decorator>
                    <:end_decorator>
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">
                        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a.75.75 0 000 1.5h.253a.25.25 0 01.244.304l-.459 2.066A1.75 1.75 0 0010.747 15H11a.75.75 0 000-1.5h-.253a.25.25 0 01-.244-.304l.459-2.066A1.75 1.75 0 009.253 9H9z" clip-rule="evenodd" />
                      </svg>
                    </:end_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-3">Ghost Variant</h3>
                <div class="space-y-3">
                  <.input variant="ghost" color="warning" name="search_ghost" placeholder="Search...">
                    <:start_decorator>
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">
                        <path fill-rule="evenodd" d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z" clip-rule="evenodd" />
                      </svg>
                    </:start_decorator>
                    <:end_decorator>
                      <button class="text-warning-600 hover:text-warning-800 dark:text-warning-400 dark:hover:text-warning-200 text-sm">Search</button>
                    </:end_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-3">Username Input</h3>
                <.input name="username" placeholder="username">
                  <:start_decorator>@</:start_decorator>
                </.input>
              </div>
            </div>
          </div>
        </section>
        
        <!-- Form Integration Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Phoenix Form Integration</h2>
            <p class="text-muted dark:text-dark-muted mb-4">
              Inputs automatically show error states when used with Phoenix forms.
            </p>
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium mb-2">Email (Valid)</label>
                <.input field={@form[:email]} placeholder="Enter your email" />
              </div>
              
              <div>
                <label class="block text-sm font-medium mb-2">Email (With Error)</label>
                <.input field={@error_form[:email]} placeholder="Enter your email" />
                <p class="text-sm text-danger-600 mt-1 flex items-center gap-1">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4">
                    <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-5a.75.75 0 01.75.75v4.5a.75.75 0 01-1.5 0v-4.5A.75.75 0 0110 5zM10 15a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
                  </svg>
                  must be a valid email format
                </p>
              </div>
              
              <div>
                <label class="block text-sm font-medium mb-2">Password (With Error)</label>
                <.input field={@error_form[:password]} type="password" placeholder="Enter password" />
                <p class="text-sm text-danger-600 mt-1 flex items-center gap-1">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4">
                    <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-5a.75.75 0 01.75.75v4.5a.75.75 0 01-1.5 0v-4.5A.75.75 0 0110 5zM10 15a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
                  </svg>
                  must be at least 8 characters
                </p>
              </div>
            </div>
          </div>
        </section>
        
        <!-- Input Types Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Input Types</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input type="text" name="text" placeholder="Text input" />
              <.input type="email" name="email" placeholder="Email input" />
              <.input type="password" name="password" placeholder="Password input" />
              <.input type="number" name="number" placeholder="Number input" />
              <.input type="tel" name="tel" placeholder="Phone input" />
              <.input type="url" name="url" placeholder="URL input" />
              <.input type="search" name="search" placeholder="Search input" />
              <.input type="date" name="date" />
            </div>
          </div>
        </section>

        <!-- States Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">States</h2>
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium mb-2">Normal</label>
                <.input name="normal" placeholder="Normal input" />
              </div>
              
              <div>
                <label class="block text-sm font-medium mb-2">Disabled</label>
                <.input name="disabled" placeholder="Disabled input" disabled />
              </div>
              
              <div>
                <label class="block text-sm font-medium mb-2">Read-only</label>
                <.input name="readonly" value="Read-only value" readonly />
              </div>
              
              <div>
                <label class="block text-sm font-medium mb-2">Required</label>
                <.input name="required" placeholder="Required input" required />
              </div>
            </div>
          </div>
        </section>
        
        <!-- Documentation Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Usage</h2>
            <div class="space-y-6">
              <div>
                <h3 class="text-lg font-medium mb-2">Basic Usage</h3>
                <div class="bg-surface dark:bg-dark-surface p-4 rounded-lg border">
                  <pre class="text-sm text-muted dark:text-dark-muted overflow-x-auto"><code>                    # Basic input
                    &lt;.input name="email" placeholder="Enter email" /&gt;

                    # With Phoenix form field (automatic error handling)
                    &lt;.input field=&#123;@form[:email]&#125; /&gt;

                    # With decorators
                    &lt;.input name="price" placeholder="0.00"&gt;
                      &lt;:start_decorator&gt;$&lt;/:start_decorator&gt;
                      &lt;:end_decorator&gt;USD&lt;/:end_decorator&gt;
                    &lt;/.input&gt;</code></pre>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Available Props</h3>
                <div class="bg-surface dark:bg-dark-surface p-4 rounded-lg border">
                  <div class="space-y-2 text-sm">
                    <div><strong>Styling:</strong></div>
                    <ul class="space-y-1 text-muted dark:text-dark-muted ml-4">
                      <li><code>variant</code> - "outline" (default) | "ghost"</li>
                      <li><code>size</code> - "xs" | "sm" | "md" | "lg" | "xl"</li>
                    </ul>
                    <div class="mt-4"><strong>Behavior:</strong></div>
                    <ul class="space-y-1 text-muted dark:text-dark-muted ml-4">
                      <li><code>field</code> - Phoenix form field (automatic error detection)</li>
                      <li><code>type</code> - HTML input type</li>
                      <li><code>disabled</code>, <code>readonly</code>, <code>required</code> - Boolean states</li>
                    </ul>
                    <div class="mt-4"><strong>Note:</strong></div>
                    <p class="text-muted dark:text-dark-muted">No color prop needed - colors are automatic based on state!</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </.catalog_layout>
    """
  end
end