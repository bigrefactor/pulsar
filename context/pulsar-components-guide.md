# Pulsar Components Guide

Beautiful, production-ready Phoenix LiveView components that enhance and replace Phoenix's core components.

## Overview

Pulsar provides styled, accessible components that are drop-in replacements for Phoenix's generated core components, plus essential additions for building modern web applications. Every component is built with Tailwind CSS and uses Phoenix.LiveView.JS for interactions.

**Generator-Only Architecture**: Following the shadcn/ui model, Pulsar generates components directly into your Phoenix application instead of providing them as dependencies. This gives you full control, easier customization, and better Tailwind integration.

## Installation

### 1. Setup (One-Time)
```bash
# Install the generator and setup your project
mix pulsar.install
```

This installs the Pulsar theme CSS and configures Tailwind - no dependencies are added.

### 2. Generate Components
```bash
# Generate individual components as needed
mix pulsar.gen.button
mix pulsar.gen.input
mix pulsar.gen.modal
```

Components are generated into `lib/your_app_web/components/` and you own them completely.

### 3. Use Components
```elixir
# Use the generated components in your templates
<.button variant="solid" color="primary">
  Save Changes
</.button>
```

## Component Categories

### Core Components (Phoenix Replacements)
Direct replacements for Phoenix's generated components with professional styling and enhanced features.

### Essential Components
Additional components that Phoenix doesn't include but every application needs.

### SaaS Components (Pro)
Pre-built patterns for SaaS applications including billing, teams, and analytics.

### Application Shells (Pro)
Complete layout patterns for common application screens.

---

## Core Components (Phoenix Replacements)

These components directly replace Phoenix's default generated components with the same API but enhanced styling and features.

### 1. Button
**Replaces**: Phoenix's `.button`  
**Purpose**: Styled button with multiple variants and states

```elixir
<.button variant="primary" size="md" icon="hero-plus">
  Add Item
</.button>

<.button variant="destructive" loading={@deleting}>
  Delete
</.button>
```

**Variants**: `primary`, `secondary`, `ghost`, `destructive`, `outline`  
**Sizes**: `xs`, `sm`, `md`, `lg`, `xl`  
**Features**: Loading state, disabled state, icon support, full width option

### 2. Input
**Replaces**: Phoenix's `.input`  
**Purpose**: Styled text input with validation states

```elixir
<.input 
  field={@form[:email]} 
  type="email" 
  placeholder="Enter your email"
  icon="hero-envelope"
/>
```

**Types**: All HTML5 input types  
**Features**: Leading/trailing icons, validation styling, disabled state, sizes

### 3. Label
**Replaces**: Phoenix's `.label`  
**Purpose**: Form labels with required indicators

```elixir
<.label for={@form[:email]} required>
  Email Address
</.label>
```

**Features**: Required asterisk, helper text, error state integration

### 4. Error
**Replaces**: Phoenix's `.error`  
**Purpose**: Field error messages with icons

```elixir
<.error field={@form[:email]} />
```

**Features**: Icon display, smooth animation on appearance, multiple error support

### 5. Simple Form
**Replaces**: Phoenix's `.simple_form`  
**Purpose**: Enhanced form wrapper with consistent spacing

```elixir
<.simple_form for={@form} phx-change="validate" phx-submit="save">
  <.field_group>
    <.label for={@form[:name]}>Name</.label>
    <.input field={@form[:name]} />
    <.error field={@form[:name]} />
  </.field_group>
  
  <.form_actions>
    <.button type="submit" variant="primary">Save</.button>
  </.form_actions>
</.simple_form>
```

**Features**: Automatic spacing, loading states, error summary, sections

### 6. Textarea
**Replaces**: Phoenix's textarea input type  
**Purpose**: Styled multiline text input

```elixir
<.textarea 
  field={@form[:description]} 
  rows="4"
  character_count
  max_length="500"
/>
```

**Features**: Auto-resize option, character count, validation states

### 7. Select
**Replaces**: Phoenix's select input type  
**Purpose**: Styled native select element

```elixir
<.select field={@form[:country]} options={@countries} prompt="Choose a country" />
```

**Features**: Grouped options, disabled options, icons, sizes

### 8. Checkbox
**Replaces**: Phoenix's checkbox input type  
**Purpose**: Styled checkbox with label

```elixir
<.checkbox field={@form[:terms_accepted]}>
  I agree to the terms and conditions
</.checkbox>
```

**Features**: Indeterminate state, custom colors, sizes, help text

### 9. Radio
**Replaces**: Phoenix's radio input type  
**Purpose**: Styled radio button group

```elixir
<.radio_group field={@form[:plan]} options={[
  {"Free", "free"},
  {"Pro - $9/mo", "pro"},
  {"Team - $29/mo", "team"}
]} />
```

