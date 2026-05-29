# Pulsar

Beautiful, accessible Phoenix LiveView components.

> ⚠️ **Early stage — work in progress. Not ready for use.**
>
> Pulsar is being developed in the open. APIs are unstable and will change
> without notice, components are incomplete, and there is no support or
> stability guarantee. **Do not use it in production.** Watch or star the repo
> to follow along.

Pulsar provides styled components with Tailwind CSS, aiming to bake in accessibility and behavior while giving you complete control and customization. This self-contained library is a single dependency by design.

## Features

- 🚀 **Single Dependency** - Only requires [Twm](https://hex.pm/packages/twm) for intelligent Tailwind class merging (Tailwind v4 ready)
- ♿ **Full Accessibility** - WCAG 2.2 AA compliant with proper ARIA attributes and keyboard navigation ([per-component audit](docs/a11y/README.md))
- 🎨 **Tailwind-first** - Styled with Tailwind CSS utilities and semantic color tokens
- 🌙 **Dark mode ready** - Automatic light/dark mode support via CSS custom properties  
- 📚 **Well documented** - TypeScript-like documentation with `:values` validation
- 🚧 **Early stage** - Actively developed; expect breaking changes
- ⚡ **Zero JavaScript** - Pure Phoenix LiveView with colocated hooks when needed
- 🎯 **Semantic colors** - Use `primary`, `success`, `error` instead of `blue-500`, `green-600`
- 🛡️ **Security first** - XSS protection and proper input validation built-in

## Quick Start

Pulsar is **generator-first**: the recommended workflow is to copy component source directly into your Phoenix application using `mix pulsar.install` (and the per-component `mix pulsar.gen.*` tasks). You own the generated code and can modify it freely. Library mode — importing components straight from the Pulsar package — is available but [secondary](#library-mode-secondary).

### Installation

Add Pulsar as a dev dependency to use its generators:

```elixir
# mix.exs
defp deps do
  [
    {:pulsar, "~> 0.1", only: :dev},
    {:twm, "~> 0.1"}
  ]
end
```

```bash
mix deps.get
```

### Generate Components

Run the installer to copy the theme CSS, all components, and a `CoreComponents` aggregate module into your app:

```bash
# Install everything (theme + all components + core_components module)
mix pulsar.install

# Install specific components only
mix pulsar.install --component=button,input,checkbox --no-theme

# Custom module namespace (default: YourAppWeb.Components)
mix pulsar.install --components-module=MyAppWeb.UI

# Auto-confirm all prompts
mix pulsar.install --yes
```

Or generate components individually with `mix pulsar.gen.<component>`:

```bash
mix pulsar.gen.button
mix pulsar.gen.input
mix pulsar.gen.select
mix pulsar.gen.theme
```

After generation, the components live under `lib/your_app_web/components/` and are yours to customize.

### Adding a storybook

Pulsar can also generate [phoenix_storybook](https://hexdocs.pm/phoenix_storybook)
stories for every component you install. Pass `--storybook` to the installer:

```bash
mix pulsar.install --storybook
```

This generates a `lib/<app>_web/storybook/` directory with one story per
installed component, plus foundation pages and example UIs. You will need to
add `phoenix_storybook` to your `mix.exs` and wire it into your router — the
generator prints the exact setup instructions when it finishes.

To add storybook stories after components are already installed:

```bash
mix pulsar.gen.storybook
```

### Use the Generated Components

```elixir
# In your component/LiveView
import YourAppWeb.CoreComponents

# In templates
<.button variant="primary" size="lg" loading={@saving}>
  Save Changes
</.button>

<.label for="email-input">Email Address</.label>
<.input field={@form[:email]} type="email" id="email-input" />

<.label for="category-select">Category</.label>
<.select field={@form[:category]} options={@categories} id="category-select" />
```

### Library Mode (secondary)

If you'd rather not copy source into your app, you can import components directly from the Pulsar package. This trades generator-mode customizability for a smaller diff in your repo, and means you take Pulsar as a runtime dependency rather than a dev-only tool.

```elixir
# mix.exs — promote Pulsar out of `only: :dev`
{:pulsar, "~> 0.1"},
{:twm, "~> 0.1"}
```

```elixir
# Aggregate import
import Pulsar.CoreComponents

# Or granular imports
import Pulsar.Components.{Button, Label, Link, Input, Textarea, Select, Checkbox, Switch, RadioGroup}
```

```heex
<.flash kind={:info} flash={@flash} />
<.button variant="primary">Save</.button>
<.table id="users" rows={@users}>
  <:col :let={user} label="Name">{user.name}</:col>
</.table>
```

## Components

### Core Components (All Available)

**Form Components:**
- **Button** - Interactive buttons with semantic variants (`primary`, `success`, etc.)
- **Input** - Text inputs with validation, decorators, and accessibility
- **Textarea** - Multi-line text inputs with character counting
- **Select** - Dropdown selects with option generation
- **Checkbox** - Checkboxes with card variants and field integration
- **Switch** - Toggle switches with Phoenix form support
- **RadioGroup** - Radio button groups with proper ARIA semantics

**UI Components:**
- **Label** - Semantic labels with error states and accessibility
- **Link** - Navigation links with XSS protection and Phoenix integration

### Examples

```elixir
# Button with loading state
<.button variant="primary" size="lg" loading={@saving}>
  Save Changes
</.button>

# Form input with validation  
<.label for="email-input">Email Address</.label>
<.input field={@form[:email]} type="email" 
        id="email-input"
        placeholder="Enter your email" />

# Select with options
<.label for="role-select">Role</.label>
<.select field={@form[:role]} 
         id="role-select"
         options={[{"Admin", "admin"}, {"User", "user"}]} />

# Checkbox with card styling
<.checkbox field={@form[:terms]} card variant="outline">
  I agree to the terms
</.checkbox>
```

**All components support:**
- Phoenix form integration with `field` attribute
- Full accessibility (ARIA, keyboard navigation)
- Theming via semantic color tokens (light, dark, and custom themes)
- Security features (XSS protection, input validation)
- Custom styling via `class` attribute with intelligent merging

## Theming

Pulsar uses a semantic-token color system built on CSS custom properties.
Components reference semantic names (`bg-primary`, `text-foreground`,
`border-border`) — never raw palette colors like `blue-500`. A theme is one
block of token values, so switching or adding a theme never touches component
code.

The installer generates a three-file layout under `assets/css/`:

```
assets/css/
├── theme.css              # entry: imports Tailwind + the theme files
└── themes/
    ├── light.css          # default semantic tokens
    └── dark.css           # overrides under [data-theme="dark"]
```

### Custom Colors

Override an existing theme by editing the token values in
`assets/css/themes/light.css` (or `dark.css`):

```css
@theme {
  /* Switch primary from blue to indigo */
  --color-primary: var(--color-indigo-500);

  /* Or use a custom OKLCH color */
  --color-primary: oklch(61% 0.24 290);
}
```

Scaffold a brand-new theme with the generator:

```bash
mix pulsar.gen.theme high_contrast
```

This creates `assets/css/themes/high_contrast.css` and wires its import into
`theme.css`. Fill in the token values for your theme.

### Switching themes

Activate a theme by setting `data-theme` (or the matching `theme-*` class) on any
ancestor element — no rebuild needed:

```javascript
// Attribute-based (recommended)
document.documentElement.dataset.theme = "dark";
document.documentElement.dataset.theme = "light";
document.documentElement.dataset.theme = "high_contrast";

// Class-based (compatible with PhoenixStorybook's sandbox_class switcher)
document.documentElement.classList.toggle("theme-dark");
```

## Development

### Testing

```bash
mix test
mix credo
```

### Architecture

Pulsar components are self-contained with inlined accessibility and behavior:

```elixir
def button(assigns) do
  # Normalize Phoenix form field if provided
  normalized_assigns = normalize_field_props(assigns)
  
  # Merge styling classes intelligently
  classes = Twm.merge([
    button_base_classes(),
    variant_classes(assigns.variant), 
    size_classes(assigns.size),
    normalized_assigns.class
  ])

  ~H"""
  <button type="button" class={classes} {...assign_computed_attributes(normalized_assigns)}>
    <%= render_slot(@inner_block) %>
  </button>
  """
end
```

This approach provides:
- **Complete independence** - No external component dependencies
- **Full accessibility** - ARIA attributes, keyboard navigation, screen reader support
- **Intelligent class merging** - Twm prevents style conflicts
- **Phoenix integration** - Seamless form field support with validation
- **Security first** - XSS protection and proper escaping built-in

## Migration Guide

If you were using an older version of Pulsar:

1. **Update imports** - Import directly from `Pulsar.Components.*`
2. **No API changes** - All component APIs remain identical
3. **Clean compilation** - Run `mix deps.get && mix compile --force`

## Roadmap

Pulsar is pre-1.0 and under active development. The checklist below reflects
in-progress work — unchecked items are not built yet, and checked items may
still change as the library stabilizes.

- [x] **Core Form Components** - Button, Input, Textarea, Select, Checkbox, Switch, RadioGroup
- [x] **UI Components** - Label, Link
- [x] **Self-Contained Components** - Zero external dependencies beyond Twm
- [ ] Card component
- [ ] Alert component  
- [ ] Badge component (partial implementation available)
- [ ] Navigation components
- [ ] Data display components
- [ ] Additional themes

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Built with:
- [Twm](https://hex.pm/packages/twm) - Intelligent Tailwind CSS class merging
- [Tailwind CSS](https://tailwindcss.com) - Utility-first CSS framework  
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view) - Rich, interactive web applications

Originally inspired by:
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view) - Rich, interactive web applications

