# Project Overview

This repository contains Helm charts developed for running applications in Kubernetes clusters. The core of this repository is the **common library chart** (`charts/library/common`), which provides reusable Helm template functions that other charts can depend on.

## Repository Structure

```
charts/
├── library/
│   └── common/              # Core library chart (type: library)
│       ├── templates/       # Helm template definitions
│       │   ├── classes/     # Resource class definitions (one per Kubernetes resource type)
│       │   ├── lib/         # Library functions organized by resource type
│       │   ├── loader/      # Chart initialization and value loading
│       │   ├── render/      # Rendering logic for each resource type
│       │   └── values/      # Default values processing
│       ├── test-chart/      # Test wrapper chart for unit testing
│       │   └── unittests/   # helm-unittest test suites
│       ├── schemas/         # JSON schemas for values
│       └── values.schema.json  # Main values schema
└── other/
    ├── app-template/        # Application template chart (uses common library)
    └── multus/              # Multus CNI chart
```

## Architecture

### Library Chart Pattern

The `common` library chart follows a modular architecture:

1. **Classes** (`templates/classes/`) - Define the structure for each Kubernetes resource type (Deployment, Service, ConfigMap, etc.). Each class is a template that can be included by dependent charts.

2. **Library Functions** (`templates/lib/`) - Organized by resource type, containing:
   - Validation functions (`_validate.tpl`) - Validate user-provided values
   - Field builders - Construct specific fields for resources
   - Helper functions - Utility functions for common operations

3. **Render Functions** (`templates/render/`) - Iterate over user values and render multiple instances of each resource type.

4. **Test Chart** (`test-chart/`) - A wrapper chart that depends on the common library, used exclusively for unit testing with helm-unittest.

### Key Concepts

- **Identifiers**: Each resource instance has a unique identifier used for referencing and error messages
- **Enabled/Disabled**: Resources can be conditionally enabled via `enabled: true/false`
- **Auto-detection**: The library attempts to automatically detect relationships (e.g., which Service a Pod should use) when only one option exists
- **Validation**: Extensive validation ensures users get clear, actionable error messages when misconfiguring values

## Development Workflow

1. **Make changes** to template files in `charts/library/common/templates/`
2. **Update/add tests** in `charts/library/common/test-chart/unittests/`
3. **Run tests** via `just chart::test library/common`
4. **Verify** all tests pass before committing

## Development Environment

### Tools

- All development tools are managed via `mise` (see `.mise.toml`)
- Never assume tools are globally installed
- Run `mise install` to install all required tools

---

# Error Message Guidelines

All error messages in Helm templates MUST follow structured logging principles:

## Format

```
"ResourceType 'identifier': Problem description. Actionable suggestion."
```

## Rules

1. **Single-line only** - Never use multiline error messages. helm-unittest's YAML parsing doesn't handle them well.
2. **Start with resource context** - Always begin with the resource type and identifier (e.g., `Controller 'main':`, `Service 'api':`)
3. **Clear problem description** - Explain what's wrong in plain language
4. **Actionable guidance** - End with specific instructions on how to fix the issue, including the full path in the values file when possible

## Examples

### Good
```go
{{- fail (printf "Container '%s': Image repository is required. Specify the repository under 'controllers.%s.containers.%s.image.repository'." $containerObject.identifier $controllerObject.identifier $containerObject.identifier) }}
```

### Bad
```go
{{- fail "No image repository specified" }}  // Missing context and guidance
{{- fail (printf "Error in controller %s:\n  Container %s is missing image repository" ...) }}  // Multiline
```

## Testing

- Run all tests via: `just chart::test library/common`
- Run specific tests via glob pattern: `just chart::test library/common "container/*_test.yaml"`
  - Examples:
    - `just chart::test library/common "container/*_test.yaml"` - Run all container tests
    - `just chart::test library/common "pod/field_*_test.yaml"` - Run all pod field tests
    - `just chart::test library/common "**/field_env_*_test.yaml"` - Run all env-related tests
- All validation changes MUST include corresponding unit test updates
- Error messages in tests should match exactly (use `errorMessage` not `errorPattern` when possible)

---

# Code Conventions

## Template Function Naming

All library functions follow a strict naming convention:

```
bjw-s.common.lib.<resource>.<function>
```

Examples:
- `bjw-s.common.lib.controller.validate` - Validates controller values
- `bjw-s.common.lib.pod.field.serviceAccountName` - Returns the serviceAccountName field
- `bjw-s.common.lib.service.primaryForController` - Finds the primary service for a controller

## Common Patterns

### Context Passing

Functions receive context via a dict with standardized keys:

```go
{{- $ctx := dict "rootContext" $ "controllerObject" $controller "containerObject" $container -}}
{{- include "bjw-s.common.lib.container.validate" $ctx -}}
```

- `rootContext` - The root Helm context (`.`)
- `object` - The object being processed (controller, service, etc.)
- Additional context-specific keys as needed

### Validation Functions

Validation functions:
- Are defined in `_validate.tpl` files
- Are called early in the rendering process
- Fail fast with clear error messages
- Don't return values (only fail or pass)

### Field Builder Functions

Field builder functions:
- Are defined in `fields/` subdirectories
- Return YAML fragments that are merged into the final resource
- Handle conditional logic and defaults
- Use `tpl` for template string evaluation in user values

### Enable/Disable Pattern

Resources follow this pattern for conditional rendering:

```go
{{- $enabled := true -}}
{{- if hasKey $values "enabled" -}}
  {{- $enabled = $values.enabled -}}
{{- end -}}
{{- if $enabled -}}
  {{/* render resource */}}
{{- end -}}
```

### Identifier-based Lookups

When referencing other resources by identifier:

```go
{{- $configMap := include "bjw-s.common.lib.configMap.getByIdentifier" (dict "rootContext" $rootContext "id" .configMap) | fromYaml -}}
{{- if empty $configMap -}}
  {{- fail (printf "No ConfigMap found with identifier '%s'" .configMap) -}}
{{- end -}}
```

## File Organization

- `_validate.tpl` - Validation logic for a resource type
- `fields/_*.tpl` - Individual field builders
- `_*.tpl` (in lib directories) - Helper functions and utilities
- Test files mirror the structure: `unittests/<resource>/field_<name>_test.yaml`
