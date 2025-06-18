# Example Development Instructions

Examples are crucial for helping users understand how to use the charts in real-world scenarios.

## Example Structure

- `examples/`: Main examples directory
  - `helm/`: Examples for using charts with plain Helm
  - `flux/`: Examples for using charts with Flux CD
  - `kustomize/`: Examples for using charts with Kustomize

## Example Guidelines

### Creating New Examples

When creating new examples:

1. Choose realistic applications that demonstrate chart capabilities
2. Structure examples clearly with comments explaining key configuration options
3. Include all necessary files for the deployment method
4. Add a README.md explaining the purpose and usage of the example

### Updating Examples

When updating chart features:

1. Update relevant examples to demonstrate the new features
2. Ensure examples continue to work with the latest chart versions
3. Document any breaking changes that would affect existing users

### Example Best Practices

1. Keep examples simple enough to understand but comprehensive enough to be useful
2. Include comments that explain why certain configuration options are chosen
3. Demonstrate both basic and advanced usage patterns
4. Include examples for different types of applications (stateless, stateful, etc.)
5. Show integration with common tools and platforms (Flux, Kustomize, etc.)

### Testing Examples

Before committing examples:

1. Deploy the example in a test environment
2. Verify that all resources are created correctly
3. Test the functionality of the deployed application
4. Ensure the example is compatible with the latest chart version
