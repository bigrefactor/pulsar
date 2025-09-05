# PRD-001: Styled Form Components with Phoenix Compatibility

## Introduction/Overview

This PRD defines the implementation of styled form components for the Pulsar design system, providing self-contained components with built-in accessibility. These components will provide a drop-in replacement for Phoenix's generated `core_components` with enhanced features, beautiful styling, and complete theme integration. The goal is to give Phoenix developers production-ready form components that work seamlessly with existing Phoenix patterns while offering advanced capabilities like compositional addons, dark mode support, and semantic theming.

## GitHub Hierarchy Context

- **Type**: Feature level PRD (main issue with sub-issues for individual components)
- **Parent**: Standalone feature within the Pulsar component system
- **Sub-issues**: Each form component (Input, Label, Textarea, etc.) will be a GitHub sub-issue

## Goals

1. **Phoenix Compatibility**: Provide 100% API compatibility with Phoenix 1.7+ generated form components while adding enhanced features
2. **Beautiful Defaults**: Deliver production-ready styling that works out of the box with zero configuration
3. **Developer Experience**: Enable Phoenix developers to adopt Pulsar forms with minimal code changes
4. **Theme Integration**: Full support for Pulsar's semantic color system and automatic dark mode
5. **Accessibility**: Maintain WCAG 2.1 AA compliance through proper component implementation

## User Stories

1. **As a Phoenix developer**, I want to replace my generated `core_components` with Pulsar forms so that my application has professional styling without custom CSS work.

2. **As a Phoenix developer**, I want to use the same form helper API I'm familiar with so that I don't need to rewrite existing forms.

3. **As a UI developer**, I want compositional addon support so that I can build complex input patterns (search with icon, price with currency, etc.) easily.

4. **As a product owner**, I want consistent form styling across the application so that users have a cohesive experience.

5. **As a developer**, I want automatic dark mode support so that my forms look great in both light and dark themes without additional work.

## Functional Requirements

1. **Core Component Implementation**
   - The system must provide Input, Label, and Textarea components as the initial release
   - Each component must be self-contained with built-in accessibility
   - Components must maintain full WCAG 2.1 AA compliance

2. **Phoenix API Compatibility**
   - Components must support all existing Phoenix.Component form attributes
   - The `field` attribute must work with Phoenix.HTML.Form structs
   - Error extraction from changesets must work automatically
   - The `for` attribute must properly associate labels with inputs

3. **Enhanced Features**
   - Components must support variant props (default, filled, outlined, error)
   - Size variants must be available (xs, sm, md, lg, xl)
   - Components must support the `class` attribute for custom styling overrides
   - TailwindMerge must resolve class conflicts intelligently

4. **Compositional Addon System**
   - Input components must support leading and trailing slots
   - Any component or element must be usable as an addon
   - Addons must maintain proper spacing and alignment
   - Icon addons must size automatically based on input size

5. **Theme Integration**
   - Components must use Pulsar's semantic color tokens (primary, secondary, success, etc.)
   - Dark mode must activate via `data-theme="dark"` attribute
   - Focus rings must use theme colors
   - Error states must use danger/error semantic colors

6. **Error Handling**
   - Components must display changeset errors automatically when using `field`
   - Error messages must appear below inputs with proper styling
   - Error states must update input border colors and focus rings
   - Multiple errors must display as a list

7. **Migration Path**
   - A migration guide must document the upgrade process from core_components
   - Common patterns must have documented equivalents
   - Breaking changes (if any) must be clearly identified

## Non-Goals (Out of Scope)

1. **JavaScript Components**: This PRD does not include JavaScript-heavy components like date pickers or rich text editors
2. **Validation Logic**: Client-side validation beyond HTML5 attributes is not included
3. **Form Submission**: Handling form submission logic remains the developer's responsibility
4. **File Upload UI**: Complex file upload interfaces are not part of this initial release
5. **Non-Phoenix Usage**: Optimizing for non-Phoenix Elixir frameworks is not a goal

## Design Considerations

### Visual Design
- Follow Pulsar's established design language with rounded corners, subtle shadows, and smooth transitions
- Maintain consistent spacing using Tailwind's spacing scale
- Use semantic colors for interactive states (hover, focus, active)
- Ensure sufficient contrast ratios for accessibility

### Component Structure
```elixir
# Example usage maintaining Phoenix compatibility
<.simple_form for={@form} phx-change="validate" phx-submit="save">
  <.input field={@form[:email]} type="email" label="Email" />
  <.input field={@form[:password]} type="password" label="Password" />
  
  # Enhanced with Pulsar features
  <.input field={@form[:search]} variant="outlined" size="lg">
    <:leading>
      <.icon name="hero-magnifying-glass" />
    </:leading>
  </.input>
</.simple_form>
```

