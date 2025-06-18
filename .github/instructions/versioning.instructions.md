# Version Management Instructions

Proper versioning is critical for maintaining compatibility and communicating changes to users.

## Versioning Principles

This repository follows [Semantic Versioning (SemVer)](https://semver.org/):

1. **MAJOR**: Incompatible API changes
2. **MINOR**: Functionality added in a backward compatible manner
3. **PATCH**: Backward compatible bug fixes

## Version Management Guidelines

### When to Increment Versions

- **MAJOR**: When making breaking changes like:
  - Removing or renaming values
  - Changing default behavior significantly
  - Requiring a newer Kubernetes version

- **MINOR**: When adding new features like:
  - New resource types
  - New configuration options
  - Extended functionality

- **PATCH**: When making non-breaking fixes like:
  - Bug fixes
  - Documentation updates
  - Optimization improvements

### Chart Dependencies

When updating chart dependencies:

1. Update the dependency version in `Chart.yaml`
2. Update the chart's own version appropriately
3. Document the change and any implications

### Release Notes

For each version change:

1. Document what changed
2. Highlight any breaking changes
3. Provide upgrade instructions if needed
4. Tag the repository with the new version

### Version Management Best Practices

1. Always increment versions for any chart changes
2. Be conservative in MAJOR version increments
3. Document breaking changes thoroughly
4. Provide upgrade paths for users on older versions
5. Test upgrades from previous versions to ensure compatibility
