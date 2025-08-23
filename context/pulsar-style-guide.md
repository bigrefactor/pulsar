## Best Practices

### Class Organization
Order classes consistently:

1. Layout (display, position)
2. Spacing (padding, margin)
3. Sizing (width, height)
4. Typography (font, text)
5. Theme colors with light/dark
6. Effects (shadow, opacity)
7. Transitions
8. States (hover, focus)

### Using Theme Colors
Always use semantic theme colors instead of Tailwind's default colors:

```elixir
# Good: Theme colors
<div class="bg-light-background dark:bg-dark-background">
<button class="bg-light-primary dark:bg-dark-primary">

# Avoid: Hard-coded Tailwind colors
<div class="bg-white dark:bg-gray-900">
<button class="bg-blue-600 dark:bg-blue-500">
```

### Composition Over Customization
```elixir
# Good: Compose with utilities
<.button class="rounded-full px-8" />

# Avoid: Custom CSS
<.button style="border-radius: 9999px; padding: 0 2rem;" />
```

### Responsive-First
Always consider mobile:

```elixir
# Good: Mobile-first
class="p-4 sm:p-6 lg:p-8"

# Avoid: Desktop-first
class="p-8 sm:p-6 xs:p-4"
```

### Theme Consistency
Use theme colors consistently across components:

```elixir
# Good: Consistent theme usage
<.card class="bg-light-card dark:bg-dark-card">
  <.button class="bg-light-primary dark:bg-dark-primary">
    Action
  </.button>
</.card>

# Avoid: Mixing theme and non-theme colors
<.card class="bg-light-card dark:bg-dark-card">
  <.button class="bg-blue-600">  # Breaking theme consistency
    Action
  </.button>
</.card>
```# Pulsar Style Guide

A comprehensive guide to building interfaces with Pulsar components and Tailwind CSS.

## Theme System

### Setting Up Themes
Pulsar uses a simple, static theme system through Tailwind configuration:

```javascript
// tailwind.config.js
const lofi = require('@pulsar/themes/lofi')
const dracula = require('@pulsar/themes/dracula')

module.exports = {
  darkMode: 'class',
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

### Using Theme Colors
All Pulsar components use semantic color names with `light-` and `dark-` prefixes:

```html
<!-- Backgrounds -->
<div class="bg-light-background dark:bg-dark-background">

<!-- Text -->
<p class="text-light-foreground dark:text-dark-foreground">

<!-- Borders -->
<div class="border border-light-border dark:border-dark-border">

<!-- Interactive elements -->
<button class="bg-light-primary dark:bg-dark-primary 
               text-light-primary-foreground dark:text-dark-primary-foreground">
```

### Available Semantic Colors
Every Pulsar theme provides these semantic colors:

- `background` - Main background color
- `foreground` - Main text color
- `card` - Card/surface background
- `card-foreground` - Text on cards
- `primary` - Primary brand color
- `primary-foreground` - Text on primary
- `secondary` - Secondary brand color
- `secondary-foreground` - Text on secondary
- `accent` - Accent/highlight color
- `accent-foreground` - Text on accent
- `muted` - Muted backgrounds
- `muted-foreground` - Muted text
- `destructive` - Error/danger color
- `destructive-foreground` - Text on destructive
- `border` - Border color
- `input` - Input border/background
- `ring` - Focus ring color

### Switching Themes
To change themes, simply import different theme packages:

```javascript
// From cupcake + synthwave
const cupcake = require('@pulsar/themes/cupcake')
const synthwave = require('@pulsar/themes/synthwave')

// To corporate + night
const corporate = require('@pulsar/themes/corporate')
const night = require('@pulsar/themes/night')

module.exports = {
  theme: {
    extend: {
      colors: {
        light: corporate.colors,  // Just change the import
        dark: night.colors        // Components automatically update
      }
    }
  }
}
```

## Typography with Tailwind

### Text Sizes
Use Tailwind's text scale consistently:

```elixir
# Display
<h1 class="text-4xl font-bold tracking-tight sm:text-5xl lg:text-6xl">
  Hero Title