**Features**: Horizontal/vertical layout, descriptions, disabled options

### 10. Field Group
**New**: Composition helper  
**Purpose**: Groups label, input, and error together

```elixir
<.field_group>
  <.label for={@form[:email]}>Email</.label>
  <.input field={@form[:email]} type="email" />
  <.error field={@form[:email]} />
  <.field_hint>We'll never share your email.</.field_hint>
</.field_group>
```

**Features**: Consistent spacing, optional hint text, required indicators

### 11. Form Actions
**New**: Form button group  
**Purpose**: Consistent form action button layout

```elixir
<.form_actions>
  <.button variant="ghost">Cancel</.button>
  <.button type="submit" variant="primary">Save Changes</.button>
</.form_actions>
```

**Features**: Alignment options, spacing, responsive layout

### 12. Flash
**Replaces**: Phoenix's `.flash` and `.flash_group`  
**Purpose**: Styled flash messages with auto-dismiss

```elixir
<.flash kind={:info} title="Success!" phx-click="lv:clear-flash">
  Your changes have been saved.
</.flash>

<.flash_group flash={@flash} />
```

**Features**: Icons per type, auto-dismiss timer, actions, close button

### 13. Link
**Replaces**: Phoenix's `.link`  
**Purpose**: Styled links with variants

```elixir
<.link navigate={~p"/users"} variant="primary">
  View all users
</.link>

<.link href="https://example.com" target="_blank" variant="underline">
  External link
</.link>
```

**Variants**: `primary`, `secondary`, `underline`, `hover-underline`  
**Features**: External link icon, active state, disabled state

### 14. Back
**Replaces**: Phoenix's `.back`  
**Purpose**: Back navigation with icon

```elixir
<.back navigate={~p"/users"}>
  Back to users
</.back>
```

**Features**: Customizable icon, keyboard shortcut support

### 15. Table
**Replaces**: Phoenix's `.table`  
**Purpose**: Styled responsive table

```elixir
<.table rows={@users}>
  <:col :let={user} label="Name">
    <%= user.name %>
  </:col>
  <:col :let={user} label="Email">
    <%= user.email %>
  </:col>
  <:action :let={user}>
    <.link navigate={~p"/users/#{user}"}>Edit</.link>
  </:action>
</.table>
```

**Features**: Responsive scroll, sortable columns, row hover, striped rows, empty state

### 16. List
**Replaces**: Phoenix's `.list`  
**Purpose**: Key-value list display

```elixir
<.list>
  <.list_item title="Name">
    <%= @user.name %>
  </.list_item>
  <.list_item title="Email">
    <%= @user.email %>
  </.list_item>
</.list>
```

**Features**: Horizontal/vertical layout, dividers, icons, copyable values

### 17. Header
**Replaces**: Phoenix's `.header`  
**Purpose**: Page and section headers

```elixir
<.header>
  <:title>Users</:title>
  <:subtitle>Manage your application users</:subtitle>
  <:actions>
    <.button variant="primary">Add User</.button>
  </:actions>
</.header>
```

**Features**: Breadcrumb support, actions alignment, back button integration

### 18. Modal
**Replaces**: Phoenix's `.modal`  
**Purpose**: Production-ready modal dialog

```elixir
<.modal id="user-modal">
  <:title>Edit User</:title>
  <:description>Update the user information below</:description>
  <:body>
    <!-- Modal content -->
  </:body>
  <:footer>
    <.button phx-click={JS.hide(to: "#user-modal")}>Cancel</.button>
    <.button variant="primary">Save</.button>
  </:footer>
</.modal>
```

**Features**: Size variants, close button, backdrop click, ESC key, focus trap

---

## Essential Components

Components that Phoenix doesn't include but are essential for modern applications.

### 19. Navbar
**Purpose**: Application navigation bar

```elixir
<.navbar>
  <:brand>
    <img src="/logo.svg" /> MyApp
  </:brand>
  <:nav>
    <.navbar_item navigate={~p"/dashboard"} active>Dashboard</.navbar_item>
    <.navbar_item navigate={~p"/users"}>Users</.navbar_item>
  </:nav>
  <:actions>
    <.user_menu user={@current_user} />
  </:actions>
</.navbar>
```

**Features**: Mobile responsive, dropdown menus, search integration, sticky option

### 20. Sidebar
**Purpose**: Collapsible sidebar navigation

```elixir
<.sidebar collapsible>
  <:header>
    <img src="/logo.svg" />
  </:header>
  <:nav>
    <.sidebar_item navigate={~p"/dashboard"} icon="hero-home" active>
      Dashboard
    </.sidebar_item>
    <.sidebar_item navigate={~p"/users"} icon="hero-users">
      Users
    </.sidebar_item>
  </:nav>
  <:footer>
    <.sidebar_item icon="hero-cog">Settings</.sidebar_item>
  </:footer>
</.sidebar>
```

