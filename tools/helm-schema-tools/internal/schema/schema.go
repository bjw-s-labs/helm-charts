// Package schema provides shared utilities for walking JSON Schema structures.
package schema

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"maps"
	"net/url"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"github.com/kaptinlin/jsonschema"
	"gopkg.in/yaml.v3"
)

// CollectAllProperties recursively collects properties from a schema including
// allOf, oneOf, and anyOf composition branches. Direct properties take
// precedence; the first occurrence of a key wins. For oneOf/anyOf, only the
// first branch is visited — every allOf branch is always included.
func CollectAllProperties(schema *jsonschema.Schema) map[string]*jsonschema.Schema {
	return collectProps(schema, make(map[*jsonschema.Schema]struct{}))
}

// collectProps is the cycle-safe implementation of CollectAllProperties.
// Schema graphs can contain a reference cycle, while valid non-cyclic schemas
// may be deeper than any arbitrary nesting limit. Track visited nodes instead
// of silently omitting properties after a fixed depth.
func collectProps(schema *jsonschema.Schema, visited map[*jsonschema.Schema]struct{}) map[string]*jsonschema.Schema {
	if schema == nil {
		return nil
	}
	if _, seen := visited[schema]; seen {
		return nil
	}
	visited[schema] = struct{}{}

	props := make(map[string]*jsonschema.Schema)
	if schema.Properties != nil {
		maps.Copy(props, *schema.Properties)
	}

	mergeFirstBranch := func(subs []*jsonschema.Schema) {
		if len(subs) == 0 {
			return
		}
		for k, v := range collectProps(subs[0], visited) {
			if _, exists := props[k]; !exists {
				props[k] = v
			}
		}
	}

	for _, sub := range schema.AllOf {
		for k, v := range collectProps(sub, visited) {
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
	return collectRequired(schema, make(map[*jsonschema.Schema]struct{}))
}

func collectRequired(schema *jsonschema.Schema, visited map[*jsonschema.Schema]struct{}) []string {
	if schema == nil {
		return nil
	}
	if _, seen := visited[schema]; seen {
		return nil
	}
	visited[schema] = struct{}{}
	required := make([]string, 0, len(schema.Required))
	required = append(required, schema.Required...)
	for _, sub := range schema.AllOf {
		required = append(required, collectRequired(sub, visited)...)
	}
	if len(schema.OneOf) > 0 {
		required = append(required, collectRequired(schema.OneOf[0], visited)...)
	}
	if len(schema.AnyOf) > 0 {
		required = append(required, collectRequired(schema.AnyOf[0], visited)...)
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

type localSchemaRegistry struct {
	// schemas contains one source document per canonical resource ID. The
	// compiler uses these IDs to resolve cross-document references without
	// contacting the network.
	schemas map[string][]byte
	// documents maps resource URLs to local files for references to documents
	// without an explicit $id and for the compiler's loader fallback.
	documents       map[string]string
	sourceDocuments map[string][]byte
	rootID          string
}

// kaptinlin treats URIs with a host as absolute references. A file URI has an
// empty host, so its relative-reference handling would otherwise leave refs
// such as "schemas/definitions.json" unresolved. Use a synthetic HTTPS URI
// only inside the compiler; source JSON and generated output retain the real
// file URI.
func normalizeCompilerURI(raw string) string {
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Scheme != "file" || parsed.Host != "" {
		return raw
	}
	parsed.Scheme = "https"
	parsed.Host = "helm-schema-tools.local"
	return parsed.String()
}

// normalizeCompilerReference normalizes a complete resource URI while
// preserving its JSON Pointer or anchor fragment. Relative references are
// deliberately left alone: the compiler resolves those against the
// normalized resource ID.
func normalizeCompilerReference(raw string, normalizedIDs map[string]string) string {
	resourceID, fragment, hasFragment := strings.Cut(raw, "#")
	normalizedID, ok := normalizedIDs[resourceID]
	if !ok {
		return raw
	}
	if hasFragment {
		return normalizedID + "#" + fragment
	}
	return normalizedID
}

// normalizeCompilerDocument applies URI normalization only to JSON Schema URI
// keywords. Rewriting raw bytes can accidentally alter descriptions, examples,
// or extension values that merely contain an ID-shaped string.
func normalizeCompilerDocument(contents []byte, normalizedIDs map[string]string) ([]byte, error) {
	document, err := decodeJSONDocument(contents)
	if err != nil {
		return nil, err
	}
	var visit func(any)
	visit = func(value any) {
		switch node := value.(type) {
		case map[string]any:
			for key, child := range node {
				if key == "$id" || key == "$ref" || key == "$dynamicRef" {
					if uri, ok := child.(string); ok {
						node[key] = normalizeCompilerReference(uri, normalizedIDs)
					}
				}
				visit(node[key])
			}
		case []any:
			for _, child := range node {
				visit(child)
			}
		}
	}
	visit(document)
	return json.Marshal(document)
}

func pointerPathSegment(segment string) string {
	return strings.NewReplacer("~", "~0", "/", "~1").Replace(segment)
}

func collectPropertyOrdersByPath(node *yaml.Node, path string, orders map[string][]string) {
	if node == nil {
		return
	}
	if node.Kind == yaml.DocumentNode {
		for _, child := range node.Content {
			collectPropertyOrdersByPath(child, path, orders)
		}
		return
	}
	if node.Kind == yaml.SequenceNode {
		for index, child := range node.Content {
			collectPropertyOrdersByPath(child, path+"/"+fmt.Sprint(index), orders)
		}
		return
	}
	if node.Kind != yaml.MappingNode {
		return
	}
	for i := 0; i < len(node.Content); i += 2 {
		keyNode := node.Content[i]
		valueNode := node.Content[i+1]
		key := keyNode.Value
		childPath := path + "/" + pointerPathSegment(key)
		if key == "properties" && valueNode.Kind == yaml.MappingNode {
			propertyNames := make([]string, 0, len(valueNode.Content)/2)
			for j := 0; j < len(valueNode.Content); j += 2 {
				propertyNames = append(propertyNames, valueNode.Content[j].Value)
			}
			orders[childPath] = propertyNames
		}
		collectPropertyOrdersByPath(valueNode, childPath, orders)
	}
}

// collectLocalSchemaResources maps schema IDs and local file URIs to source
// documents next to the root schema. The JSON Schema compiler, rather than
// this package, owns reference parsing and resolution.
func collectLocalSchemaResources(inputPath string) (*localSchemaRegistry, error) {
	root := filepath.Dir(inputPath)
	registry := &localSchemaRegistry{
		schemas:         make(map[string][]byte),
		documents:       make(map[string]string),
		sourceDocuments: make(map[string][]byte),
	}
	rootAbsolute, err := filepath.Abs(inputPath)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve root schema path: %w", err)
	}

	err = filepath.WalkDir(root, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		// Charts commonly expose their parent values.schema.json through a
		// test-chart symlink. It is not a separate schema resource; following it
		// would manufacture a duplicate $id and make resolution depend on the
		// directory layout rather than the reference graph.
		if entry.IsDir() || entry.Type()&os.ModeSymlink != 0 || filepath.Ext(path) != ".json" {
			return nil
		}

		contents, err := os.ReadFile(path) //nolint:gosec // path is rooted at the user-provided schema path
		if err != nil {
			return err
		}
		var resource any
		if err := json.Unmarshal(contents, &resource); err != nil {
			// Ignore unrelated or malformed JSON files in the schema directory.
			return nil
		}
		absolutePath, err := filepath.Abs(path)
		if err != nil {
			return err
		}
		fileURI := (&url.URL{Scheme: "file", Path: absolutePath}).String()
		resourceID := fileURI
		if resourceObject, ok := resource.(map[string]any); ok {
			if id, ok := resourceObject["$id"].(string); ok && id != "" {
				resourceID = id
			}
		}
		if existingPath, exists := registry.documents[resourceID]; exists && existingPath != absolutePath {
			return fmt.Errorf("duplicate schema resource ID %q in %q and %q", resourceID, existingPath, absolutePath)
		}
		registry.documents[fileURI] = absolutePath
		registry.schemas[resourceID] = contents
		registry.sourceDocuments[resourceID] = contents
		registry.documents[resourceID] = absolutePath
		if absolutePath == rootAbsolute {
			registry.rootID = resourceID
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("failed to collect local schema resources: %w", err)
	}

	if registry.rootID == "" {
		return nil, fmt.Errorf("root schema %q was not found in its directory", inputPath)
	}

	// kaptinlin's relative URI implementation requires a URI host. Normalize
	// local file IDs and any absolute file references for compiler use while
	// retaining the original source documents for serialization.
	rawSchemas := registry.schemas
	rawSources := registry.sourceDocuments
	registry.schemas = make(map[string][]byte, len(rawSchemas))
	registry.sourceDocuments = make(map[string][]byte, len(rawSources))
	normalizedIDs := make(map[string]string, len(rawSchemas))
	for resourceID := range rawSchemas {
		normalizedIDs[resourceID] = normalizeCompilerURI(resourceID)
	}
	for resourceID, contents := range rawSchemas {
		normalizedID := normalizedIDs[resourceID]
		normalizedContents, normalizeErr := normalizeCompilerDocument(contents, normalizedIDs)
		if normalizeErr != nil {
			return nil, fmt.Errorf("failed to normalize schema resource %q: %w", resourceID, normalizeErr)
		}
		registry.schemas[normalizedID] = normalizedContents
		registry.sourceDocuments[normalizedID] = rawSources[resourceID]
		registry.documents[normalizedID] = registry.documents[resourceID]
		if registry.rootID == resourceID {
			registry.rootID = normalizedID
		}
	}
	for documentURL, documentPath := range registry.documents {
		normalizedURL := normalizeCompilerURI(documentURL)
		registry.documents[normalizedURL] = documentPath
	}

	// A document without $id is identified by the URI used to load it. Add
	// aliases under the root document's URL so relative references can still be
	// loaded locally when their target has no explicit identifier.
	rootURL, err := url.Parse(registry.rootID)
	if err == nil {
		for documentURL, documentPath := range registry.documents {
			if documentURL == registry.rootID {
				continue
			}
			relativePath, relativeErr := filepath.Rel(root, documentPath)
			if relativeErr != nil {
				continue
			}
			alias := rootURL.ResolveReference(&url.URL{Path: filepath.ToSlash(relativePath)}).String()
			registry.documents[alias] = documentPath
		}
	}

	return registry, nil
}

func (r *localSchemaRegistry) load(uri string) (io.ReadCloser, error) {
	documentURL, err := url.Parse(uri)
	if err != nil {
		return nil, fmt.Errorf("invalid schema URI %q: %w", uri, err)
	}
	documentURL.Fragment = ""
	path, ok := r.documents[documentURL.String()]
	if !ok {
		return nil, fmt.Errorf("schema URI %q is not available in the local schema tree", documentURL.String())
	}
	file, err := os.Open(path) //nolint:gosec // path is selected from the local schema tree
	if err != nil {
		return nil, fmt.Errorf("open local schema %q: %w", path, err)
	}
	return file, nil
}

func newLocalCompiler(registry *localSchemaRegistry) *jsonschema.Compiler {
	compiler := jsonschema.NewCompiler().SetPreserveExtra(true)
	loader := func(uri string) (io.ReadCloser, error) { return registry.load(uri) }
	// Keep resolution offline and deterministic. These replace kaptinlin's
	// default network loaders with the local schema tree collected above.
	compiler.RegisterLoader("file", loader)
	compiler.RegisterLoader("http", loader)
	compiler.RegisterLoader("https", loader)
	return compiler
}

func copyReferenceStack(stack map[*jsonschema.Schema]bool, schema *jsonschema.Schema) map[*jsonschema.Schema]bool {
	next := make(map[*jsonschema.Schema]bool, len(stack)+1)
	maps.Copy(next, stack)
	next[schema] = true
	return next
}

type orderedObject struct {
	order  []string
	values map[string]any
}

// annotationKeywords are safe to expose directly on a dereferenced schema.
// They do not constrain validation, while retaining them here keeps generated
// documentation useful when a ref has a local description or default.
var annotationKeywords = map[string]struct{}{
	"$comment":    {},
	"title":       {},
	"description": {},
	"default":     {},
	"deprecated":  {},
	"readOnly":    {},
	"writeOnly":   {},
	"examples":    {},
}

func hasOnlyAnnotationKeywords(schema map[string]any) bool {
	for key := range schema {
		if _, ok := annotationKeywords[key]; !ok {
			return false
		}
	}
	return true
}

func copyAnnotations(destination, source map[string]any) {
	for key := range annotationKeywords {
		if value, ok := source[key]; ok {
			destination[key] = value
		}
	}
}

func refIgnoresSiblings(dialect jsonschema.Dialect) bool {
	return dialect == jsonschema.Draft4 || dialect == jsonschema.Draft6 || dialect == jsonschema.Draft7
}

func (o orderedObject) MarshalJSON() ([]byte, error) {
	keys := make([]string, 0, len(o.values))
	seen := make(map[string]bool, len(o.values))
	for _, key := range o.order {
		if _, exists := o.values[key]; exists && !seen[key] {
			keys = append(keys, key)
			seen[key] = true
		}
	}
	remaining := make([]string, 0, len(o.values)-len(keys))
	for key := range o.values {
		if !seen[key] {
			remaining = append(remaining, key)
		}
	}
	slices.Sort(remaining)
	keys = append(keys, remaining...)

	var output bytes.Buffer
	output.WriteByte('{')
	for index, key := range keys {
		if index > 0 {
			output.WriteByte(',')
		}
		encodedKey, err := json.Marshal(key)
		if err != nil {
			return nil, err
		}
		encodedValue, err := json.Marshal(o.values[key])
		if err != nil {
			return nil, err
		}
		output.Write(encodedKey)
		output.WriteByte(':')
		output.Write(encodedValue)
	}
	output.WriteByte('}')
	return output.Bytes(), nil
}

func decodeJSONDocument(contents []byte) (any, error) {
	decoder := json.NewDecoder(bytes.NewReader(contents))
	decoder.UseNumber()
	var document any
	if err := decoder.Decode(&document); err != nil {
		return nil, err
	}
	return document, nil
}

type sourceSchemaNode struct {
	object        map[string]any
	propertyOrder []string
}

func bindSourceSchema(
	s *jsonschema.Schema,
	source any,
	path string,
	nodes map[*jsonschema.Schema]sourceSchemaNode,
	propertyOrders map[string][]string,
	visited map[*jsonschema.Schema]bool,
) {
	if s == nil || visited[s] || s.Boolean != nil {
		return
	}
	object, ok := source.(map[string]any)
	if !ok {
		return
	}
	visited[s] = true
	nodes[s] = sourceSchemaNode{
		object:        object,
		propertyOrder: append([]string(nil), propertyOrders[path+"/properties"]...),
	}

	bindSourceSchemaSlice := func(key string, children []*jsonschema.Schema) {
		sourceItems, ok := object[key].([]any)
		if !ok {
			return
		}
		for index, child := range children {
			if index < len(sourceItems) {
				bindSourceSchema(child, sourceItems[index], path+"/"+pointerPathSegment(key)+"/"+fmt.Sprint(index), nodes, propertyOrders, visited)
			}
		}
	}
	bindSourceSchemaMap := func(key string, children map[string]*jsonschema.Schema) {
		sourceMap, ok := object[key].(map[string]any)
		if !ok {
			return
		}
		for name, child := range children {
			if sourceChild, exists := sourceMap[name]; exists {
				bindSourceSchema(child, sourceChild, path+"/"+pointerPathSegment(key)+"/"+pointerPathSegment(name), nodes, propertyOrders, visited)
			}
		}
	}
	bindSourceSchemaChild := func(key string, child *jsonschema.Schema) {
		if sourceChild, exists := object[key]; exists {
			bindSourceSchema(child, sourceChild, path+"/"+pointerPathSegment(key), nodes, propertyOrders, visited)
		}
	}

	forEachSchemaSliceChild(s, bindSourceSchemaSlice)
	forEachSchemaChild(s, bindSourceSchemaChild)
	forEachSchemaMapChild(s, bindSourceSchemaMap)
}

func materializeChild(out map[string]any, key string, child *jsonschema.Schema, stack map[*jsonschema.Schema]bool, sources map[*jsonschema.Schema]sourceSchemaNode) error {
	if child == nil {
		return nil
	}
	value, err := materializeSchema(child, stack, sources)
	if err != nil {
		return fmt.Errorf("materialize %s: %w", key, err)
	}
	out[key] = value
	return nil
}

func materializeChildSlice(out map[string]any, key string, children []*jsonschema.Schema, stack map[*jsonschema.Schema]bool, sources map[*jsonschema.Schema]sourceSchemaNode) error {
	if len(children) == 0 {
		return nil
	}
	values := make([]any, len(children))
	for i, child := range children {
		value, err := materializeSchema(child, stack, sources)
		if err != nil {
			return fmt.Errorf("materialize %s[%d]: %w", key, i, err)
		}
		values[i] = value
	}
	out[key] = values
	return nil
}

func materializeChildMap(out map[string]any, key string, children map[string]*jsonschema.Schema, order []string, stack map[*jsonschema.Schema]bool, sources map[*jsonschema.Schema]sourceSchemaNode) error {
	if len(children) == 0 {
		return nil
	}
	values := make(map[string]any, len(children))
	for name, child := range children {
		value, err := materializeSchema(child, stack, sources)
		if err != nil {
			return fmt.Errorf("materialize %s.%s: %w", key, name, err)
		}
		values[name] = value
	}
	if key == "properties" {
		out[key] = orderedObject{order: order, values: values}
	} else {
		out[key] = values
	}
	return nil
}

func schemaMapValues(value *jsonschema.SchemaMap) map[string]*jsonschema.Schema {
	if value == nil {
		return nil
	}
	return map[string]*jsonschema.Schema(*value)
}

// The jsonschema dependency exposes child schemas as several different Go
// shapes. Keeping their keyword mapping here gives source binding and
// materialization one authoritative traversal as the dependency evolves.
func forEachSchemaSliceChild(s *jsonschema.Schema, visit func(string, []*jsonschema.Schema)) {
	for _, child := range []struct {
		keyword string
		value   []*jsonschema.Schema
	}{
		{"allOf", s.AllOf},
		{"anyOf", s.AnyOf},
		{"oneOf", s.OneOf},
		{"prefixItems", s.PrefixItems},
	} {
		visit(child.keyword, child.value)
	}
}

func forEachSchemaMapChild(s *jsonschema.Schema, visit func(string, map[string]*jsonschema.Schema)) {
	for _, child := range []struct {
		keyword string
		value   map[string]*jsonschema.Schema
	}{
		{"$defs", s.Defs},
		{"properties", schemaMapValues(s.Properties)},
		{"patternProperties", schemaMapValues(s.PatternProperties)},
		{"dependentSchemas", s.DependentSchemas},
	} {
		visit(child.keyword, child.value)
	}
}

func forEachSchemaChild(s *jsonschema.Schema, visit func(string, *jsonschema.Schema)) {
	for _, child := range []struct {
		keyword string
		value   *jsonschema.Schema
	}{
		{"not", s.Not},
		{"if", s.If},
		{"then", s.Then},
		{"else", s.Else},
		{"items", s.Items},
		{"contains", s.Contains},
		{"additionalProperties", s.AdditionalProperties},
		{"propertyNames", s.PropertyNames},
		{"unevaluatedItems", s.UnevaluatedItems},
		{"unevaluatedProperties", s.UnevaluatedProperties},
		{"contentSchema", s.ContentSchema},
	} {
		visit(child.keyword, child.value)
	}
}

func materializeSchemaChildren(s *jsonschema.Schema, out map[string]any, stack map[*jsonschema.Schema]bool, sources map[*jsonschema.Schema]sourceSchemaNode) error {
	var materializeErr error
	forEachSchemaSliceChild(s, func(key string, children []*jsonschema.Schema) {
		if materializeErr == nil {
			materializeErr = materializeChildSlice(out, key, children, stack, sources)
		}
	})
	forEachSchemaChild(s, func(key string, child *jsonschema.Schema) {
		if materializeErr == nil {
			materializeErr = materializeChild(out, key, child, stack, sources)
		}
	})
	forEachSchemaMapChild(s, func(key string, children map[string]*jsonschema.Schema) {
		if materializeErr != nil {
			return
		}
		var order []string
		if key == "properties" {
			order = sources[s].propertyOrder
		}
		materializeErr = materializeChildMap(out, key, children, order, stack, sources)
	})
	return materializeErr
}

// materializeSchema expands ordinary $ref edges using kaptinlin's resolved
// schema graph. Recursive edges remain as $ref so recursive schemas stay
// finite. Dynamic references are deliberately retained: their target depends
// on dynamic scope and replacing them with the fallback target would change
// schema semantics.
func materializeSchema(s *jsonschema.Schema, stack map[*jsonschema.Schema]bool, sources map[*jsonschema.Schema]sourceSchemaNode) (any, error) {
	if s == nil {
		return nil, fmt.Errorf("nil schema")
	}
	if s.Boolean != nil {
		return *s.Boolean, nil
	}

	source, ok := sources[s]
	if ok {
		out := maps.Clone(source.object)
		return materializeSchemaObject(s, out, stack, sources)
	} else {
		encoded, err := json.Marshal(s)
		if err != nil {
			return nil, fmt.Errorf("encode schema: %w", err)
		}
		var out map[string]any
		if err := json.Unmarshal(encoded, &out); err != nil {
			return nil, fmt.Errorf("decode schema: %w", err)
		}
		return materializeSchemaObject(s, out, stack, sources)
	}
}

func materializeSchemaObject(s *jsonschema.Schema, out map[string]any, stack map[*jsonschema.Schema]bool, sources map[*jsonschema.Schema]sourceSchemaNode) (any, error) {

	if s.Ref != "" {
		if s.ResolvedRef == nil {
			return nil, fmt.Errorf("unresolved $ref %q", s.Ref)
		}
		if !stack[s.ResolvedRef] {
			target, err := materializeSchema(s.ResolvedRef, copyReferenceStack(stack, s), sources)
			if err != nil {
				return nil, fmt.Errorf("resolve $ref %q: %w", s.Ref, err)
			}
			// Draft-04 through Draft-07 specify that sibling keywords are
			// ignored for a $ref. Modern drafts instead compose them.
			if refIgnoresSiblings(s.Dialect()) {
				return target, nil
			}
			if targetObject, ok := target.(map[string]any); ok {
				delete(out, "$ref")
				if err := materializeSchemaChildren(s, out, copyReferenceStack(stack, s), sources); err != nil {
					return nil, err
				}
				if len(out) == 0 {
					return targetObject, nil
				}
				copyAnnotations(targetObject, out)
				if hasOnlyAnnotationKeywords(out) {
					return targetObject, nil
				}
				// In modern JSON Schema, $ref and its sibling keywords are
				// conjunctive. A shallow map merge lets a sibling overwrite a
				// referenced constraint (for example, string → integer), changing
				// validation semantics. Preserve the target's shape at this node
				// for downstream generators and put every non-annotation sibling
				// in an allOf branch.
				allOf, _ := targetObject["allOf"].([]any)
				targetObject["allOf"] = append(allOf, out)
				return targetObject, nil
			} else if targetBool, ok := target.(bool); ok {
				delete(out, "$ref")
				if err := materializeSchemaChildren(s, out, copyReferenceStack(stack, s), sources); err != nil {
					return nil, err
				}
				if len(out) == 0 {
					return targetBool, nil
				}
				allOf := []any{targetBool}
				if siblings, ok := out["allOf"].([]any); ok {
					allOf = append(allOf, siblings...)
				}
				out["allOf"] = allOf
			}
		}
		if stack[s.ResolvedRef] {
			return out, nil
		}
		return out, nil
	}
	if s.DynamicRef != "" && s.ResolvedDynamicRef == nil {
		return nil, fmt.Errorf("unresolved $dynamicRef %q", s.DynamicRef)
	}

	if err := materializeSchemaChildren(s, out, copyReferenceStack(stack, s), sources); err != nil {
		return nil, err
	}
	return out, nil
}

// DereferenceSchema resolves local JSON Schema references and emits a single
// schema document. Local sibling keywords override referenced keywords, which
// preserves the JSON Schema 2020-12 semantics used by this repository.
func DereferenceSchema(inputPath string) ([]byte, error) {
	registry, err := collectLocalSchemaResources(inputPath)
	if err != nil {
		return nil, err
	}
	compiler := newLocalCompiler(registry)
	compiled, err := compiler.CompileBatch(registry.schemas)
	if err != nil {
		return nil, fmt.Errorf("failed to compile schema resources: %w", err)
	}
	rootSchema, ok := compiled[registry.rootID]
	if !ok {
		return nil, fmt.Errorf("compiled root schema %q was not found", registry.rootID)
	}
	sources := make(map[*jsonschema.Schema]sourceSchemaNode)
	visited := make(map[*jsonschema.Schema]bool)
	for resourceID, resourceBytes := range registry.sourceDocuments {
		compiledSchema, exists := compiled[resourceID]
		if !exists {
			continue
		}
		source, decodeErr := decodeJSONDocument(resourceBytes)
		if decodeErr != nil {
			return nil, fmt.Errorf("failed to decode source schema %q: %w", resourceID, decodeErr)
		}
		var orderedDocument yaml.Node
		propertyOrders := make(map[string][]string)
		if decodeErr := yaml.Unmarshal(resourceBytes, &orderedDocument); decodeErr == nil {
			collectPropertyOrdersByPath(&orderedDocument, "", propertyOrders)
		}
		bindSourceSchema(compiledSchema, source, "", sources, propertyOrders, visited)
	}
	resolved, err := materializeSchema(rootSchema, nil, sources)
	if err != nil {
		return nil, fmt.Errorf("failed to materialize schema: %w", err)
	}
	return json.Marshal(resolved)
}