</h1>

# Headings
<h2 class="text-2xl font-semibold tracking-tight sm:text-3xl">Section</h2>
<h3 class="text-xl font-semibold sm:text-2xl">Subsection</h3>
<h4 class="text-lg font-medium">Card Title</h4>

# Body
<p class="text-base text-gray-600 dark:text-gray-400">Body text</p>
<p class="text-sm text-gray-500 dark:text-gray-500">Secondary text</p>
<p class="text-xs text-gray-400 dark:text-gray-600">Caption</p>
```

### Font Weights
Consistent weight usage:

- `font-normal` (400): Body text
- `font-medium` (500): Emphasized body, small headers
- `font-semibold` (600): Headers, buttons
- `font-bold` (700): Hero text, important headers

### Line Heights
Following Tailwind's defaults:

- `leading-tight` (1.25): Headers
- `leading-snug` (1.375): Subheaders  
- `leading-normal` (1.5): Body text
- `leading-relaxed` (1.625): Readable paragraphs
- `leading-loose` (2): Spacious text

## Spacing System

### Component Spacing
Standard padding and margin combinations:

```elixir
# Buttons
<.button class="px-4 py-2" />           # Default
<.button class="px-3 py-1.5 text-sm" /> # Small
<.button class="px-6 py-3 text-lg" />   # Large

# Cards
<.card class="p-6 space-y-4" />         # Default padding with vertical spacing

# Form Fields
<div class="space-y-6">                 # Between form fields
  <.input />
  <.input />
</div>

# Sections
<section class="py-12 sm:py-16 lg:py-20" />  # Responsive section padding
```

### Layout Spacing
Common layout patterns:

```elixir
# Page container
<div class="container mx-auto px-4 sm:px-6 lg:px-8">

# Grid gaps
<div class="grid gap-4 sm:gap-6 lg:gap-8">

# Stack spacing
<div class="flex flex-col space-y-4">

# Inline spacing
<div class="flex items-center space-x-2">
```

## Component Patterns

### Buttons
Standard button styles using theme colors:

```elixir
# Primary
<.button class="bg-light-primary dark:bg-dark-primary 
                text-light-primary-foreground dark:text-dark-primary-foreground
                hover:bg-light-primary/90 dark:hover:bg-dark-primary/90
                focus:outline-none focus:ring-2 focus:ring-light-ring dark:focus:ring-dark-ring" />

# Secondary  
<.button class="bg-light-secondary dark:bg-dark-secondary
                text-light-secondary-foreground dark:text-dark-secondary-foreground
                hover:bg-light-secondary/80 dark:hover:bg-dark-secondary/80" />

# Ghost
<.button class="text-light-foreground dark:text-dark-foreground
                hover:bg-light-accent/10 dark:hover:bg-dark-accent/10" />

# Destructive
<.button class="bg-light-destructive dark:bg-dark-destructive
                text-light-destructive-foreground dark:text-dark-destructive-foreground
                hover:bg-light-destructive/90 dark:hover:bg-dark-destructive/90" />

# Sizes with Tailwind classes
<.button class="px-2.5 py-1.5 text-xs" />  # xs
<.button class="px-3 py-2 text-sm" />      # sm  
<.button class="px-4 py-2 text-sm" />      # base
<.button class="px-4 py-2 text-base" />    # lg
<.button class="px-6 py-3 text-base" />    # xl
```

### Cards
Using theme colors for cards:

```elixir
<.card class="bg-light-card dark:bg-dark-card shadow rounded-lg">
  <:header class="px-6 py-4 border-b border-light-border dark:border-dark-border">
    <h3 class="text-lg font-medium text-light-foreground dark:text-dark-foreground">Title</h3>
  </:header>
  <:body class="px-6 py-4 text-light-card-foreground dark:text-dark-card-foreground">
    Content
  </:body>
