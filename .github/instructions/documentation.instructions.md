# Documentation Instructions

Good documentation is essential for this project as it helps users understand how to use the charts effectively.

## Documentation Structure

- `docs/`: Main documentation directory
  - `index.md`: Home page (includes README.md content)
  - `app-template/`: Documentation for the app-template chart
    - `index.md`: Overview of the app-template chart
    - `upgrade-instructions.md`: Instructions for upgrading between major versions
    - `examples/`: Example configurations for the app-template
    - `howto/`: Guides for specific tasks with the app-template
  - `common-library/`: Documentation for the common library chart
    - `index.md`: Overview of the common library chart
    - `howto/`: Guides for specific tasks with the common library
    - `resources/`: Documentation for specific resource types
    - `storage/`: Documentation for storage options
  - `overrides/`: Custom MkDocs template overrides
  - `requirements.txt`: Python dependencies for building the documentation

## Documentation Tools

This repository uses:

1. **MkDocs**: For generating the documentation site
2. **Material for MkDocs**: For styling and enhanced features
3. **PyMdown Extensions**: For extended markdown capabilities
4. **README.md.gotmpl**: Template files for generating README files
5. **mkdocs-minify-plugin**: For minifying the generated HTML

## Documentation Guidelines

### Writing Documentation

When documenting charts and features:

1. Use clear, concise language
2. Provide examples for common use cases
3. Document all available options and their default values
4. Include diagrams or screenshots where helpful
5. Link to relevant external documentation

### Markdown Formatting

All documentation should use consistent Markdown formatting:

1. **Headers**: Use proper hierarchy (H1 → H2 → H3)
   ```markdown
   # Page Title (H1)
   ## Section (H2)
   ### Subsection (H3)
   ```

2. **Code Blocks**: Use fenced code blocks with language specification
   ```markdown
   ```yaml
   controllers:
     main:
       containers:
         main:
           image:
             repository: ghcr.io/example/app
             tag: latest
   ```
   ```

3. **File Inclusions**: Use the `--8<--` syntax to include files
   ```markdown
   --8<--
   examples/helm/vaultwarden/values.yaml
   --8<--
   ```

4. **Admonitions**: Use admonition blocks for notes, warnings, etc.
   ```markdown
   !!! note
       This is a note admonition.

   !!! warning
       This is a warning admonition.
   ```

5. **Line Numbers**: Use line numbers for longer code blocks
   ```markdown
   ```yaml linenums="1"
   # Code with line numbers
   ```
   ```

6. **Annotations**: Use annotations to highlight specific parts of code
   ```markdown
   ```yaml
   image:
     repository: nginx # (1)!
     tag: latest
   ```

   1. This is an annotation explaining the repository value
   ```

### Chart Documentation

Each chart should have at minimum:

1. **Overview**: Brief description of the chart's purpose
2. **Background**: Context or reasoning behind the chart
3. **Usage**: Instructions for using the chart
4. **Examples**: Practical examples with configurations
5. **Source code**: Link to the chart's source code

### Updating Documentation

When making changes to charts:

1. Update the corresponding documentation files
2. Update examples if the change affects how users would use the chart
3. Document breaking changes prominently
4. Add upgrade instructions for major version changes
5. Ensure cross-references between docs remain valid

### Version-Specific Documentation

For version-specific features or changes:

1. Clearly indicate the version where the feature was introduced
2. Use admonitions to highlight version requirements
   ```markdown
   !!! info "Version requirement"
       This feature is available in version 4.0.0 and later.
   ```
3. For major version changes, update `upgrade-instructions.md` with migration steps
4. Use version comparison conditionals when appropriate

### Serving Documentation Locally

To preview documentation locally:

1. Run `task docs:serve`
2. Open a browser to the URL displayed in the terminal (typically http://localhost:8000)
3. Make changes to documentation files and see live updates

### Building the Documentation

To build the documentation for production:

1. Run `task docs:build`
2. The static site will be generated in the `site/` directory

### Documentation Best Practices

1. Keep documentation up to date with code changes
2. Use consistent formatting and style
3. Organize content in a logical hierarchy
4. Include both basic and advanced usage examples
5. Document common gotchas and troubleshooting tips
6. Use code blocks with syntax highlighting for examples
7. Add explanatory comments within code examples
8. Link to related documentation sections

## Folder-Specific Documentation

### App Template Documentation

For the app-template chart, ensure documentation covers:

1. How to use the chart for basic applications
2. Common customization patterns
3. Examples for popular applications
4. Integration with different environments (Flux, Kustomize, etc.)
5. Upgrade paths between major versions

### Common Library Documentation

For the common library, documentation should focus on:

1. Available templates and functions
2. How to use each resource type
3. Advanced configuration options
4. Best practices for extending or customizing

## Example Templates

### Basic Chart Example

```markdown
# Chart Name

## Background

Brief explanation of what this chart does and why it exists.

## Usage

Instructions on how to use this chart, including:

```yaml
# Example values.yaml
controllers:
  main:
    containers:
      main:
        image:
          repository: nginx
          tag: latest
```

## Source code

The source code for this chart can be found [here](link/to/chart).
```

### How-To Guide Template

```markdown
# How to Accomplish X

This guide explains how to accomplish X using the chart.

## Prerequisites

- List prerequisites
- Required knowledge

## Steps

1. First step with explanation
2. Second step with explanation
   ```yaml
   # Example configuration
   ```
3. Third step with explanation

## Examples

Provide complete examples

## See Also

- [Related guide](link/to/related)
- [External resource](link/to/external)
```
