defmodule Pulsar.Storybook.InputLive do
  @moduledoc """
  Phoenix LiveView component for showcasing Pulsar input components.

  Demonstrates all variants, colors, sizes, decorator patterns, and states 
  of the input component with interactive examples and code snippets.
  """

  use Phoenix.LiveView
  import Pulsar.Components.Input
  import Pulsar.Storybook.CatalogLayout

  def mount(_params, _session, socket) do
    # Create form changeset for demonstration
    form =
      to_form(
        %{
          "email" => "",
          "password" => "",
          "website" => "",
          "amount" => "",
          "search" => "",
          "phone" => "",
          "username" => "",
          "bio" => "",
          "location" => "",
          "price" => "",
          "discount" => "",
          "api_key" => "",
          "error_field" => ""
        },
        as: "demo"
      )

    {:ok,
     assign(socket,
       selected_component: "input",
       page_title: "Input Component",
       form: form
     )}
  end

  def render(assigns) do
    ~H"""
    <.catalog_layout selected_component={@selected_component}>
      <div class="max-w-4xl mx-auto space-y-12">
        <div>
          <h1 class="text-3xl font-bold mb-2">Input</h1>
          <p class="text-muted dark:text-dark-muted">
            Accessible input component with decorator support, Phoenix form integration, and comprehensive theming.
          </p>
        </div>
        
    <!-- Variants Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Variants</h2>
            <div class="space-y-4">
              <div>
                <h3 class="text-lg font-medium mb-2">Solid</h3>
                <div class="space-y-3">
                  <.input variant="solid" name="solid_default" placeholder="Default solid input" />
                  <.input
                    variant="solid"
                    color="primary"
                    name="solid_primary"
                    placeholder="Primary solid input"
                  />
                  <.input
                    variant="solid"
                    color="info"
                    name="solid_info"
                    placeholder="Info solid input"
                  />
                  <.input
                    variant="solid"
                    color="success"
                    name="solid_success"
                    placeholder="Success solid input"
                  />
                  <.input
                    variant="solid"
                    color="warning"
                    name="solid_warning"
                    placeholder="Warning solid input"
                  />
                  <.input
                    variant="solid"
                    color="secondary"
                    name="solid_secondary"
                    placeholder="Secondary solid input"
                  />
                  <.input
                    variant="solid"
                    color="danger"
                    name="solid_danger"
                    placeholder="Danger solid input"
                  />
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Outline</h3>
                <div class="space-y-3">
                  <.input
                    variant="outline"
                    name="outline_default"
                    placeholder="Default outline input"
                  />
                  <.input
                    variant="outline"
                    color="primary"
                    name="outline_primary"
                    placeholder="Primary outline input"
                  />

                  <.input
                    variant="outline"
                    color="secondary"
                    name="outline_secondary"
                    placeholder="Secondary outline input"
                  />

                  <.input
                    variant="outline"
                    color="info"
                    name="outline_info"
                    placeholder="Info outline input"
                  />

                  <.input
                    variant="outline"
                    color="success"
                    name="outline_success"
                    placeholder="Success outline input"
                  />
                  <.input
                    variant="outline"
                    color="warning"
                    name="outline_warning"
                    placeholder="Warning outline input"
                  />
                  <.input
                    variant="outline"
                    color="danger"
                    name="outline_danger"
                    placeholder="Danger outline input"
                  />
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Ghost</h3>
                <div class="space-y-3">
                  <.input variant="ghost" name="ghost_default" placeholder="Default ghost input" />
                  <.input
                    variant="ghost"
                    color="primary"
                    name="ghost_primary"
                    placeholder="Primary ghost input"
                  />
                  <.input
                    variant="ghost"
                    color="secondary"
                    name="ghost_secondary"
                    placeholder="Secondary ghost input"
                  />
                  <.input
                    variant="ghost"
                    color="info"
                    name="ghost_info"
                    placeholder="Info ghost input"
                  />
                  <.input
                    variant="ghost"
                    color="success"
                    name="ghost_success"
                    placeholder="Success ghost input"
                  />
                  <.input
                    variant="ghost"
                    color="warning"
                    name="ghost_warning"
                    placeholder="Warning ghost input"
                  />
                  <.input
                    variant="ghost"
                    color="danger"
                    name="ghost_danger"
                    placeholder="Danger ghost input"
                  />
                </div>
              </div>
            </div>
          </div>
        </section>
        
    <!-- Sizes Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Sizes</h2>
            <div class="space-y-4">
              <div class="space-y-3">
                <.input size="xs" name="size_xs" placeholder="Extra small input" />
                <.input size="sm" name="size_sm" placeholder="Small input" />
                <.input size="md" name="size_md" placeholder="Medium input (default)" />
                <.input size="lg" name="size_lg" placeholder="Large input" />
                <.input size="xl" name="size_xl" placeholder="Extra large input" />
              </div>
            </div>
          </div>
        </section>
        
    <!-- Decorators Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Decorators</h2>
            <div class="space-y-4">
              <div>
                <h3 class="text-lg font-medium mb-2">Start Decorators</h3>
                <div class="space-y-3">
                  <.input name="email_with_icon" placeholder="Enter email">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path d="M3 4a2 2 0 00-2 2v1.161l8.441 4.221a1.25 1.25 0 001.118 0L19 7.162V6a2 2 0 00-2-2H3z" />
                        <path d="M19 8.839l-7.77 3.885a2.75 2.75 0 01-2.46 0L1 8.839V14a2 2 0 002 2h14a2 2 0 002-2V8.839z" />
                      </svg>
                    </:start_decorator>
                  </.input>

                  <.input name="url_with_text" placeholder="Enter your website">
                    <:start_decorator>https://</:start_decorator>
                  </.input>

                  <.input name="phone_with_code" placeholder="Phone number">
                    <:start_decorator>+1</:start_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">End Decorators</h3>
                <div class="space-y-3">
                  <.input name="search_with_icon" placeholder="Search...">
                    <:end_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:end_decorator>
                  </.input>

                  <.input name="domain_with_suffix" placeholder="yourcompany">
                    <:end_decorator>.com</:end_decorator>
                  </.input>

                  <.input name="price_with_currency" placeholder="0.00">
                    <:end_decorator>USD</:end_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Both Decorators</h3>
                <div class="space-y-3">
                  <.input name="price_full" placeholder="0.00">
                    <:start_decorator>$</:start_decorator>
                    <:end_decorator>USD</:end_decorator>
                  </.input>

                  <.input name="percentage" placeholder="0">
                    <:start_decorator>Discount</:start_decorator>
                    <:end_decorator>%</:end_decorator>
                  </.input>

                  <.input name="api_key" placeholder="Enter API key">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M8 7a5 5 0 113.61 4.804l-1.903 1.903A1 1 0 019 14H8v1a1 1 0 01-1 1H6v1a1 1 0 01-1 1H3a1 1 0 01-1-1v-2a1 1 0 01.293-.707L8.196 8.39A5.002 5.002 0 018 7zm5-3a.75.75 0 000 1.5A1.5 1.5 0 0114.5 7 .75.75 0 0016 7a3 3 0 00-3-3z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:start_decorator>
                    <:end_decorator>
                      <button
                        type="button"
                        class="text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 text-sm font-medium"
                      >
                        Copy
                      </button>
                    </:end_decorator>
                  </.input>
                </div>
              </div>
            </div>
          </div>
        </section>
        
    <!-- Ghost Variant with Decorators Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Ghost Variant with Decorators</h2>
            <div class="space-y-4">
              <div>
                <h3 class="text-lg font-medium mb-2">Ghost Start Decorators</h3>
                <div class="space-y-3">
                  <.input variant="ghost" name="ghost_email_icon" placeholder="Enter email">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path d="M3 4a2 2 0 00-2 2v1.161l8.441 4.221a1.25 1.25 0 001.118 0L19 7.162V6a2 2 0 00-2-2H3z" />
                        <path d="M19 8.839l-7.77 3.885a2.75 2.75 0 01-2.46 0L1 8.839V14a2 2 0 002 2h14a2 2 0 002-2V8.839z" />
                      </svg>
                    </:start_decorator>
                  </.input>

                  <.input variant="ghost" name="ghost_url_prefix" placeholder="Enter your website">
                    <:start_decorator>https://</:start_decorator>
                  </.input>

                  <.input variant="ghost" name="ghost_phone_code" placeholder="Phone number">
                    <:start_decorator>+1</:start_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Ghost End Decorators</h3>
                <div class="space-y-3">
                  <.input variant="ghost" name="ghost_search_icon" placeholder="Search...">
                    <:end_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:end_decorator>
                  </.input>

                  <.input variant="ghost" name="ghost_domain_suffix" placeholder="yourcompany">
                    <:end_decorator>.com</:end_decorator>
                  </.input>

                  <.input variant="ghost" name="ghost_currency" placeholder="0.00">
                    <:end_decorator>USD</:end_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Ghost Both Decorators</h3>
                <div class="space-y-3">
                  <.input variant="ghost" name="ghost_price_full" placeholder="0.00">
                    <:start_decorator>$</:start_decorator>
                    <:end_decorator>USD</:end_decorator>
                  </.input>

                  <.input variant="ghost" name="ghost_percentage" placeholder="0">
                    <:start_decorator>Discount</:start_decorator>
                    <:end_decorator>%</:end_decorator>
                  </.input>

                  <.input variant="ghost" name="ghost_api_key" placeholder="Enter API key">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M8 7a5 5 0 113.61 4.804l-1.903 1.903A1 1 0 019 14H8v1a1 1 0 01-1 1H6v1a1 1 0 01-1 1H3a1 1 0 01-1-1v-2a1 1 0 01.293-.707L8.196 8.39A5.002 5.002 0 018 7zm5-3a.75.75 0 000 1.5A1.5 1.5 0 0114.5 7 .75.75 0 0016 7a3 3 0 00-3-3z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:start_decorator>
                    <:end_decorator>
                      <button
                        type="button"
                        class="text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 text-sm font-medium"
                      >
                        Copy
                      </button>
                    </:end_decorator>
                  </.input>
                </div>
              </div>
            </div>
          </div>
        </section>
        
    <!-- States Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">States</h2>
            <div class="space-y-4">
              <div>
                <h3 class="text-lg font-medium mb-2">Input States</h3>
                <div class="space-y-3">
                  <.input name="normal_state" placeholder="Normal state" />
                  <.input name="disabled_state" placeholder="Disabled state" disabled={true} />
                  <.input name="readonly_state" value="Read-only value" readonly={true} />
                  <.input name="required_state" placeholder="Required field" required={true} />
                </div>
              </div>
            </div>
          </div>
        </section>
        
    <!-- Phoenix Form Integration Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Phoenix Form Integration</h2>
            <div class="space-y-4">
              <div>
                <h3 class="text-lg font-medium mb-2">Form Fields</h3>
                <div class="space-y-3">
                  <.input field={@form[:email]} type="email" placeholder="Email address" />
                  <.input field={@form[:password]} type="password" placeholder="Password" />
                  <.input field={@form[:username]} placeholder="Username" />
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">With Decorators</h3>
                <div class="space-y-3">
                  <.input field={@form[:website]} placeholder="yourwebsite.com">
                    <:start_decorator>https://</:start_decorator>
                  </.input>

                  <.input field={@form[:phone]} placeholder="555-0100">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M2 3.5A1.5 1.5 0 013.5 2h1.148a1.5 1.5 0 011.465 1.175l.716 3.223a1.5 1.5 0 01-1.052 1.767l-.933.267c-.41.117-.643.555-.48.95a11.542 11.542 0 006.254 6.254c.395.163.833-.07.95-.48l.267-.933a1.5 1.5 0 011.767-1.052l3.223.716A1.5 1.5 0 0118 15.352V16.5a1.5 1.5 0 01-1.5 1.5H15c-1.149 0-2.263-.15-3.326-.43A13.022 13.022 0 012.43 8.326 13.019 13.019 0 012 5V3.5z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:start_decorator>
                  </.input>

                  <.input field={@form[:price]} placeholder="0.00">
                    <:start_decorator>$</:start_decorator>
                    <:end_decorator>USD</:end_decorator>
                  </.input>
                </div>
              </div>
            </div>
          </div>
        </section>
        
    <!-- Input Types Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Input Types</h2>
            <div class="space-y-4">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <.input type="text" name="type_text" placeholder="Text input" />
                <.input type="email" name="type_email" placeholder="email@example.com" />
                <.input type="password" name="type_password" placeholder="Password" />
                <.input type="number" name="type_number" placeholder="123" />
                <.input type="tel" name="type_tel" placeholder="+1 (555) 000-0000" />
                <.input type="url" name="type_url" placeholder="https://example.com" />
                <.input type="search" name="type_search" placeholder="Search..." />
                <.input type="date" name="type_date" />
                <.input type="time" name="type_time" />
                <.input type="datetime-local" name="type_datetime" />
              </div>
            </div>
          </div>
        </section>
        
    <!-- Complex Examples Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Complex Examples</h2>
            <div class="space-y-4">
              <div>
                <h3 class="text-lg font-medium mb-2">Search with Clear Button</h3>
                <div class="space-y-3">
                  <.input variant="outline" name="search_clear" placeholder="Search products...">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:start_decorator>
                    <:end_decorator>
                      <button
                        type="button"
                        class="text-muted hover:text-foreground dark:text-dark-muted dark:hover:text-dark-foreground"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 20 20"
                          fill="currentColor"
                          class="w-5 h-5"
                        >
                          <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
                        </svg>
                      </button>
                    </:end_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Password with Toggle</h3>
                <div class="space-y-3">
                  <.input type="password" name="password_toggle" placeholder="Enter password">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M10 1a4.5 4.5 0 00-4.5 4.5V9H5a2 2 0 00-2 2v6a2 2 0 002 2h10a2 2 0 002-2v-6a2 2 0 00-2-2h-.5V5.5A4.5 4.5 0 0010 1zm3 8V5.5a3 3 0 10-6 0V9h6z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:start_decorator>
                    <:end_decorator>
                      <button
                        type="button"
                        class="text-muted hover:text-foreground dark:text-dark-muted dark:hover:text-dark-foreground"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 20 20"
                          fill="currentColor"
                          class="w-5 h-5"
                        >
                          <path d="M10 12.5a2.5 2.5 0 100-5 2.5 2.5 0 000 5z" />
                          <path
                            fill-rule="evenodd"
                            d="M.664 10.59a1.651 1.651 0 010-1.186A10.004 10.004 0 0110 3c4.257 0 7.893 2.66 9.336 6.41.147.381.146.804 0 1.186A10.004 10.004 0 0110 17c-4.257 0-7.893-2.66-9.336-6.41zM14 10a4 4 0 11-8 0 4 4 0 018 0z"
                            clip-rule="evenodd"
                          />
                        </svg>
                      </button>
                    </:end_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Credit Card Input</h3>
                <div class="space-y-3">
                  <.input name="credit_card" placeholder="4242 4242 4242 4242">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M2.5 4A1.5 1.5 0 001 5.5V6h18v-.5A1.5 1.5 0 0017.5 4h-15zM19 8.5H1v6A1.5 1.5 0 002.5 16h15a1.5 1.5 0 001.5-1.5v-6zM3 13.25a.75.75 0 01.75-.75h1.5a.75.75 0 010 1.5h-1.5a.75.75 0 01-.75-.75zm4.75-.75a.75.75 0 000 1.5h3.5a.75.75 0 000-1.5h-3.5z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:start_decorator>
                    <:end_decorator>
                      <span class="text-muted dark:text-dark-muted text-sm">VISA</span>
                    </:end_decorator>
                  </.input>
                </div>
              </div>
            </div>
          </div>
        </section>
        
    <!-- Color Variants with Decorators Section -->
        <section class="space-y-8">
          <div>
            <h2 class="text-xl font-semibold mb-6">Color Variants with Decorators</h2>
            <div class="space-y-4">
              <div>
                <h3 class="text-lg font-medium mb-2">Primary Color with Decorators</h3>
                <div class="space-y-3">
                  <.input variant="solid" color="primary" name="primary_email" placeholder="Enter email">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path d="M3 4a2 2 0 00-2 2v1.161l8.441 4.221a1.25 1.25 0 001.118 0L19 7.162V6a2 2 0 00-2-2H3z" />
                        <path d="M19 8.839l-7.77 3.885a2.75 2.75 0 01-2.46 0L1 8.839V14a2 2 0 002 2h14a2 2 0 002-2V8.839z" />
                      </svg>
                    </:start_decorator>
                  </.input>

                  <.input variant="outline" color="primary" name="primary_price" placeholder="0.00">
                    <:start_decorator>$</:start_decorator>
                    <:end_decorator>USD</:end_decorator>
                  </.input>

                  <.input variant="ghost" color="primary" name="primary_search" placeholder="Search...">
                    <:end_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:end_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Secondary Color with Decorators</h3>
                <div class="space-y-3">
                  <.input variant="solid" color="secondary" name="secondary_url" placeholder="Enter website">
                    <:start_decorator>https://</:start_decorator>
                  </.input>

                  <.input variant="outline" color="secondary" name="secondary_phone" placeholder="Phone number">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M2 3.5A1.5 1.5 0 013.5 2h1.148a1.5 1.5 0 011.465 1.175l.716 3.223a1.5 1.5 0 01-1.052 1.767l-.933.267c-.41.117-.643.555-.48.95a11.542 11.542 0 006.254 6.254c.395.163.833-.07.95-.48l.267-.933a1.5 1.5 0 011.767-1.052l3.223.716A1.5 1.5 0 0118 15.352V16.5a1.5 1.5 0 01-1.5 1.5H15c-1.149 0-2.263-.15-3.326-.43A13.022 13.022 0 012.43 8.326 13.019 13.019 0 012 5V3.5z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:start_decorator>
                  </.input>

                  <.input variant="ghost" color="secondary" name="secondary_domain" placeholder="yourcompany">
                    <:end_decorator>.com</:end_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Info Color with Decorators</h3>
                <div class="space-y-3">
                  <.input variant="solid" color="info" name="info_api" placeholder="Enter API key">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M8 7a5 5 0 113.61 4.804l-1.903 1.903A1 1 0 019 14H8v1a1 1 0 01-1 1H6v1a1 1 0 01-1 1H3a1 1 0 01-1-1v-2a1 1 0 01.293-.707L8.196 8.39A5.002 5.002 0 018 7zm5-3a.75.75 0 000 1.5A1.5 1.5 0 0114.5 7 .75.75 0 0016 7a3 3 0 00-3-3z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:start_decorator>
                  </.input>

                  <.input variant="outline" color="info" name="info_percentage" placeholder="0">
                    <:start_decorator>Progress</:start_decorator>
                    <:end_decorator>%</:end_decorator>
                  </.input>

                  <.input variant="ghost" color="info" name="info_username" placeholder="Username">
                    <:start_decorator>@</:start_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Success Color with Decorators</h3>
                <div class="space-y-3">
                  <.input variant="solid" color="success" name="success_amount" placeholder="0.00">
                    <:start_decorator>$</:start_decorator>
                    <:end_decorator>
                      <span class="text-sm">Saved</span>
                    </:end_decorator>
                  </.input>

                  <.input variant="outline" color="success" name="success_verified" placeholder="Verified email">
                    <:end_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:end_decorator>
                  </.input>

                  <.input variant="ghost" color="success" name="success_complete" placeholder="Task completed">
                    <:start_decorator>✓</:start_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Warning Color with Decorators</h3>
                <div class="space-y-3">
                  <.input variant="solid" color="warning" name="warning_expiry" placeholder="MM/YY">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:start_decorator>
                    <:end_decorator>Expires</:end_decorator>
                  </.input>

                  <.input variant="outline" color="warning" name="warning_limit" placeholder="0">
                    <:start_decorator>Limit</:start_decorator>
                    <:end_decorator>/100</:end_decorator>
                  </.input>

                  <.input variant="ghost" color="warning" name="warning_pending" placeholder="Pending review">
                    <:end_decorator>⏳</:end_decorator>
                  </.input>
                </div>
              </div>

              <div>
                <h3 class="text-lg font-medium mb-2">Danger Color with Decorators</h3>
                <div class="space-y-3">
                  <.input variant="solid" color="danger" name="danger_delete" placeholder="Type DELETE to confirm">
                    <:start_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:start_decorator>
                  </.input>

                  <.input variant="outline" color="danger" name="danger_error" placeholder="Fix error">
                    <:end_decorator>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        class="w-5 h-5"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-5a.75.75 0 01.75.75v4.5a.75.75 0 01-1.5 0v-4.5A.75.75 0 0110 5zm0 10a1 1 0 100-2 1 1 0 000 2z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </:end_decorator>
                  </.input>

                  <.input variant="ghost" color="danger" name="danger_blocked" placeholder="Access denied">
                    <:start_decorator>🚫</:start_decorator>
                  </.input>
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