</.card>
```

### Forms
Form styling with theme colors:

```elixir
# Input fields
<.input class="block w-full rounded-md 
               border-light-input dark:border-dark-input
               bg-light-background dark:bg-dark-background
               text-light-foreground dark:text-dark-foreground
               focus:border-light-primary dark:focus:border-dark-primary
               focus:ring-light-ring dark:focus:ring-dark-ring" />

# Labels
<.label class="block text-sm font-medium 
               text-light-foreground dark:text-dark-foreground">
  Email
</.label>

# Help text
<p class="mt-1 text-sm text-light-muted-foreground dark:text-dark-muted-foreground">
  We'll never share your email.
</p>

# Error messages
<p class="mt-1 text-sm text-light-destructive dark:text-dark-destructive">
  This field is required
</p>
```

## Responsive Design

### Breakpoint Usage
Following Tailwind's mobile-first approach:

```elixir
# Text sizing
<h1 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl">

# Spacing
<div class="p-4 sm:p-6 md:p-8 lg:p-10">

# Grid columns
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">

# Display
<div class="hidden sm:block">        # Hidden on mobile
<div class="block sm:hidden">        # Only on mobile
```

### Container Patterns
Standard responsive containers:

```elixir
# Full-width with padding
<div class="px-4 sm:px-6 lg:px-8">

# Max-width containers
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">     # Standard
<div class="max-w-4xl mx-auto px-4 sm:px-6">             # Narrow
<div class="max-w-2xl mx-auto px-4">                     # Article
```

## Dark Mode

### Theme-Based Dark Mode
Dark mode is handled through the theme system with `dark:` prefixes:

```elixir
# Backgrounds automatically adapt
"bg-light-background dark:bg-dark-background"

# Text colors adapt
"text-light-foreground dark:text-dark-foreground"

# Borders adapt
"border-light-border dark:border-dark-border"
```

### Component Dark Mode Example
```elixir
<.card class="bg-light-card dark:bg-dark-card 
              border border-light-border dark:border-dark-border">
  <:body class="text-light-card-foreground dark:text-dark-card-foreground">
    Content adapts to theme automatically
  </:body>
</.card>
```

### Dark Mode Toggle
```elixir
# Simple class toggle on html/body
def handle_event("toggle_dark_mode", _, socket) do
  {:noreply, 
   socket
   |> push_event("toggle_dark_mode", %{})
  }
end
```

```javascript
// app.js
window.addEventListener("phx:toggle_dark_mode", (e) => {
  document.documentElement.classList.toggle('dark')
  localStorage.setItem('theme', 
    document.documentElement.classList.contains('dark') ? 'dark' : 'light'
  )
})
```

## Interactive States

### Hover States
Using Tailwind's hover utilities:

```elixir
# Elevation on hover
"shadow-sm hover:shadow-md transition-shadow"

# Color change
"bg-gray-50 hover:bg-gray-100"

# Scale
"hover:scale-105 transition-transform"

# Opacity
"opacity-0 hover:opacity-100 transition-opacity"
```

### Focus States
Accessible focus indicators:

```elixir
# Focus ring (primary)
"focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2"

# Focus within
"focus-within:ring-2 focus-within:ring-primary-500"

# Focus visible only
"focus-visible:ring-2 focus-visible:ring-primary-500"
```

### Disabled States
Consistent disabled styling:

```elixir
"disabled:opacity-50 disabled:cursor-not-allowed"
"disabled:bg-gray-100 disabled:text-gray-400"
```

## Animation & Transitions

### Transition Utilities
Standard transitions:

```elixir
# Default transition
"transition-colors duration-200 ease-in-out"

# Multiple properties
"transition-all duration-200 ease-in-out"

# Specific timings
"transition duration-150"        # Fast (dropdowns)
"transition duration-200"        # Default
"transition duration-300"        # Slow (modals)
```

### Animation Classes
Common animations:

```elixir
# Pulse for loading
"animate-pulse"

# Spin for spinners
"animate-spin"

# Bounce for attention
"animate-bounce"

