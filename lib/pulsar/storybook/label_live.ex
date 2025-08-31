defmodule Pulsar.Storybook.LabelLive do
  @moduledoc """
  Phoenix LiveView storybook page for the Pulsar Label component.

  Demonstrates all label variants, sizes, states, and usage patterns with form fields.
  """

  use Phoenix.LiveView
  import Pulsar.Storybook.CatalogLayout
  import Pulsar.Components.Label
  import Pulsar.Components.Input

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Label Component",
       selected_component: "label"
     )}
  end

  def render(assigns) do
    ~H"""
    <.catalog_layout selected_component={@selected_component}>
      <div class="space-y-12">
        <!-- Header -->
        <div>
          <h1 class="text-3xl font-bold text-foreground dark:text-dark-foreground mb-4">
            Label Component
          </h1>
          <p class="text-lg text-muted-foreground dark:text-dark-muted-foreground mb-6">
            Styled label component with typography variants, visual indicators, and form integration.
          </p>
        </div>

        <!-- Size Variants -->
        <section>
          <h2 class="text-2xl font-semibold mb-6">Size Variants</h2>
          <p class="text-muted-foreground mb-4">
            Labels are available in five sizes to match corresponding input components.
          </p>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div class="space-y-3">
              <h3 class="font-medium text-sm text-muted-foreground uppercase tracking-wide">
                Extra Small
              </h3>
              <div class="space-y-2">
                <.label for="xs-demo" size="xs">Extra Small Label</.label>
                <.input id="xs-demo" type="text" size="xs" placeholder="XS input" />
              </div>
              <pre class="text-xs bg-surface-1 dark:bg-dark-surface-1 p-2 rounded overflow-x-auto"><code>&lt;.label for="field" size="xs"&gt;
                Extra Small Label
              &lt;/.label&gt;</code></pre>
            </div>

            <div class="space-y-3">
              <h3 class="font-medium text-sm text-muted-foreground uppercase tracking-wide">
                Small
              </h3>
              <div class="space-y-2">
                <.label for="sm-demo" size="sm">Small Label</.label>
                <.input id="sm-demo" type="text" size="sm" placeholder="SM input" />
              </div>
              <pre class="text-xs bg-surface-1 dark:bg-dark-surface-1 p-2 rounded overflow-x-auto"><code>&lt;.label for="field" size="sm"&gt;
                Small Label
              &lt;/.label&gt;</code></pre>
            </div>

            <div class="space-y-3">
              <h3 class="font-medium text-sm text-muted-foreground uppercase tracking-wide">
                Medium (Default)
              </h3>
              <div class="space-y-2">
                <.label for="md-demo" size="md">Medium Label</.label>
                <.input id="md-demo" type="text" size="md" placeholder="MD input" />
              </div>
              <pre class="text-xs bg-surface-1 dark:bg-dark-surface-1 p-2 rounded overflow-x-auto"><code>&lt;.label for="field"&gt;
                Medium Label
              &lt;/.label&gt;</code></pre>
            </div>

            <div class="space-y-3">
              <h3 class="font-medium text-sm text-muted-foreground uppercase tracking-wide">
                Large
              </h3>
              <div class="space-y-2">
                <.label for="lg-demo" size="lg">Large Label</.label>
                <.input id="lg-demo" type="text" size="lg" placeholder="LG input" />
              </div>
              <pre class="text-xs bg-surface-1 dark:bg-dark-surface-1 p-2 rounded overflow-x-auto"><code>&lt;.label for="field" size="lg"&gt;
                Large Label
              &lt;/.label&gt;</code></pre>
            </div>

            <div class="space-y-3">
              <h3 class="font-medium text-sm text-muted-foreground uppercase tracking-wide">
                Extra Large
              </h3>
              <div class="space-y-2">
                <.label for="xl-demo" size="xl">Extra Large Label</.label>
                <.input id="xl-demo" type="text" size="xl" placeholder="XL input" />
              </div>
              <pre class="text-xs bg-surface-1 dark:bg-dark-surface-1 p-2 rounded overflow-x-auto"><code>&lt;.label for="field" size="xl"&gt;
                Extra Large Label
              &lt;/.label&gt;</code></pre>
            </div>
          </div>
        </section>

        <!-- Required States -->
        <section>
          <h2 class="text-2xl font-semibold mb-6">Required States</h2>
          <p class="text-muted-foreground mb-4">
            Labels can display required (*) indicators for clear form guidance.
          </p>
          <div class="space-y-6">
            <div class="max-w-md space-y-4">
              <h3 class="text-lg font-medium">Required Field Examples</h3>
              <div class="space-y-4">
                <div class="space-y-2">
                  <.label for="email-required" required>Email Address</.label>
                  <.input id="email-required" type="email" placeholder="Enter your email" />
                </div>
                <div class="space-y-2">
                  <.label for="password-required" required size="lg">Password</.label>
                  <.input id="password-required" type="password" size="lg" placeholder="Enter password" />
                </div>
                <div class="space-y-2">
                  <.label for="confirm-required" required size="sm">Confirm Password</.label>
                  <.input id="confirm-required" type="password" size="sm" placeholder="Confirm password" />
                </div>
              </div>
              <pre class="text-xs bg-surface-1 dark:bg-dark-surface-1 p-3 rounded overflow-x-auto"><code>&lt;.label for="email" required&gt;
                Email Address
              &lt;/.label&gt;</code></pre>
            </div>
          </div>
        </section>

        <!-- Error States -->
        <section>
          <h2 class="text-2xl font-semibold mb-6">Error States</h2>
          <p class="text-muted-foreground mb-4">
            Labels automatically coordinate with form validation errors to provide clear visual feedback.
          </p>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div class="space-y-4">
              <h3 class="text-lg font-medium">Normal State</h3>
              <div class="space-y-2">
                <.label for="normal-email">Email Address</.label>
                <.input id="normal-email" type="email" placeholder="Enter your email" />
              </div>
              <div class="space-y-2">
                <.label for="normal-required" required>Required Field</.label>
                <.input id="normal-required" type="text" placeholder="Enter value" />
              </div>
            </div>

            <div class="space-y-4">
              <h3 class="text-lg font-medium">Error State</h3>
              <div class="space-y-2">
                <.label for="error-email" error>Email Address</.label>
                <.input id="error-email" type="email" placeholder="Enter your email" color="danger" />
                <p class="text-sm text-danger dark:text-dark-danger">Please enter a valid email address</p>
              </div>
              <div class="space-y-2">
                <.label for="error-required" error required>Required Field</.label>
                <.input id="error-required" type="text" placeholder="Enter value" color="danger" />
                <p class="text-sm text-danger dark:text-dark-danger">This field is required</p>
              </div>
            </div>
          </div>
          <pre class="text-xs bg-surface-1 dark:bg-dark-surface-1 p-3 rounded overflow-x-auto"><code>&lt;.label for="field" error&gt;
            Error Field
          &lt;/.label&gt;</code></pre>
        </section>

        <!-- Form Integration -->
        <section>
          <h2 class="text-2xl font-semibold mb-6">Form Integration</h2>
          <p class="text-muted-foreground mb-4">
            Labels integrate seamlessly with Phoenix forms and other input types.
          </p>
          <div class="max-w-md space-y-4">
            <div class="space-y-2">
              <.label for="username-form" required>Username</.label>
              <.input id="username-form" type="text" placeholder="Enter username" />
            </div>

            <div class="space-y-2">
              <.label for="email-form" required>Email</.label>
              <.input id="email-form" type="email" placeholder="Enter email" />
            </div>

            <div class="space-y-2">
              <.label for="phone-form">Phone Number</.label>
              <.input id="phone-form" type="tel" placeholder="+1 (555) 123-4567" />
            </div>

            <div class="space-y-2">
              <.label for="message-form" size="lg">Message</.label>
              <textarea 
                id="message-form" 
                rows="4" 
                placeholder="Enter your message..."
                class="w-full px-3 py-2 border rounded-md"
              ></textarea>
            </div>
          </div>
          <pre class="text-xs bg-surface-1 dark:bg-dark-surface-1 p-3 rounded overflow-x-auto"><code>&lt;.label for="username" required&gt;
            Username
          &lt;/.label&gt;
          &lt;.input id="username" type="text" /&gt;</code></pre>
        </section>

        <!-- Custom Styling -->
        <section>
          <h2 class="text-2xl font-semibold mb-6">Custom Styling</h2>
          <p class="text-muted-foreground mb-4">
            Labels accept custom CSS classes and additional HTML attributes for flexibility.
          </p>
          <div class="space-y-4">
            <div class="space-y-2">
              <.label for="custom-1" class="mb-3 font-bold">Custom Styled Label</.label>
              <.input id="custom-1" type="text" placeholder="Custom styling" />
            </div>

            <div class="space-y-2">
              <.label for="custom-2" class="text-primary dark:text-dark-primary" size="lg" required>
                Branded Label
              </.label>
              <.input id="custom-2" type="text" placeholder="Branded input" />
            </div>

            <div class="space-y-2">
              <.label for="custom-3" id="custom-label-id" data-test="label">
                Label with Custom Attributes
              </.label>
              <.input id="custom-3" type="text" placeholder="Custom attributes" />
            </div>
          </div>
          <pre class="text-xs bg-surface-1 dark:bg-dark-surface-1 p-3 rounded overflow-x-auto"><code>&lt;.label 
            for="field" 
            class="custom-class"
            id="custom-id"
            data-test="value"
          &gt;
            Custom Label
          &lt;/.label&gt;</code></pre>
        </section>

        <!-- API Reference -->
        <section>
          <h2 class="text-2xl font-semibold mb-6">API Reference</h2>
          <div class="bg-surface-1 dark:bg-dark-surface-1 rounded-lg p-6">
            <h3 class="text-lg font-medium mb-4">Props</h3>
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead>
                  <tr class="border-b border-border dark:border-dark-border">
                    <th class="text-left py-2 pr-4">Prop</th>
                    <th class="text-left py-2 pr-4">Type</th>
                    <th class="text-left py-2 pr-4">Default</th>
                    <th class="text-left py-2">Description</th>
                  </tr>
                </thead>
                <tbody class="space-y-2">
                  <tr>
                    <td class="py-2 pr-4 font-mono text-xs">for</td>
                    <td class="py-2 pr-4 text-muted-foreground">string</td>
                    <td class="py-2 pr-4 text-muted-foreground">required</td>
                    <td class="py-2">ID of the associated input element</td>
                  </tr>
                  <tr>
                    <td class="py-2 pr-4 font-mono text-xs">required</td>
                    <td class="py-2 pr-4 text-muted-foreground">boolean</td>
                    <td class="py-2 pr-4 text-muted-foreground">false</td>
                    <td class="py-2">Show required indicator (*)</td>
                  </tr>
                  <tr>
                    <td class="py-2 pr-4 font-mono text-xs">error</td>
                    <td class="py-2 pr-4 text-muted-foreground">boolean</td>
                    <td class="py-2 pr-4 text-muted-foreground">false</td>
                    <td class="py-2">Apply error state styling</td>
                  </tr>
                  <tr>
                    <td class="py-2 pr-4 font-mono text-xs">size</td>
                    <td class="py-2 pr-4 text-muted-foreground">string</td>
                    <td class="py-2 pr-4 text-muted-foreground">"md"</td>
                    <td class="py-2">Size variant: xs, sm, md, lg, xl</td>
                  </tr>
                  <tr>
                    <td class="py-2 pr-4 font-mono text-xs">class</td>
                    <td class="py-2 pr-4 text-muted-foreground">string</td>
                    <td class="py-2 pr-4 text-muted-foreground">""</td>
                    <td class="py-2">Additional CSS classes</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </section>
      </div>
    </.catalog_layout>
    """
  end
end