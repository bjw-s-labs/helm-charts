package values

import (
	"bytes"
	"embed"
	"fmt"
	"maps"
	"slices"
	"strings"
	"text/template"
	"unicode/utf8"

	schemautil "github.com/bjw-s-labs/helm-charts/tools/helm-schema-tools/internal/schema"
	"github.com/kaptinlin/jsonschema"
	"gopkg.in/yaml.v3"
)

//go:embed templates/values.yaml.tmpl
var templateFS embed.FS

const (
	typeObject  = "object"
	typeArray   = "array"
	typeNull    = "null"
	typeBoolean = "boolean"
	typeString  = "string"
	typeInteger = "integer"
	typeNumber  = "number"
)

// fieldCtx carries per-field context that varies as the generator recurses.
// Using a value type (not pointer) means callers set fields on a local copy —
// no save/restore needed and no risk of forgetting to restore on early return.
type fieldCtx struct {
	path     string // JSON schema path to this field's schema
	depth    int
	required bool // whether this field is listed as required in its parent
}

// rootContext is the template data for the top-level values.yaml.
type rootContext struct {
	SchemaPath string
	Entries    []*Entry
}

// Generator generates commented YAML from JSON Schema.
type Generator struct {
	SchemaPath string

	// order preserves the schema's declared property order so generated
	// values.yaml matches the semantic grouping intended by the schema author.
	order *OrderedSchema
	tmpl  *template.Template
}

// NewGenerator creates a new Generator with defaults.
func NewGenerator() *Generator {
	tmpl := template.Must(
		template.New("").Funcs(funcMap()).ParseFS(templateFS, "templates/values.yaml.tmpl"),
	)
	return &Generator{tmpl: tmpl}
}

// Generate produces commented YAML from a compiled JSON Schema.
func (g *Generator) Generate(schemaBytes []byte) ([]byte, error) {
	schema, err := schemautil.Compile(schemaBytes)
	if err != nil {
		return nil, err
	}

	g.order, err = NewOrderedSchema(schemaBytes)
	if err != nil {
		return nil, err
	}

	var entries []*Entry
	if schema.Properties != nil {
		requiredSet := schemautil.MakeSet(schema.Required)
		entries, err = g.buildEntries(*schema.Properties, requiredSet, "", 0)
		if err != nil {
			return nil, err
		}
	}

	ctx := rootContext{SchemaPath: g.SchemaPath, Entries: entries}
	var buf bytes.Buffer
	if err := g.tmpl.ExecuteTemplate(&buf, "values.yaml.tmpl", ctx); err != nil {
		return nil, fmt.Errorf("failed to render template: %w", err)
	}
	return buf.Bytes(), nil
}

func (g *Generator) buildEntries(
	props map[string]*jsonschema.Schema,
	requiredSet map[string]bool,
	schemaPath string,
	depth int,
) ([]*Entry, error) {
	keys := g.order.OrderKeys(schemaPath+"/properties", slices.Collect(maps.Keys(props)))
	entries := make([]*Entry, 0, len(keys))
	for _, key := range keys {
		prop := props[key]
		fc := fieldCtx{
			path:     schemaPath + "/properties/" + key,
			depth:    depth,
			required: requiredSet[key],
		}
		e, err := g.buildEntry(key, prop, fc)
		if err != nil {
			return nil, err
		}
		if e != nil {
			entries = append(entries, e)
		}
	}
	return entries, nil
}

// buildEntry returns nil when the property cannot be safely represented (e.g.
// an optional object whose oneOf/anyOf constraints would be violated by dummy
// values).
func (g *Generator) buildEntry(key string, prop *jsonschema.Schema, fc fieldCtx) (*Entry, error) {
	e := &Entry{Key: key}

	keep, err := g.fillValue(e, prop, fc)
	if err != nil {
		return nil, err
	}
	if !keep {
		return nil, nil
	}

	typeHint := ""
	if e.CommentOut || e.Value == "null" {
		typeHint = helmDocsTypeHint(prop)
	}
	desc := ""
	if prop.Description != nil {
		desc = *prop.Description
	}
	if desc != "" || typeHint != "" {
		e.Comment = formatHelmDocsComment(desc, typeHint, isStructuredMapType(prop))
	} else if isStructuredMapType(prop) {
		e.Comment = "@default -- See below"
	}

	if exs := schemautil.CollectExamples(prop); len(exs) > 0 {
		e.Examples = exs[:min(3, len(exs))]
	}

	return e, nil
}

