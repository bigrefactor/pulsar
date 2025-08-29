# Pulsar Design Principles

## Core Philosophy
Pulsar extends Tailwind CSS's utility-first approach into the LiveView ecosystem, providing accessible, composable components that embrace both Tailwind's design system and Phoenix's server-first architecture.

## 1. Utility-First, Component-Second
**We build on Tailwind's utility classes, not against them.**

- Components are thin wrappers around Tailwind utilities
- Custom styles are the exception, not the rule
- Variants map directly to Tailwind class combinations
- Theme customization happens through Tailwind config
- Component props translate to utility classes

*Example: Our button variants are simply predefined Tailwind class combinations that can be overridden with the `class` prop.*

```elixir
<.button variant="primary" class="rounded-full" />
# Merges: "bg-blue-600 hover:bg-blue-700" + "rounded-full"
```

## 2. Embrace Tailwind's Design System
**We don't reinvent what Tailwind already solved.**

- Use Tailwind's default spacing scale (0.5, 1, 1.5, 2, 2.5, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 72, 80, 96)
- Leverage Tailwind's color palette (50-950 shades)
- Respect Tailwind's breakpoint system (sm, md, lg, xl, 2xl)
- Follow Tailwind's shadow and radius scales
- Use Tailwind's typography plugin patterns

*Example: `spacing-4` always means `1rem` because we use Tailwind's scale.*

## 3. Pure Phoenix Patterns
**Zero external JavaScript dependencies.**

- Phoenix.LiveView.JS commands for all interactions
- LiveView streams for real-time updates
- Phoenix.HTML.Form integration built-in
- Changesets and error handling as first-class citizens
- No npm, no node_modules, just Phoenix

*Example: Our dropdown uses `JS.toggle()` and `JS.set_attribute()` for open/close state with pure Phoenix commands.*

## 4. Composition Through Slots
**Phoenix components with Tailwind flexibility.**

```elixir
<.card>
  <:header class="bg-gray-50">
    Title
  </:header>
  <:body class="space-y-4">
    Content
  </:body>
</.card>
```

- Named slots for structure
- Class props for customization
- Tailwind utilities for styling
- Merge strategies for flexibility

## 5. Accessible by Default
**ARIA attributes and keyboard navigation aren't optional.**

- Semantic HTML elements always
- ARIA labels computed automatically
- Focus management built into components
- Keyboard shortcuts follow conventions
- Screen reader tested

*Example: Modals trap focus, announce themselves, and handle Escape—no configuration needed.*

## 6. Theme System Through Tailwind Config
**Themes are just Tailwind color configurations.**

- Themes defined as simple JavaScript objects
- Light and dark themes configured in Tailwind config
- No runtime switching, no CSS variables
- Components use `light-` and `dark-` prefixed colors
- Switch themes by changing imports

*Example: Change from a minimalist theme to a colorful theme by just changing which theme file you import in tailwind.config.js.*

```javascript
// Simple theme switching
const lofi = require('@pulsar/themes/lofi')
const dracula = require('@pulsar/themes/dracula')

module.exports = {
  theme: {
    extend: {
      colors: {
        light: lofi.colors,
        dark: dracula.colors
      }
    }
  }
}
```

## 7. Responsive by Design
**Mobile-first, just like Tailwind.**

- Components accept responsive prop variants
- Breakpoint prefixes work on component props
- Container queries where appropriate
- Touch-friendly by default
- Viewport-aware positioning

*Example:*
```elixir
<.button size="sm md:base lg:lg" />
# Small on mobile, base on tablet, large on desktop
```

## 8. Zero Runtime Styles
**If it's not in your Tailwind build, it's not in your bundle.**

- No runtime CSS generation
- All styles are purgeable
- Component styles are Tailwind classes
- Custom CSS is discouraged
- Build-time optimization via Tailwind

## 9. Progressive Enhancement with Phoenix
**Works without JavaScript, better with Phoenix JS commands.**

- Core functionality server-rendered
- Phoenix.LiveView.JS for local interactions
- No external JavaScript libraries
- LiveView for real-time features
- Graceful degradation

*Example: Modals use `JS.show()` and `JS.hide()` with CSS transitions, falling back to server-side navigation if JS is disabled.*

## 10. Copy-Paste Friendly
**Following the shadcn/ui model.**

- Components generated into your app
- Full source control
- Modify without fear
- No version lock-in
- Learn by reading

*Example: `mix pulsar.gen.component button` creates `components/ui/button.ex` in your project.*

## Design Token Integration

### Semantic Color System
We use semantic color names that adapt to themes:

```elixir
# Component uses semantic colors
<.button class="bg-light-primary dark:bg-dark-primary 
                text-light-primary-foreground dark:text-dark-primary-foreground">

# Actual colors depend on theme choice:
# lofi theme: black button with white text
# cupcake theme: pink button with white text
# corporate theme: blue button with white text
```

### Required Semantic Colors
Every theme must provide:
- `background` / `foreground` - Main colors
- `card` / `card-foreground` - Surface colors
- `primary` / `primary-foreground` - Brand colors
- `secondary` / `secondary-foreground` - Supporting colors
- `accent` / `accent-foreground` - Highlight colors
- `muted` / `muted-foreground` - De-emphasized colors
- `destructive` / `destructive-foreground` - Error/danger colors
- `border`, `input`, `ring` - UI element colors

### Theme Flexibility
```javascript
// Mix any light theme with any dark theme
colors: {
  light: cupcake.colors,    // Pastel light theme
  dark: synthwave.colors    // Neon dark theme
}
```

## Component Design Patterns

### Three Levels of Customization

1. **Theme Selection**: Choose your themes
   ```javascript
   // tailwind.config.js
   colors: {
     light: lofi.colors,
     dark: dracula.colors
   }
   ```

2. **Component Variants**: Predefined combinations
   ```elixir
   <.button variant="ghost" size="sm" />
   ```

3. **Utility Classes**: Instance overrides
   ```elixir
   <.button class="shadow-xl hover:scale-105" />
   ```

### Class Composition Strategy
Components use semantic theme colors:

```elixir
# Base component definition
def button(assigns) do
  ~H"""
  <button class={[
    # Semantic theme colors
    "bg-light-primary dark:bg-dark-primary",
    "text-light-primary-foreground dark:text-dark-primary-foreground",
    "hover:bg-light-primary/90 dark:hover:bg-dark-primary/90",
    
    # Standard Tailwind utilities
    "px-4 py-2 rounded-md font-medium",
    "transition-colors duration-200",
    
    # User overrides
    @class
  ]}>
    <%= render_slot(@inner_block) %>
  </button>
  """
end
```

## What Pulsar Doesn't Do

- **No custom design system**: We use Tailwind's
- **No CSS-in-JS**: We use utility classes
- **No runtime styles**: Everything is build-time
- **No style props**: Use classes instead
- **No theme provider**: Use Tailwind config
- **No custom breakpoints**: Use Tailwind's

## Generator Philosophy

Our generators follow Phoenix conventions:

```bash
# Generate into your app, not node_modules
mix pulsar.gen.component button
mix pulsar.gen.layout sidebar
mix pulsar.gen.theme dark
```

Each generated component:
1. Lives in your codebase
2. Uses your Tailwind config
3. Can be modified freely
4. Includes usage examples
5. Has test templates

## Development Workflow

1. **Configure Tailwind** with your design tokens
2. **Generate components** you need
3. **Customize** with utility classes
4. **Extend** through composition
5. **Optimize** with Tailwind's purge

## Performance Principles

- **PurgeCSS compatible**: Unused styles removed
- **No runtime overhead**: Classes resolved at build
- **No JavaScript dependencies**: Only Phoenix's built-in JS
- **Server-rendered**: Initial HTML is complete
- **Streaming updates**: LiveView for real-time

## Phoenix JS Commands Philosophy

Pulsar leverages Phoenix's built-in JS command system for all client-side interactions:

```elixir
# Toggle dropdown
JS.toggle(to: "#dropdown-menu")
|> JS.set_attribute({"aria-expanded", "true"}, to: "#dropdown-button")

# Show modal with animation
JS.show(
  to: "#modal",
  transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
)

# Complex interactions without external dependencies
JS.push("select_item")
|> JS.hide(to: "#dropdown")
|> JS.dispatch("item-selected", detail: %{id: item_id})
```

Benefits of Phoenix-only approach:
- **No build complexity**: No npm, webpack, or JavaScript tooling
- **Smaller bundle**: Only Phoenix's minimal JS runtime
- **Consistent API**: One way to handle interactions
- **Server authority**: State remains server-side
- **Better testing**: Test through LiveView, not JavaScript

## Contributing Guidelines

When creating Pulsar components:

1. **Start with HTML + Tailwind classes**
2. **Extract to Phoenix component**
3. **Add slots for flexibility**
4. **Document class combinations**
5. **Provide variant presets**
6. **Test accessibility**
7. **Include usage examples**

---

*Pulsar bridges the gap between Tailwind's utility-first CSS and Phoenix's component-first architecture, giving you the best of both worlds.*