# ADR-002: Form Component API Design Strategy

**Date**: 2024-12-30
**Status**: Proposed
**Deciders**: Pulsar Development Team
**Technical Story**: [GitHub Issue #19](https://github.com/bigrefactor/pulsar/issues/19) - PRD-001 Form Components Implementation

## Context and Problem Statement

Pulsar needs a consistent API design strategy for form components that balances multiple competing requirements: maintaining Phoenix compatibility for easy adoption, providing enhanced features through compositional patterns, supporting theme customization, and ensuring consistency across all current and future components (not just forms).

### Background

Pulsar provides styled components with built-in accessibility and behavior. The initial implementations (Button, Input, Label, Textarea) have established patterns that need to be formalized before expanding to additional components. The goal is to create a cohesive API that serves as a drop-in replacement for Phoenix's `core_components` while offering advanced capabilities.

### Requirements
- Maintain 100% backward compatibility with Phoenix.Component form helpers
- Support compositional patterns for complex UI needs (addons, decorators, compound components)
- Ensure consistent theming through semantic color tokens and variant system
- Enable progressive enhancement without breaking existing Phoenix forms
- Support both stateless and stateful component patterns where appropriate
- Provide clear migration path with versioned APIs

## Decision Drivers

- **Developer Experience**: API should feel natural to Phoenix developers while offering power features
- **Consistency**: All components (forms and beyond) should follow the same patterns
- **Flexibility**: Support simple use cases elegantly and complex ones without hacks
- **Performance**: Minimize runtime overhead and bundle size
- **Maintainability**: Clear patterns that are easy to extend and debug
- **Versioning**: Ability to evolve the API with major versions while providing upgrade paths

## Considered Options

### Option 1: Pure Wrapper Pattern (Current Approach)
**Description**: Self-contained components with styling and behavior, using slots for composition

**Pros**:
- Clean component architecture with built-in accessibility
- Leverages Phoenix's slot system for maximum flexibility
- Consistent with Phoenix LiveView patterns
- Easy to understand and document

**Cons**:
- Verbose for simple cases (slots for basic addons)
- May require more boilerplate for common patterns
- Slots can't be conditionally rendered as easily as props

**Estimated effort**: S (already implemented for Input/Label/Textarea)

### Option 2: Hybrid Props/Slots Pattern
**Description**: Use props for simple cases, slots for complex composition

**Pros**:
- Optimized for common use cases (icon props, text props)
- Less verbose for simple scenarios
- Still supports complex composition via slots

**Cons**:
- Two ways to do the same thing (confusing)
- Harder to document and maintain
- Prop explosion for edge cases
- Migration complexity when simple becomes complex

**Estimated effort**: M

### Option 3: Context-Aware Composition
**Description**: Components adapt based on content type and context

**Pros**:
- Most intelligent/automatic behavior
- Minimal API surface
- Best developer experience for common cases

**Cons**:
- "Magic" behavior can be confusing
- Harder to debug and test
- Performance overhead from runtime detection
- Less predictable for edge cases

**Estimated effort**: L

### Option 4: Render Function Pattern
**Description**: Props accept functions that return content

**Pros**:
- Maximum flexibility
- Type-safe with proper specs
- Familiar to React developers

**Cons**:
- Not idiomatic in Phoenix/LiveView
- Poor HTML template integration
- Complex for designers to understand
- Performance implications with function calls

**Estimated effort**: M

## Decision Outcome

**Chosen option**: "Option 1: Pure Wrapper Pattern" with standardized conventions

### Rationale

The self-contained component pattern with slots provides the best balance of flexibility, consistency, and Phoenix compatibility. By building components with integrated accessibility and using slots for composition, we maintain clean architecture while leveraging Phoenix's native composition model. This approach is already proven in our Input component implementation and scales well to complex scenarios.

### Implementation Example

```elixir
defmodule Pulsar.Components.Form.Input do
  use Phoenix.Component
  import TailwindMerge, only: [merge: 1]

  # Consistent prop pattern across all components
  attr :variant, :string, default: "solid", values: ~w(outline ghost solid)
  attr :color, :string, default: "neutral", values: ~w(neutral primary secondary success danger warning info)
  attr :size, :string, default: "md", values: ~w(xs sm md lg xl)
  
  # Phoenix compatibility props
  attr :field, FormField, default: nil
  attr :type, :string, default: "text"
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  
  # State management
  attr :invalid, :boolean, default: nil
  attr :disabled, :boolean, default: false
  attr :readonly, :boolean, default: false
  
  # Extensibility
  attr :class, :string, default: ""
  attr :rest, :global
  
  # Compositional slots
  slot :start_decorator, doc: "Leading content"
  slot :end_decorator, doc: "Trailing content"

  def input(assigns) do
    # Automatic error detection from Phoenix forms
    has_errors = has_field_errors(assigns)
    invalid = assigns.invalid || has_errors
    effective_color = if invalid, do: "danger", else: assigns.color
    
    # Class merging with TailwindMerge
    class = merge([
      base_classes(),
      variant_classes(assigns.variant),
      color_classes(assigns.variant, effective_color),
      size_classes(assigns.size),
      assigns.class
    ])
    
    ~H"""
    <div class={class} data-variant={@variant} data-color={@color}>
      <.decorator :if={@start_decorator != []} position="start">
        {render_slot(@start_decorator)}
      </.decorator>
      
      <input
        field={@field}
        type={@type}
        class="input-base-classes"
        invalid={invalid}
        disabled={@disabled}
        {...@rest}
      />
      
      <.decorator :if={@end_decorator != []} position="end">
        {render_slot(@end_decorator)}
      </.decorator>
    </div>
    """
  end
end
```

## Consequences

### Positive
- **Consistency**: All components follow the same wrapper + slots pattern
- **Phoenix Integration**: Drop-in replacement for core_components works seamlessly
- **Flexibility**: Slots enable any level of UI complexity
- **Performance**: No runtime overhead for prop detection or transformation
- **Maintainability**: Self-contained components with clear patterns
- **Documentation**: Single pattern to learn and document

### Negative
- **Verbosity**: Simple cases (single icon) require slot syntax
- **Learning Curve**: Developers must understand slot composition
- **Boilerplate**: More code for basic scenarios compared to prop-based APIs

### Neutral
- **Migration Path**: Requires creating Phoenix adapter module (core_components.ex)
- **Bundle Size**: Each component includes full variant/color matrix
- **Testing**: Need comprehensive tests for all variant/color/size combinations

## Implementation Plan

### Phase 1: Standardize Existing Components
1. Review and align Input, Label, Textarea with documented patterns
2. Create shared utilities module for common functions
3. Document standard prop names and values
4. Add comprehensive tests for API consistency

### Phase 2: Phoenix Adapter Module
1. Create `Pulsar.Components.CoreComponents` module
2. Map Phoenix core_components API to Pulsar components
3. Handle automatic field error extraction
4. Provide migration utilities

### Phase 3: Component Expansion
1. Apply pattern to Select, Checkbox, Radio, Switch
2. Extend to non-form components (Card, Modal, Table)
3. Create component generator with standard template
4. Document patterns in component guide

### Phase 4: Stateful Components
1. Design state management for complex components (typeahead, combobox)
2. Create LiveComponent wrappers where needed
3. Provide hooks for state synchronization
4. Document stateful component patterns

## Migration Strategy

### For Existing Phoenix Apps

```elixir
# Step 1: Install Pulsar
{:pulsar, "~> 1.0"}

# Step 2: Replace core_components import
# Before:
import MyAppWeb.CoreComponents

# After:
import Pulsar.Components.CoreComponents

# Step 3: Progressively adopt Pulsar features
# Phoenix-compatible:
<.input field={@form[:email]} />

# With Pulsar enhancements:
<.input field={@form[:email]} variant="outline" color="primary">
  <:start_decorator><.icon name="hero-envelope" /></:start_decorator>
</.input>
```

### Version Migration
- **1.x**: Current API with slots for composition
- **2.x**: Potential convenience props for common cases (if user feedback indicates need)
- Migration tool to convert between versions
- Deprecation warnings for breaking changes

## Validation

How will we know this decision was correct?

- [ ] All form components can replace Phoenix core_components without code changes
- [ ] Complex UI patterns (search with button, price with currency) are achievable
- [ ] Component API is consistent across all 15+ planned components
- [ ] Developer survey shows 80%+ satisfaction with API design
- [ ] Performance benchmarks show <5% overhead vs raw HTML
- [ ] Migration from core_components takes <1 hour for typical Phoenix app

## Notes

### Research Links
- [Phoenix.Component Documentation](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html)
- [Phoenix LiveView Components](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html)
- [TailwindMerge for Class Resolution](https://github.com/dcastil/tailwind-merge)

### Component Conventions

**Standard Props** (all components):
- `variant`: Visual style (solid, outline, ghost, link)
- `color`: Semantic color (neutral, primary, secondary, success, danger, warning, info)
- `size`: Component size (xs, sm, md, lg, xl)
- `class`: Additional CSS classes
- `rest`: Global attributes pass-through

**Standard Slots** (where applicable):
- `inner_block`: Primary content
- `start_decorator`/`end_decorator`: Compositional addons
- Named slots for specific features

**Error Handling**:
- Automatic from Phoenix changesets when `field` prop is used
- Manual override via `invalid` prop
- Color automatically becomes "danger" when invalid

**Theme Integration**:
- All colors reference semantic tokens from `/themes/pulsar.css`
- Dark mode via `dark:` prefix utilities
- TailwindMerge resolves conflicts

### Related ADRs
- [ADR-001: Theme Design System](/docs/adr/ADR-001-theme-design-system.md) - Semantic color system
- ADR-003: Addon System Implementation (to be created)
- ADR-004: Phoenix Core Components Migration (to be created)

## Status Tracking
- [x] Proposed (2024-12-30)
- [ ] Reviewed
- [ ] Accepted
- [ ] Implemented (GitHub issue #19)