# Custom keyframes in Tailwind config
"animate-slide-in"
"animate-fade-in"
```

## Icons

### Icon Sizing
Consistent icon dimensions:

```elixir
# With text
"h-4 w-4"    # With text-sm
"h-5 w-5"    # With text-base (default)
"h-6 w-6"    # With text-lg

# Standalone
"h-8 w-8"    # Small
"h-10 w-10"  # Medium
"h-12 w-12"  # Large
```

### Icon Spacing
In buttons and links:

```elixir
<.button>
  <.icon name="hero-plus" class="h-5 w-5 -ml-0.5 mr-2" />
  Add Item
</.button>
```

## Accessibility Classes

### Screen Reader Utilities
Using Tailwind's SR utilities:

```elixir
# Visually hidden but screen reader accessible
<span class="sr-only">Loading...</span>

# Focus visible
<button class="focus:not-sr-only">Skip to content</button>
```

### ARIA States
Tailwind's ARIA modifiers:

```elixir
"aria-expanded:rotate-180"           # Rotating chevrons
"aria-selected:bg-primary-50"        # Selected items
"aria-checked:bg-primary-600"        # Checked states
"aria-disabled:opacity-50"           # Disabled elements
```

## Layout Patterns

### Sidebar Layout
```elixir
<div class="flex h-screen bg-gray-50 dark:bg-gray-900">
  <!-- Sidebar -->
  <aside class="w-64 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700">
    <!-- Sidebar content -->
  </aside>
  
  <!-- Main content -->
  <main class="flex-1 overflow-y-auto">
    <div class="p-4 sm:p-6 lg:p-8">
      <!-- Page content -->
    </div>
  </main>
</div>
```

### Dashboard Grid
```elixir
<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
  <!-- Stat cards -->
  <.card class="bg-white dark:bg-gray-800">
    <!-- Card content -->
  </.card>
</div>
```

### Stacked List
```elixir
<ul class="divide-y divide-gray-200 dark:divide-gray-700">
  <li class="py-4 hover:bg-gray-50 dark:hover:bg-gray-800">
    <!-- List item content -->
  </li>
</ul>
```

## Available Themes

### Included Themes
Pulsar ships with several pre-built themes:

**Light Themes:**
- `@pulsar/themes/lofi` - Minimalist black and white
- `@pulsar/themes/cupcake` - Pastel and sweet colors
- `@pulsar/themes/corporate` - Professional blues and grays
- `@pulsar/themes/retro` - Warm, vintage colors
- `@pulsar/themes/garden` - Natural greens

**Dark Themes:**
- `@pulsar/themes/dracula` - Classic Dracula purple theme
- `@pulsar/themes/synthwave` - Neon 80s aesthetic
- `@pulsar/themes/night` - Deep blues and purples
- `@pulsar/themes/black` - True black, OLED-friendly

**Neutral Themes (work for both):**
- `@pulsar/themes/nord` - Nord color palette
- `@pulsar/themes/winter` - Cool blues and grays

### Creating Custom Themes
Create your own theme by providing all semantic colors:

```javascript
// my-custom-theme.js
module.exports = {
  colors: {
    background: '#ffffff',
    foreground: '#171717',
    card: '#ffffff',
    'card-foreground': '#171717',
    primary: '#7c3aed',
    'primary-foreground': '#ffffff',
    secondary: '#f3f4f6',
    'secondary-foreground': '#171717',
    accent: '#7c3aed',
    'accent-foreground': '#ffffff',
    muted: '#f3f4f6',
    'muted-foreground': '#737373',
    destructive: '#ef4444',
    'destructive-foreground': '#ffffff',
    border: '#e5e7eb',
    input: '#e5e7eb',
    ring: '#7c3aed',
  }
}

// Use in tailwind.config.js
const myTheme = require('./my-custom-theme')

module.exports = {
  theme: {
    extend: {
      colors: {
        light: myTheme.colors,
        // dark: ...
      }
    }
  }
}
```

---

*This style guide ensures consistency across all Pulsar components while maintaining full compatibility with Tailwind CSS's utility-first approach.*