### Responsive Behavior
- Components must be mobile-first and responsive
- Touch targets must meet minimum size requirements (44x44px)
- Form layouts must stack appropriately on small screens

## Technical Considerations

### Phoenix Context
- Components will live in `Pulsar.Components.Form` module
- Each component will be a separate submodule (Form.Input, Form.Label, etc.)
- Components will use Phoenix.Component macros and conventions

### LiveView Integration
- Components must work in both LiveView and dead views
- Phoenix.LiveView.JS commands for interactions must be supported
- Real-time validation feedback must be possible

### Database Considerations
- No database changes required (purely UI components)

### Architectural Decisions Needed
- **ADR needed**: Form component API design strategy → `/docs/adr/ADR-002-form-component-api.md`
- **ADR needed**: Addon system implementation approach → `/docs/adr/ADR-003-addon-system.md`
- **ADR needed**: Phoenix core_components migration strategy → `/docs/adr/ADR-004-core-components-migration.md`

## Success Metrics

1. **Developer Adoption**
   - Successful integration in Pulsar showcase application
   - Positive community feedback on ease of use
   - Adoption in at least 3 real Phoenix applications within first month

2. **Migration Ease**
   - 90% of existing Phoenix forms work with simple import change
   - Migration guide covers all common patterns
   - Zero breaking changes for basic form usage

3. **Design Consistency**
   - All form components follow Pulsar theme system
   - Consistent spacing, typography, and interaction patterns
   - Professional appearance in both light and dark modes

4. **Performance**
   - No measurable performance degradation vs core_components
   - Efficient Tailwind class usage (no class bloat)
   - Proper tree-shaking of unused component code

## Implementation Breakdown

### Phase 1: Core Components (Priority)
- [ ] Create `Pulsar.Components.Form.Input` with built-in accessibility (#sub-issue-1)
  - [ ] Basic input with all Phoenix.Component attributes
  - [ ] Variant support (default, filled, outlined, error)
  - [ ] Size variants (xs, sm, md, lg, xl)
  - [ ] Compositional addon system with leading/trailing slots
  - [ ] Error state styling and message display
  
- [ ] Create `Pulsar.Components.Form.Label` with built-in accessibility (#sub-issue-2)
  - [ ] Typography variants matching input sizes
  - [ ] Required indicator support
  - [ ] Helper text styling
  - [ ] Proper `for` attribute handling
  
- [ ] Create `Pulsar.Components.Form.Textarea` component (#sub-issue-3)
  - [ ] Multi-line input with consistent styling
  - [ ] Auto-resize capability
  - [ ] Character count display option
  - [ ] Same variant and size system as Input

- [ ] Create migration guide documentation (#sub-issue-4)
  - [ ] Step-by-step migration from core_components
  - [ ] Common pattern translations
  - [ ] Troubleshooting guide

### Phase 2: Extended Components (Future)
- [ ] Select component with custom styling
- [ ] Checkbox with custom design
- [ ] Radio group with card layouts
- [ ] Switch toggle component
- [ ] Form wrapper with field groups

### Phase 3: Generator Integration (Future)
- [ ] mix pulsar.gen.form task implementation
- [ ] Template generation system
- [ ] core_components.ex update logic

## Related Documents

### Architecture Decision Records (To Be Created)
- ADR needed: Form component API design strategy → `/docs/adr/ADR-002-form-component-api.md`
- ADR needed: Addon system implementation approach → `/docs/adr/ADR-003-addon-system.md`
- ADR needed: Phoenix core_components migration strategy → `/docs/adr/ADR-004-core-components-migration.md`

### Related PRDs
- Future PRD: Advanced Form Components (Select, Checkbox, Radio, Switch)
- Future PRD: Form Generator System

### External References
- [Phoenix.Component Documentation](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html)
- [Phoenix LiveView Components](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html)
- [Pulsar Theme System](/docs/adr/ADR-001-theme-design-system.md)

## Open Questions

1. **Type Attribute Handling**: Should we maintain Phoenix's string-based type system or introduce a more type-safe approach?

2. **Custom Validation UI**: Should Phase 1 include any custom validation message formatting beyond default Phoenix behavior?

3. **Input Masking**: Should formatted inputs (phone, currency) be considered for Phase 2?

4. **Keyboard Navigation**: Are there specific keyboard shortcuts we should support beyond standard browser behavior?

5. **Form Wrapper Component**: Should the `simple_form` wrapper be part of Phase 1 or Phase 2?

---

*PRD Created: [Current Date]*
*Status: Draft - Pending Review*
*GitHub Issue: To be created*
*Implementation Tracking: GitHub Issue #[TBD] with sub-issues for each component*