**Features**: Collapse to icons, nested items, badges, tooltips when collapsed

### 21. Breadcrumb
**Purpose**: Navigation path display

```elixir
<.breadcrumb>
  <.breadcrumb_item navigate={~p"/"}>Home</.breadcrumb_item>
  <.breadcrumb_item navigate={~p"/users"}>Users</.breadcrumb_item>
  <.breadcrumb_item current>John Doe</.breadcrumb_item>
</.breadcrumb>
```

**Features**: Custom separator, icons, responsive truncation

### 22. Tabs
**Purpose**: Tabbed content navigation

```elixir
<.tabs default_value="general">
  <:list>
    <.tab value="general">General</.tab>
    <.tab value="security">Security</.tab>
    <.tab value="billing" badge="New">Billing</.tab>
  </:list>
  <:panel value="general">
    <!-- General settings content -->
  </:panel>
  <:panel value="security">
    <!-- Security settings content -->
  </:panel>
</.tabs>
```

**Features**: Icons, badges, disabled tabs, vertical layout, URL sync

### 23. Pagination
**Purpose**: Page navigation controls

```elixir
<.pagination 
  current_page={@page}
  total_pages={@total_pages}
  path={~p"/users"}
/>
```

**Features**: Page size selector, jump to page, responsive design, customizable labels

### 24. Card
**Purpose**: Content container

```elixir
<.card>
  <:header>
    <.card_title>Revenue</.card_title>
    <.dropdown>
      <:trigger><.button variant="ghost" size="sm">•••</.button></:trigger>
      <!-- Options -->
    </.dropdown>
  </:header>
  <:body>
    <!-- Card content -->
  </:body>
  <:footer>
    <.link variant="primary" size="sm">View details</.link>
  </:footer>
</.card>
```

**Features**: Loading state, collapsible, hover effects, click handler

### 25. Stats Card
**Purpose**: Metric display card

```elixir
<.stats_card
  title="Total Revenue"
  value="$12,345"
  change="+12.5%"
  trend="up"
  icon="hero-currency-dollar"
/>
```

**Features**: Trend indicators, sparkline support, comparison values

### 26. Empty State
**Purpose**: No content placeholder

```elixir
<.empty_state
  icon="hero-users"
  title="No users yet"
  description="Get started by creating your first user."
>
  <.button variant="primary">Add User</.button>
</.empty_state>
```

**Features**: Custom illustrations, actions, sizes

### 27. Alert
**Purpose**: Inline notifications

```elixir
<.alert variant="warning" dismissible>
  <:title>Payment Required</:title>
  <:description>
    Your trial ends in 3 days. Upgrade to continue.
  </:description>
  <:actions>
    <.button size="sm" variant="primary">Upgrade</.button>
  </:actions>
</.alert>
```

**Variants**: `info`, `success`, `warning`, `error`  
**Features**: Icons, dismissible, actions, compact mode

### 28. Badge
**Purpose**: Status indicators and counts

```elixir
<.badge variant="success">Active</.badge>
<.badge variant="error" dot>Offline</.badge>
<.badge count={99} max={99} />
```

**Variants**: `default`, `success`, `warning`, `error`, `info`  
**Features**: Dot indicator, count display, removable, sizes

### 29. Progress
**Purpose**: Progress indicators

```elixir
<.progress value={@progress} max={100} />
<.progress indeterminate />
```

**Features**: Labels, colors, sizes, striped animation, circular variant

### 30. Spinner
**Purpose**: Loading indicator

```elixir
<.spinner size="md" />
<.spinner text="Loading..." />
```

**Features**: Sizes, custom text, colors

### 31. Skeleton
**Purpose**: Loading placeholder

```elixir
<.skeleton class="h-12 w-full" />
<.skeleton variant="text" lines={3} />
<.skeleton variant="avatar" />
```

**Variants**: `text`, `avatar`, `card`, `table`  
**Features**: Animation, custom shapes

### 32. Dropdown
**Purpose**: Actions menu

```elixir
<.dropdown>
  <:trigger>
    <.button variant="outline">Options</.button>
  </:trigger>
  <:item icon="hero-pencil" phx-click="edit">Edit</:item>
  <:item icon="hero-duplicate" phx-click="duplicate">Duplicate</:item>
  <:separator />
  <:item icon="hero-trash" variant="danger" phx-click="delete">Delete</:item>
</.dropdown>
```

**Features**: Icons, keyboard navigation, submenus, disabled items

### 33. Tooltip
**Purpose**: Hover information

```elixir
<.tooltip content="This action cannot be undone">
  <.button variant="destructive">Delete</.button>
</.tooltip>
```

**Features**: Positions, delays, arrow, max width

