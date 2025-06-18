# Common Library Development Instructions

The `common` library chart is the foundation of this repository. It provides reusable templates and functions for Kubernetes resource generation.

## Structure

- `templates/classes/`: Contains template definitions for various Kubernetes resources
- `templates/lib/`: Contains library functions used across templates
- `templates/loader/`: Contains code for loading and initializing templates
- `templates/render/`: Contains code for rendering resources
- `templates/values/`: Contains code for value validation
- `schemas/`: JSON schemas for validating values

## Key Concepts

1. **Template Classes**: These are blueprint templates for Kubernetes resources like Deployments, Services, etc.
2. **Library Functions**: Helper functions that can be used across templates
3. **Values Schema**: JSON schema definitions for validating chart values

## Development Guidelines

### Adding New Features

When adding new features to the common library:

1. Determine which resource type(s) the feature applies to
2. Add appropriate parameters to the values schema
3. Update the relevant template class(es)
4. Update documentation as needed
5. Increment the chart version in `Chart.yaml` following semver principles

### Modifying Existing Features

When modifying existing features:

1. Ensure backward compatibility or document breaking changes
2. Update the relevant template class(es)
3. Update the values schema if needed
4. Update documentation
5. Increment the chart version appropriately

### Testing Changes

After making changes:

1. Run `task charts:lint` to validate chart syntax
2. Run `task charts:test` to run chart tests
3. Deploy a test chart using the library to verify functionality

### Common Library Best Practices

1. Keep template functions focused and reusable
2. Use clear naming conventions for functions and parameters
3. Document function parameters and behavior
4. Maintain backward compatibility where possible
5. Update version numbers in accordance with semver principles
