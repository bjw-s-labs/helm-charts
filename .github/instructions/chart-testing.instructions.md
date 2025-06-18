# Chart Testing Instructions

Testing is a critical part of chart development to ensure reliability and compatibility.

## Testing Structure

- `charts/library/common/test-chart/`: Contains a test chart for validating the common library
- `charts/library/common/test-chart/unittests/`: Contains unit tests for different resource types
- `charts/library/common/test-chart/ci/`: Contains CI test values

## Testing Tools

This repository uses:

1. **Helm lint**: For syntax validation
2. **Schema validation**: For values validation
3. **Unit tests**: For template functionality validation

## Testing Guidelines

### Running Tests Locally

To run tests locally:

1. `task charts:lint`: Run linting on all charts
2. `task charts:test`: Run chart tests

### Adding New Tests

When adding new features, always add corresponding tests:

1. For new resource types, add unit tests in the appropriate directory
2. For new value options, add test cases that exercise those options
3. For edge cases, add specific test values to validate behavior

### Testing Best Practices

1. Test both valid and invalid configurations
2. Test resource generation with different combinations of values
3. Test template functions with various inputs
4. Test backward compatibility when making changes

### Testing with Real Applications

Beyond automated tests, it's valuable to test with real applications:

1. Deploy sample applications using the app-template chart
2. Verify that all resources are created correctly
3. Test the application functionality
4. Test upgrades from previous versions to ensure compatibility
