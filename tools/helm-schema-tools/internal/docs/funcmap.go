package docs

import (
	"fmt"
	"html"
	"strings"
	"text/template"
	"unicode/utf8"

	schemautil "github.com/bjw-s-labs/helm-charts/tools/helm-schema-tools/internal/schema"
	"github.com/kaptinlin/jsonschema"
)

// ellipsis is the suffix appended by truncateDescription when a string is cut
// mid-way; its rune width is subtracted from the budget to keep output <= maxLen.
const ellipsis = "..."

// anyType is the sentinel returned by typeString when no concrete type can be
// derived from the schema; collectBranchTypes uses it to skip uninformative
// branches.
const anyType = "any"

// funcMap returns the template function map used by all doc templates.
func funcMap() template.FuncMap {
	return template.FuncMap{
		"typeString":     typeString,
		"description":    description,
		"truncate":       truncateDescription,
		"defaultVal":     defaultVal,
		"enumValues":     enumValues,
		"hasNested":      hasNestedContent,
		"descWithExtras": descriptionWithExtras,
		"add1":           func(i int) int { return i + 1 },
		"sub":            func(a, b int) int { return a - b },
		"lower":          strings.ToLower,
		"allExamples":    collectAllExamples,
		"mdxSafe":        mdxSafe,
	}
}

// typeString returns a display string for a schema's type.
// Uses " / " as separator to avoid breaking markdown tables.
// Handles oneOf/anyOf unions by collecting types from all branches.
func typeString(schema *jsonschema.Schema) string {
	if schema == nil {
		return anyType
	}
	if len(schema.Type) > 0 {
		if len(schema.Type) == 1 {
			return schema.Type[0]
		}
		return strings.Join(schema.Type, " / ")
	}
	if schema.Properties != nil || schema.AdditionalProperties != nil {
		return "object"
	}
	if schema.Items != nil {
		return "array"
	}
	if len(schema.Enum) > 0 {
		return "enum"
	}
	// Collect types from oneOf/anyOf branches for union types like `string | object`.
	types := collectBranchTypes(schema.OneOf)
	types = append(types, collectBranchTypes(schema.AnyOf)...)
	if len(types) > 0 {
		return strings.Join(schemautil.DeduplicateStrings(types), " / ")
	}
	return anyType
}

// collectBranchTypes returns the type string for each branch in a oneOf/anyOf slice.
func collectBranchTypes(branches []*jsonschema.Schema) []string {
	out := make([]string, 0, len(branches))
	for _, b := range branches {
		if t := typeString(b); t != anyType {
			out = append(out, t)
		}
	}
	return out
}

// description returns the MDX-safe description string from a schema.
func description(schema *jsonschema.Schema) string {
	if schema == nil || schema.Description == nil {
		return ""
	}
	return mdxSafe(*schema.Description)
}

// truncateDescription shortens a description to maxLen runes, stripping
// newlines. The cut is rune-aware so multi-byte characters are never split.
// When the input exceeds maxLen, the tail is replaced with an ellipsis; if
// maxLen is too small to fit the ellipsis, the input is truncated to maxLen
// runes without one.
func truncateDescription(s string, maxLen int) string {
	s = strings.ReplaceAll(s, "\n", " ")
	s = strings.TrimSpace(s)
	if maxLen <= 0 {
		return ""
	}
	if utf8.RuneCountInString(s) <= maxLen {
		return s
	}
	runes := []rune(s)
	ellipsisRunes := utf8.RuneCountInString(ellipsis)
	if maxLen <= ellipsisRunes {
		return string(runes[:maxLen])
	}
	return string(runes[:maxLen-ellipsisRunes]) + ellipsis
}

// defaultVal formats a schema's default value for display, or returns "-".
func defaultVal(schema *jsonschema.Schema) string {
	if schema == nil || schema.Default == nil {
		return "-"
	}
	return fmt.Sprintf("`%v`", schema.Default)
}

// enumValues returns the enum values as formatted strings.
func enumValues(schema *jsonschema.Schema) []string {
	if schema == nil || len(schema.Enum) == 0 {
		return nil
	}
	out := make([]string, len(schema.Enum))
	for i, e := range schema.Enum {
		out[i] = fmt.Sprintf("`%v`", e)
	}
	return out
}

// hasNestedContent returns true if a schema has nested properties worth a sub-page.
func hasNestedContent(schema *jsonschema.Schema) bool {
	if schema == nil {
		return false
	}
	if schema.Properties != nil && len(*schema.Properties) > 0 {
		return true
	}
	if schema.AdditionalProperties != nil {
		props := schemautil.CollectAllProperties(schema.AdditionalProperties)
		return len(props) > 0
	}
	return false
}

// collectAllExamples gathers examples from a schema and all its composition branches.
func collectAllExamples(schema *jsonschema.Schema) []any {
	if schema == nil {
		return nil
	}
	var out []any
	out = append(out, schema.Examples...)
	for _, sub := range schema.OneOf {
		out = append(out, sub.Examples...)
	}
	for _, sub := range schema.AnyOf {
		out = append(out, sub.Examples...)
	}
	for _, sub := range schema.AllOf {
		out = append(out, sub.Examples...)
	}
	// For map types, also collect from additionalProperties branches
	if schema.AdditionalProperties != nil {
		out = append(out, collectAllExamples(schema.AdditionalProperties)...)
	}
	return out
}

// mdxSafe escapes characters that MDX interprets as JSX (<>{}).
// html.EscapeString handles < and >, then we escape {} for JSX expressions.
func mdxSafe(s string) string {
	s = html.EscapeString(s)
	s = strings.ReplaceAll(s, "{", "\\{")
	s = strings.ReplaceAll(s, "}", "\\}")
	return s
}

// descriptionWithExtras returns a truncated, MDX-safe description with an
// inline enum hint appended when the total fits within maxLen runes.
func descriptionWithExtras(schema *jsonschema.Schema, maxLen int) string {
	if schema == nil {
		return ""
	}
	desc := ""
	if schema.Description != nil {
		desc = truncateDescription(mdxSafe(*schema.Description), maxLen)
	}
	if len(schema.Enum) > 0 && len(schema.Enum) <= 4 {
		enumStrs := make([]string, 0, len(schema.Enum))
		for _, e := range schema.Enum {
			enumStrs = append(enumStrs, fmt.Sprintf("%v", e))
		}
		enumHint := fmt.Sprintf(" (%s)", strings.Join(enumStrs, ", "))
		if utf8.RuneCountInString(desc)+utf8.RuneCountInString(enumHint) <= maxLen {
			desc += enumHint
		}
	}
	return desc
}
