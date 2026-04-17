// Package schema provides shared utilities for walking JSON Schema structures.
package schema

import (
	"errors"
	"fmt"
	"maps"
	"os/exec"
	"slices"

	"github.com/kaptinlin/jsonschema"
)

// maxCollectDepth guards against stack overflow from circular schema references.
const maxCollectDepth = 32

// CollectAllProperties recursively collects properties from a schema including
// allOf, oneOf, and anyOf composition branches. Direct properties take
// precedence; the first occurrence of a key wins. For oneOf/anyOf, only the
// first branch is visited — every allOf branch is always included.
func CollectAllProperties(schema *jsonschema.Schema) map[string]*jsonschema.Schema {
	return collectProps(schema, 0)
}

// collectProps is the recursion-guarded implementation of CollectAllProperties.
// depth is the current nesting level; returning nil when it reaches
// maxCollectDepth prevents stack overflow from cyclic schemas.
func collectProps(schema *jsonschema.Schema, depth int) map[string]*jsonschema.Schema {
	if depth >= maxCollectDepth {
		return nil
	}

	props := make(map[string]*jsonschema.Schema)
	if schema.Properties != nil {
		maps.Copy(props, *schema.Properties)
	}

	mergeFirstBranch := func(subs []*jsonschema.Schema) {
		if len(subs) == 0 {
			return
		}
		for k, v := range collectProps(subs[0], depth+1) {
			if _, exists := props[k]; !exists {
				props[k] = v
			}
		}
	}

	for _, sub := range schema.AllOf {
		for k, v := range collectProps(sub, depth+1) {
			if _, exists := props[k]; !exists {
				props[k] = v
			}
		}
	}
	mergeFirstBranch(schema.OneOf)
	mergeFirstBranch(schema.AnyOf)

	return props
}

// CollectAllRequired recursively collects required field names from a schema,
// following the same branch-selection rules as CollectAllProperties (every
// allOf branch plus the first oneOf/anyOf branch). This keeps the required
// set consistent with the properties visible at the same schema node.
func CollectAllRequired(schema *jsonschema.Schema) []string {
	return collectRequired(schema, 0)
}

func collectRequired(schema *jsonschema.Schema, depth int) []string {
	if depth >= maxCollectDepth {
		return nil
	}
	required := make([]string, 0, len(schema.Required))
	required = append(required, schema.Required...)
	for _, sub := range schema.AllOf {
		required = append(required, collectRequired(sub, depth+1)...)
	}
	if len(schema.OneOf) > 0 {
		required = append(required, collectRequired(schema.OneOf[0], depth+1)...)
	}
	if len(schema.AnyOf) > 0 {
		required = append(required, collectRequired(schema.AnyOf[0], depth+1)...)
	}
	return required
}

// HasAnyProperties returns true if a schema has any properties, either
// directly or via allOf/oneOf/anyOf composition.
func HasAnyProperties(schema *jsonschema.Schema) bool {
	if schema == nil {
		return false
	}
	if schema.Properties != nil && len(*schema.Properties) > 0 {
		return true
	}
	return slices.ContainsFunc(schema.AllOf, HasAnyProperties) ||
		slices.ContainsFunc(schema.OneOf, HasAnyProperties) ||
		slices.ContainsFunc(schema.AnyOf, HasAnyProperties)
}

// SortedKeys returns the keys of a schema property map in alphabetical order.
func SortedKeys(m map[string]*jsonschema.Schema) []string {
	return slices.Sorted(maps.Keys(m))
}

// MakeSet converts a string slice into a set for O(1) membership testing.
func MakeSet(slice []string) map[string]bool {
	set := make(map[string]bool, len(slice))
	for _, s := range slice {
		set[s] = true
	}
	return set
}

// DeduplicateStrings returns a new slice with duplicates removed while
// preserving the order of first occurrence.
func DeduplicateStrings(in []string) []string {
	seen := make(map[string]struct{}, len(in))
	out := make([]string, 0, len(in))
	for _, s := range in {
		if _, ok := seen[s]; !ok {
			seen[s] = struct{}{}
			out = append(out, s)
		}
	}
	return out
}

// CollectExamples gathers string examples from a schema and its oneOf/anyOf
// branches, plus additionalProperties for map types.
func CollectExamples(schema *jsonschema.Schema) []string {
	if schema == nil {
		return nil
	}
	var out []string
	for _, ex := range schema.Examples {
		if s, ok := ex.(string); ok {
			out = append(out, s)
		}
	}
	for _, sub := range schema.OneOf {
		out = append(out, CollectExamples(sub)...)
	}
	for _, sub := range schema.AnyOf {
		out = append(out, CollectExamples(sub)...)
	}
	if schema.AdditionalProperties != nil {
		out = append(out, CollectExamples(schema.AdditionalProperties)...)
	}
	return out
}

// Compile compiles raw JSON Schema bytes into a jsonschema.Schema.
func Compile(schemaBytes []byte) (*jsonschema.Schema, error) {
	s, err := jsonschema.NewCompiler().Compile(schemaBytes)
	if err != nil {
		return nil, fmt.Errorf("failed to compile schema: %w", err)
	}
	return s, nil
}

// schematoolsBinary is the external CLI that resolves $ref entries in a schema.
const schematoolsBinary = "schematools-cli"

// DereferenceSchema uses schematools-cli to dereference $refs in a schema.
// If the binary is not on PATH, the error hints at the canonical install
// method for this repo so the caller can fix their environment quickly.
func DereferenceSchema(inputPath string) ([]byte, error) {
	cmd := exec.Command(schematoolsBinary, "process", "dereference", inputPath) //nolint:gosec // inputPath is a local file path from CLI flags
	output, err := cmd.Output()
	if err != nil {
		if exitErr, ok := errors.AsType[*exec.ExitError](err); ok {
			return nil, fmt.Errorf("%s failed: %s", schematoolsBinary, string(exitErr.Stderr))
		}
		if errors.Is(err, exec.ErrNotFound) {
			return nil, fmt.Errorf("%s not found in PATH (install via `mise install` or `cargo install schematools-cli`): %w", schematoolsBinary, err)
		}
		return nil, fmt.Errorf("failed to run %s: %w", schematoolsBinary, err)
	}
	return output, nil
}