### 34. Command Palette
**Purpose**: ⌘K command menu

```elixir
<.command_palette 
  commands={@commands}
  placeholder="Type a command or search..."
  hotkey="cmd+k"
/>
```

**Features**: Fuzzy search, categories, shortcuts, recent commands

### 35. Search
**Purpose**: Search input with results

```elixir
<.search
  phx-change="search"
  phx-debounce="300"
  results={@search_results}
  searching={@searching}
/>
```

**Features**: Debouncing, loading state, results dropdown, filters

---

## SaaS Components (Pro)

Premium components for SaaS applications.

### Authentication Components

#### 36. Auth Card
**Purpose**: Login/signup card layout

```elixir
<.auth_card title="Sign in to your account">
  <.simple_form for={@form} phx-submit="login">
    <!-- Form fields -->
  </.simple_form>
  <:footer>
    Don't have an account? <.link navigate={~p"/signup"}>Sign up</.link>
  </:footer>
</.auth_card>
```

#### 37. Social Button
**Purpose**: OAuth login buttons

```elixir
<.social_button provider="google" phx-click="oauth_login">
  Continue with Google
</.social_button>
```

### User Management

#### 38. Avatar
**Purpose**: User profile images

```elixir
<.avatar src={@user.avatar_url} alt={@user.name} size="lg" status="online" />
<.avatar initials="JD" size="sm" />
```

#### 39. User Menu
**Purpose**: User account dropdown

```elixir
<.user_menu user={@current_user}>
  <:item navigate={~p"/profile"}>Profile</:item>
  <:item navigate={~p"/settings"}>Settings</:item>
  <:separator />
  <:item phx-click="logout">Sign out</:item>
</.user_menu>
```

### Billing Components

#### 40. Pricing Card
**Purpose**: Pricing tier display

```elixir
<.pricing_card
  name="Pro"
  price="$29"
  period="month"
  features={@pro_features}
  highlighted
>
  <.button variant="primary" class="w-full">Get Started</.button>
</.pricing_card>
```

#### 41. Usage Meter
**Purpose**: Usage/quota display

```elixir
<.usage_meter
  label="API Calls"
  used={8500}
  limit={10000}
  unit="requests"
/>
```

### Data Components

#### 42. Data Table
**Purpose**: Advanced table with sorting/filtering

```elixir
<.data_table
  rows={@users}
  columns={@columns}
  sortable
  filterable
  selectable
  phx-change="filter"
/>
```

**Features**: Column sorting, filters, bulk actions, pagination, export

---

## Application Shells (Pro)

Complete layout patterns for common screens.

### 43. Dashboard Shell
**Purpose**: Full dashboard layout

```elixir
<.dashboard_shell current_user={@current_user}>
  <:sidebar>
    <.sidebar>
      <!-- Navigation -->
    </.sidebar>
  </:sidebar>
  <:header>
    <.header>
      <:title>Dashboard</:title>
    </.header>
  </:header>
  <:content>
    <!-- Page content -->
  </:content>
</.dashboard_shell>
```

### 44. Settings Shell
**Purpose**: Settings page layout

```elixir
<.settings_shell>
  <:sidebar>
    <.settings_nav active="general" />
  </:sidebar>
  <:content>
    <!-- Settings forms -->
  </:content>
</.settings_shell>
```

---

## Installation & Usage

### Installation

```bash
# Add to mix.exs
{:pulsar, "~> 1.0"}

# Install
mix deps.get
mix pulsar.install
```

### Replacing Phoenix Core Components

```bash
# Replace all core components
mix pulsar.replace_core_components

# Or selectively
mix pulsar.gen.component button --replace-core
```

### Generating Components

```bash
# Generate individual components
mix pulsar.gen.component card
mix pulsar.gen.component navbar

# Generate component sets
mix pulsar.gen.set forms
mix pulsar.gen.set navigation
```

### Configuration

```elixir
# config/config.exs
config :pulsar,
  theme: "default",
  dark_mode: true,
  icon_library: :heroicons
```

## Component Conventions

### Naming
- Components use snake_case: `.button`, `.stats_card`
- Variants use atoms: `variant="primary"`, `size="lg"`
- Boolean props are atoms: `loading`, `dismissible`

### Styling
- All components use Tailwind classes
- Dark mode supported via `dark:` prefix
- Responsive design via `sm:`, `md:`, `lg:` prefixes
- Custom classes merge with defaults

### Accessibility
- All components meet WCAG 2.1 AA standards
- Keyboard navigation supported
- Screen reader optimized
- Focus indicators included

### Icons
- Heroicons by default
- Configurable icon library
- Consistent sizing with components

---

*Pulsar provides everything you need to build beautiful Phoenix LiveView applications, from basic forms to complete SaaS interfaces.*