// fillValue returns keep=false when the entry should be dropped entirely.
func (g *Generator) fillValue(e *Entry, prop *jsonschema.Schema, fc fieldCtx) (bool, error) {
	if prop.Const != nil && prop.Const.IsSet && len(prop.Type) == 0 {
		e.Value = constValue(prop)
		return true, nil
	}

	propType := getSchemaType(prop)

	switch propType {
	case typeObject:
		return g.fillObject(e, prop, fc)
	case typeArray:
		e.Value = "[]"
	default:
		g.fillScalar(e, prop, propType, fc)
	}
	return true, nil
}

func (g *Generator) fillObject(e *Entry, prop *jsonschema.Schema, fc fieldCtx) (bool, error) {
	if !fc.required && prop.Default == nil && hasUnsafeRequiredFields(prop) {
		return false, nil
	}

	// Map type: additionalProperties without direct properties. Emit `{}` as
	// the real value (so an empty map satisfies schema validation) and render
	// a synthetic `main:` example below it as commented-out lines so users can
	// still see the expected shape. This matches the helm-docs/bjw-s
	// convention used in hand-maintained values.yaml files.
	if prop.AdditionalProperties != nil && prop.Properties == nil {
		e.Value = "{}"
		if schemautil.HasAnyProperties(prop.AdditionalProperties) {
			example, err := g.buildMapExample(prop.AdditionalProperties, fc.path+"/additionalProperties", fc.depth)
			if err != nil {
				return false, err
			}
			block, err := g.renderEntriesAsComments(example, fc.depth+1)
			if err != nil {
				return false, err
			}
			e.ExampleBlock = block
		}
		return true, nil
	}

	allProps := schemautil.CollectAllProperties(prop)
	if len(allProps) == 0 {
		e.Value = "{}"
		return true, nil
	}

	// Optional nested objects without a default collapse to `{}` plus a
	// commented-out structure preview. This keeps Helm's value-merge semantics
	// sane — users who don't set the key won't inherit empty sub-containers
	// that would leak through `{{ with }}` guards in chart templates. Top-level
	// objects (depth 0) stay fully expanded so `helm show values` still
	// surfaces scalar defaults like nameOverride or replicas.
	if fc.depth >= 1 && !fc.required && prop.Default == nil {
		e.Value = "{}"
		requiredSet := schemautil.MakeSet(schemautil.CollectAllRequired(prop))
		children, err := g.buildEntries(allProps, requiredSet, fc.path, fc.depth+1)
		if err != nil {
			return false, err
		}
		block, err := g.renderEntriesAsComments(children, fc.depth+1)
		if err != nil {
			return false, err
		}
		e.ExampleBlock = block
		return true, nil
	}

	requiredSet := schemautil.MakeSet(schemautil.CollectAllRequired(prop))
	children, err := g.buildEntries(allProps, requiredSet, fc.path, fc.depth+1)
	if err != nil {
		return false, err
	}
	e.Children = children
	return true, nil
}

func (g *Generator) buildMapExample(itemSchema *jsonschema.Schema, itemSchemaPath string, depth int) ([]*Entry, error) {
	allProps := schemautil.CollectAllProperties(itemSchema)
	requiredSet := schemautil.MakeSet(schemautil.CollectAllRequired(itemSchema))
	children, err := g.buildEntries(allProps, requiredSet, itemSchemaPath, depth+1)
	if err != nil {
		return nil, err
	}
	return []*Entry{{
		Key:      "main",
		Comment:  "Example entry - rename as needed",
		Children: children,
	}}, nil
}

func (g *Generator) renderEntriesAsComments(entries []*Entry, depth int) (string, error) {
	if len(entries) == 0 {
		return "", nil
	}
	indent := strings.Repeat("  ", depth)
	var buf bytes.Buffer
	data := map[string]any{"Indent": indent, "Entries": entries, "Top": false}
	if err := g.tmpl.ExecuteTemplate(&buf, "entries", data); err != nil {
		return "", fmt.Errorf("render example block: %w", err)
	}
	return commentifyYAML(buf.String()), nil
}

// commentifyYAML prefixes every non-blank, non-comment line in yaml with `# `
// so the block renders as a commented-out example in the generated values.yaml.
// Lines that are already comments (helm-docs descriptions) are left untouched
// to avoid double-hashing like `# # -- description`.
func commentifyYAML(yaml string) string {
	lines := strings.Split(yaml, "\n")
	out := make([]string, 0, len(lines))
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}
		leading := line[:len(line)-len(strings.TrimLeft(line, " \t"))]
		rest := strings.TrimPrefix(line, leading)
		if strings.HasPrefix(rest, "#") {
			// Existing helm-docs comment line — keep as-is.
			out = append(out, line)
			continue
		}
		out = append(out, leading+"# "+rest)
	}
	return strings.Join(out, "\n")
}

