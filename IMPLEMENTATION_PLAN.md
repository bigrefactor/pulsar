# Igniter-based Component Generator System - Implementation Plan

## Overview

Transform Pulsar to an Igniter-based generator system where components are installed directly into user applications for full code ownership and customization.

## Implementation Phases

### Phase 1: Igniter Infrastructure
- [ ] Create `.igniter.exs` configuration file
- [ ] Create `lib/mix/tasks/pulsar/install.ex` main installer task
- [ ] Create `lib/pulsar/igniter/helpers.ex` utility module

### Phase 2: Template System
- [ ] Create `priv/templates/` directory structure
- [ ] Convert Button component to EEx template (pilot)
- [ ] Convert all 19 components to templates
- [ ] Add version tracking metadata

### Phase 3: Main Installer
- [ ] Web module auto-detection
- [ ] Component selection parsing (--all or individual)
- [ ] Directory structure creation (--flat, --subdir options)
- [ ] Template rendering with EEx
- [ ] TailwindMerge dependency management

### Phase 4: Theme & Assets
- [ ] Copy theme CSS to assets/css/pulsar.css
- [ ] Update app.css with imports
- [ ] Add dark mode variant
- [ ] Handle Tailwind v3/v4 detection

### Phase 5: Import Management
- [ ] Update lib/<app>_web.ex with component imports
- [ ] Core components detection and backup
- [ ] Interactive replacement prompt
- [ ] Generate delegating core_components.ex

### Phase 6: Individual Generators
- [ ] Create 19 individual component generator tasks
- [ ] Composable via Igniter.compose_task/3

### Phase 7: Update System
- [ ] `mix pulsar.update` command
- [ ] Version detection and customization tracking
- [ ] Interactive merge strategies

### Phase 8: Testing
- [ ] Install test with Igniter.Test
- [ ] Component generation tests
- [ ] Theme installation tests
- [ ] Import management tests
- [ ] Core components replacement tests

### Phase 9: Documentation
- [ ] Update CLAUDE.md with generator architecture
- [ ] Update README.md with installation instructions
- [ ] Add moduledocs to all Mix tasks
- [ ] Update HexDocs configuration

### Phase 10: Polish & Validation
- [ ] Success messages and UX
- [ ] End-to-end testing in Phoenix app
- [ ] Run mix check (format, credo, dialyzer, tests)

## Installation Behavior

### Default Installation
```bash
mix igniter.install pulsar --all
```

**Generated structure:**
```
lib/my_app_web/components/
└── ui/
    ├── button.ex          # MyAppWeb.Components.Button
    ├── input.ex           # MyAppWeb.Components.Input
    ├── checkbox.ex        # MyAppWeb.Components.Checkbox
    └── ... (19 components)

assets/css/
└── pulsar.css            # Theme with semantic color tokens
```

### Options Supported
- `--all` - Install all 19 components
- `--flat` - Install directly in /components (no subdirectory)
- `--subdir <name>` - Custom subdirectory name (default: "ui")
- `--replace-core-components` - Replace existing core_components.ex
- `--keep-core-components` - Keep existing core_components.ex
- Respects Igniter's `--yes`, `--dry-run`, `--verbose` flags

## Components (19 Total)

1. Badge
2. Button
3. Card
4. Checkbox
5. Divider
6. Field
7. Flash
8. FlashGroup
9. Header
10. Icon
11. Input
12. Label
13. Link
14. List
15. RadioGroup
16. Select
17. Switch
18. Table
19. Textarea

## Architecture Decisions

**Module Naming:**
- Generated modules: `MyAppWeb.Components.Button` (clean, no extra namespace)
- File organization: `lib/my_app_web/components/ui/button.ex` (organized subdirectory)

**Template System:**
- Source: Current components in `lib/pulsar/components/*.ex`
- Templates: EEx templates in `priv/templates/*.ex.eex`
- Variables: `@module_name`, `@web_module`, `@app_name`, `@pulsar_version`
- Version tracking: Metadata comments for future updates

**Core Components Strategy:**
- Interactive prompt when existing core_components.ex detected
- Backup original → Generate delegating module
- Full backwards compatibility via defdelegate

## Success Criteria

- [ ] `mix igniter.install pulsar --all` works in fresh Phoenix app
- [ ] All 19 components generate with correct module names
- [ ] Theme CSS installs and dark mode works immediately
- [ ] Generated components are fully functional
- [ ] TailwindMerge dependency added automatically
- [ ] Test coverage >90%
- [ ] Documentation complete and accurate

## Breaking Changes

⚠️ **Yes** - This changes Pulsar to a generator-first approach. Components must be installed into the user's codebase via `mix igniter.install pulsar`.