// fillScalar populates e.Value / e.CommentOut for string, number, bool, null.
func (g *Generator) fillScalar(e *Entry, prop *jsonschema.Schema, propType string, fc fieldCtx) {
	switch propType {
	case typeString:
		g.fillString(e, prop, fc)
	case typeInteger, typeNumber:
		g.fillNumber(e, prop, propType, fc)
	case typeBoolean:
		g.fillBool(e, prop, fc)
	default:
		e.Value = typeNull
	}
}

func (g *Generator) fillString(e *Entry, prop *jsonschema.Schema, fc fieldCtx) {
	// Nullable-and-optional fields emit `null` even when the schema has a
	// default. Chart templates that distinguish "unset" from "explicit zero"
	// (via kindIs or hasKey) rely on this semantic — injecting the default
	// would change the rendered manifest from "field omitted" to "field = 0".
	if !fc.required && allowsNull(prop) {
		e.Value = typeNull
		return
	}
	if prop.Default != nil {
		if s, ok := prop.Default.(string); ok {
			e.Value = yamlQuoteString(s)
			return
		}
	}
	if prop.Const != nil && prop.Const.IsSet {
		if s, ok := prop.Const.Value.(string); ok {
			e.Value = yamlQuoteString(s)
			return
		}
	}
	dummy := ""
	if len(prop.Enum) > 0 {
		if s, ok := prop.Enum[0].(string); ok {
			dummy = s
		}
	}
	if fc.required {
		e.Value = yamlQuoteString(dummy)
		return
	}
	e.CommentOut = true
}

func (g *Generator) fillNumber(e *Entry, prop *jsonschema.Schema, propType string, fc fieldCtx) {
	if !fc.required && allowsNull(prop) {
		e.Value = typeNull
		return
	}
	if prop.Default != nil {
		e.Value = fmt.Sprintf("%v", prop.Default)
		return
	}
	if fc.required {
		if propType == typeNumber {
			e.Value = "0.0"
		} else {
			e.Value = "0"
		}
		return
	}
	e.CommentOut = true
}

func (g *Generator) fillBool(e *Entry, prop *jsonschema.Schema, fc fieldCtx) {
	if !fc.required && allowsNull(prop) {
		e.Value = typeNull
		return
	}
	if prop.Default != nil {
		if b, ok := prop.Default.(bool); ok {
			e.Value = boolYAML(b)
			return
		}
	}
	if fc.required {
		e.Value = "false"
		return
	}
	e.CommentOut = true
}

// constValue renders a pure const schema value as a YAML scalar string.
func constValue(prop *jsonschema.Schema) string {
	switch v := prop.Const.Value.(type) {
	case string:
		return yamlQuoteString(v)
	case bool:
		return boolYAML(v)
	default:
		return fmt.Sprintf("%v", v)
	}
}

func boolYAML(b bool) string {
	if b {
		return "true"
	}
	return "false"
}

// yamlQuoteString wraps a string in YAML quotes only when the bare form would
// parse as a different type (bool, null, number) or contain structural
// characters. yaml.v3's Marshal does exactly this disambiguation, so we
// delegate to it rather than reimplementing the rules.
func yamlQuoteString(s string) string {
	b, err := yaml.Marshal(s)
	if err != nil {
		return fmt.Sprintf("%q", s)
	}
	return strings.TrimRight(string(b), "\n")
}

// helmDocsTypeHint returns a helm-docs-compatible type hint for a schema
// whose value will render as null or commented-out in the generated YAML.
func helmDocsTypeHint(prop *jsonschema.Schema) string {
	if prop == nil {
		return ""
	}
	types := schemautil.DeduplicateStrings(collectTypeHints(prop))
	if len(types) == 0 {
		return ""
	}
	return strings.Join(types, "/")
}

// collectTypeHints walks a schema and returns every helm-docs type hint it can
// derive, including those from oneOf/anyOf branches.
func collectTypeHints(prop *jsonschema.Schema) []string {
	if prop == nil {
		return nil
	}
	var out []string
	for _, t := range prop.Type {
		switch t {
		case typeString:
			out = append(out, "string")
		case typeInteger:
			out = append(out, "int")
		case typeNumber:
			out = append(out, "float")
		case typeBoolean:
			out = append(out, "bool")
		case typeArray:
			out = append(out, "list")
		case typeObject:
			out = append(out, "object")
		}
	}
	for _, sub := range prop.OneOf {
		out = append(out, collectTypeHints(sub)...)
	}
	for _, sub := range prop.AnyOf {
		out = append(out, collectTypeHints(sub)...)
	}
	// Structural inference when no non-null type was found.
	hasNonNull := slices.ContainsFunc(out, func(s string) bool { return s != typeNull })
	if !hasNonNull {
		if prop.Properties != nil || prop.AdditionalProperties != nil {
			out = append(out, "object")
		} else if prop.Items != nil {
			out = append(out, "list")
		}
	}
	return out
}

// isStructuredMapType returns true for additionalProperties maps that contain
// complex objects (warranting a @default -- See below annotation).
func isStructuredMapType(prop *jsonschema.Schema) bool {
	if prop == nil || prop.AdditionalProperties == nil {
		return false
	}
	if prop.Properties != nil && len(*prop.Properties) > 0 {
		return false
	}
	return schemautil.HasAnyProperties(prop.AdditionalProperties)
}

// hasUnsafeRequiredFields returns true if an optional object has required
// fields whose dummy values would violate oneOf/anyOf constraints.
func hasUnsafeRequiredFields(schema *jsonschema.Schema) bool {
	if len(schema.OneOf) == 0 && len(schema.AnyOf) == 0 {
		return false
	}
	allProps := schemautil.CollectAllProperties(schema)
	for _, key := range schemautil.CollectAllRequired(schema) {
		prop, ok := allProps[key]
		if !ok {
			continue
		}
		if prop.Default != nil || prop.Const != nil {
			continue
		}
		t := primaryNonNullType(prop)
		if t == typeArray || t == typeBoolean {
			continue
		}
		return true
	}
	return false
}

// primaryNonNullType returns the first non-null type from a schema's Type list.
func primaryNonNullType(prop *jsonschema.Schema) string {
	for _, t := range prop.Type {
		if t != typeNull {
			return t
		}
	}
	return ""
}

// allowsNull returns true if the schema explicitly accepts null values.
func allowsNull(prop *jsonschema.Schema) bool {
	return slices.Contains(prop.Type, typeNull)
}

// getSchemaType returns the primary non-null type, falling back to structural
// inference and then oneOf/anyOf branch types.
func getSchemaType(prop *jsonschema.Schema) string {
	for _, t := range prop.Type {
		if t != typeNull {
			return t
		}
	}
	if len(prop.Type) > 0 {
		return prop.Type[0] // only null
	}
	if prop.Properties != nil || prop.AdditionalProperties != nil {
		return typeObject
	}
	if prop.Items != nil {
		return typeArray
	}
	for _, sub := range prop.OneOf {
		if t := getSchemaType(sub); t != typeNull {
			return t
		}
	}
	for _, sub := range prop.AnyOf {
		if t := getSchemaType(sub); t != typeNull {
			return t
		}
	}
	return typeNull
}

// formatHelmDocsComment formats a description in helm-docs style.
func formatHelmDocsComment(desc, typeHint string, appendDefaultSeeBelow bool) string {
	desc = strings.TrimSpace(desc)
	const wrapWidth = 78
	prefix := "-- "
	if typeHint != "" {
		prefix = "-- (" + typeHint + ") "
	}
	if desc == "" {
		desc = strings.TrimSpace(prefix)
		prefix = ""
	}
	wrapped := wrapText(prefix+desc, wrapWidth)
	if appendDefaultSeeBelow {
		wrapped = append(wrapped, "@default -- See below")
	}
	return strings.Join(wrapped, "\n")
}

// wrapText wraps text at width runes per line, returning one string per line.
// Lines are split on word boundaries; a single word longer than width is
// emitted on its own line rather than being truncated.
func wrapText(text string, width int) []string {
	if utf8.RuneCountInString(text) <= width {
		return []string{text}
	}
	var lines []string
	words := strings.Fields(text)
	var cur strings.Builder
	curRunes := 0
	for _, word := range words {
		wordRunes := utf8.RuneCountInString(word)
		if curRunes+wordRunes+1 > width && curRunes > 0 {
			lines = append(lines, cur.String())
			cur.Reset()
			curRunes = 0
		}
		if curRunes > 0 {
			cur.WriteByte(' ')
			curRunes++
		}
		cur.WriteString(word)
		curRunes += wordRunes
	}
	if cur.Len() > 0 {
		lines = append(lines, cur.String())
	}
	return lines
}

// funcMap returns template helpers.
func funcMap() template.FuncMap {
	return template.FuncMap{
		"deeper":          func(s string) string { return s + "  " },
		"splitLines":      func(s string) []string { return strings.Split(s, "\n") },
		"allCommentedOut": allCommentedOut,
		"dict":            templateDict,
	}
}

func templateDict(pairs ...any) (map[string]any, error) {
	if len(pairs)%2 != 0 {
		return nil, fmt.Errorf("dict: odd number of arguments (%d)", len(pairs))
	}
	m := make(map[string]any, len(pairs)/2)
	for i := 0; i+1 < len(pairs); i += 2 {
		key, ok := pairs[i].(string)
		if !ok {
			return nil, fmt.Errorf("dict: key at position %d is %T, want string", i, pairs[i])
		}
		m[key] = pairs[i+1]
	}
	return m, nil
}
