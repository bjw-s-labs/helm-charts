package values

import (
	"encoding/json"
	"fmt"
	"slices"
	"strconv"
	"strings"

	"github.com/kaptinlin/jsonschema"
	"gopkg.in/yaml.v3"
)

// OrderedSchema indexes property-declaration order from a raw JSON Schema so
// generated values.yaml preserves the semantic grouping of the schema author
// (e.g. `global` before `rbac`) instead of falling back to alphabetical order.
// It parses the raw bytes into a yaml.Node tree (JSON is a subset of YAML) to
// record key order, since the jsonschema compiler exposes properties via a Go
// map which does not preserve insertion order.
type OrderedSchema struct {
	// orderByPath maps a JSON path ending in `/properties` to the ordered
	// list of property keys declared at that path.
	orderByPath map[string][]string
	// schemaPaths maps compiled schema nodes back to their paths in the
	// dereferenced document. Generator paths are logical value paths and can
	// flatten allOf/oneOf branches, so they are not always usable as JSON paths.
	schemaPaths map[*jsonschema.Schema][]string
	raw         any
}

// NewOrderedSchema parses rawJSON and indexes property-declaration order at
// every `properties` object it contains.
func NewOrderedSchema(rawJSON []byte) (*OrderedSchema, error) {
	var doc yaml.Node
	if err := yaml.Unmarshal(rawJSON, &doc); err != nil {
		return nil, fmt.Errorf("parse schema for ordering: %w", err)
	}
	var raw any
	if err := json.Unmarshal(rawJSON, &raw); err != nil {
		return nil, fmt.Errorf("decode schema for ordering: %w", err)
	}
	o := &OrderedSchema{
		orderByPath: map[string][]string{},
		schemaPaths: map[*jsonschema.Schema][]string{},
		raw:         raw,
	}
	o.index(&doc, "")
	return o, nil
}

// BindCompiledSchema records the raw-document path(s) for each compiled
// schema node. This lets the values generator retain declaration order for
// objects whose visible properties come from composition branches.
func (o *OrderedSchema) BindCompiledSchema(root *jsonschema.Schema) {
	if root == nil {
		return
	}
	o.bindCompiledSchema(root, o.raw, "", map[*jsonschema.Schema]bool{})
}

func (o *OrderedSchema) bindCompiledSchema(s *jsonschema.Schema, source any, path string, stack map[*jsonschema.Schema]bool) {
	if s == nil || s.Boolean != nil || stack[s] {
		return
	}
	object, ok := source.(map[string]any)
	if !ok {
		return
	}
	o.schemaPaths[s] = append(o.schemaPaths[s], path)
	nextStack := make(map[*jsonschema.Schema]bool, len(stack)+1)
	for node := range stack {
		nextStack[node] = true
	}
	nextStack[s] = true

	bindSlice := func(key string, children []*jsonschema.Schema) {
		items, ok := object[key].([]any)
		if !ok {
			return
		}
		for index, child := range children {
			if index < len(items) {
				o.bindCompiledSchema(child, items[index], path+"/"+orderedSchemaPathSegment(key)+"/"+strconv.Itoa(index), nextStack)
			}
		}
	}
	bindMap := func(key string, children map[string]*jsonschema.Schema) {
		items, ok := object[key].(map[string]any)
		if !ok {
			return
		}
		for name, child := range children {
			if item, exists := items[name]; exists {
				o.bindCompiledSchema(child, item, path+"/"+orderedSchemaPathSegment(key)+"/"+orderedSchemaPathSegment(name), nextStack)
			}
		}
	}
	bindChild := func(key string, child *jsonschema.Schema) {
		if item, exists := object[key]; exists {
			o.bindCompiledSchema(child, item, path+"/"+orderedSchemaPathSegment(key), nextStack)
		}
	}

	bindSlice("allOf", s.AllOf)
	bindSlice("oneOf", s.OneOf)
	bindSlice("anyOf", s.AnyOf)
	bindSlice("prefixItems", s.PrefixItems)
	if s.Properties != nil {
		bindMap("properties", map[string]*jsonschema.Schema(*s.Properties))
	}
	if s.PatternProperties != nil {
		bindMap("patternProperties", map[string]*jsonschema.Schema(*s.PatternProperties))
	}
	bindMap("$defs", map[string]*jsonschema.Schema(s.Defs))
	bindMap("dependentSchemas", s.DependentSchemas)
	for key, child := range map[string]*jsonschema.Schema{
		"not":                   s.Not,
		"if":                    s.If,
		"then":                  s.Then,
		"else":                  s.Else,
		"items":                 s.Items,
		"contains":              s.Contains,
		"additionalProperties":  s.AdditionalProperties,
		"propertyNames":         s.PropertyNames,
		"unevaluatedItems":      s.UnevaluatedItems,
		"unevaluatedProperties": s.UnevaluatedProperties,
		"contentSchema":         s.ContentSchema,
	} {
		bindChild(key, child)
	}
}

// index recursively walks the parsed schema and records property orderings.
func (o *OrderedSchema) index(node *yaml.Node, path string) {
	if node == nil {
		return
	}
	if node.Kind == yaml.DocumentNode {
		for _, c := range node.Content {
			o.index(c, path)
		}
		return
	}
	if node.Kind != yaml.MappingNode {
		// Sequences may contain schemas (e.g. allOf items); recurse into them.
		if node.Kind == yaml.SequenceNode {
			for i, c := range node.Content {
				o.index(c, path+"/"+strconv.Itoa(i))
			}
		}
		return
	}
	for i := 0; i < len(node.Content); i += 2 {
		keyNode := node.Content[i]
		valueNode := node.Content[i+1]
		k := keyNode.Value
		childPath := path + "/" + orderedSchemaPathSegment(k)
		if k == "properties" && valueNode.Kind == yaml.MappingNode {
			keys := make([]string, 0, len(valueNode.Content)/2)
			for j := 0; j < len(valueNode.Content); j += 2 {
				keys = append(keys, valueNode.Content[j].Value)
			}
			o.orderByPath[childPath] = keys
		}
		o.index(valueNode, childPath)
	}
}

func orderedSchemaPathSegment(segment string) string {
	return strings.NewReplacer("~", "~0", "/", "~1").Replace(segment)
}

// OrderKeys sorts keys using the declared order at propertiesPath. Any keys
// that have no declared position (typically keys merged in from `allOf` or
// `oneOf` branches) are appended in alphabetical order after the declared
// ones, keeping output deterministic.
func (o *OrderedSchema) OrderKeys(propertiesPath string, keys []string) []string {
	basePath := strings.TrimSuffix(propertiesPath, "/properties")
	if declared := o.bestDeclaration(basePath, keys); len(declared) > 0 {
		return orderKeysByDeclaration(declared, keys)
	}
	return orderKeysByDeclaration(nil, keys)
}

// OrderKeysForSchema uses the compiled schema node when available. This is
// more precise than the logical generator path for schemas that flatten
// composition branches while collecting visible properties.
func (o *OrderedSchema) OrderKeysForSchema(schemaNode *jsonschema.Schema, propertiesPath string, keys []string) []string {
	if schemaNode != nil {
		if declared := o.bestDeclarationForPaths(o.schemaPaths[schemaNode], keys); len(declared) > 0 {
			return orderKeysByDeclaration(declared, keys)
		}
	}
	return o.OrderKeys(propertiesPath, keys)
}

// bestDeclaration selects among declarations belonging to one schema node.
// This is intentionally path-local: a common field name in an unrelated $def
// must not influence the ordering of the current object. Ties retain source
// traversal order, with the node's direct properties considered first.
func (o *OrderedSchema) bestDeclaration(schemaPath string, keys []string) []string {
	return o.bestDeclarationForPaths([]string{schemaPath}, keys)
}

func (o *OrderedSchema) bestDeclarationForPaths(schemaPaths []string, keys []string) []string {
	var best []string
	bestScore := 0
	for _, schemaPath := range schemaPaths {
		for _, declared := range o.declarationCandidates(schemaPath) {
			score := declarationOverlap(declared, keys)
			if score > bestScore {
				best = declared
				bestScore = score
			}
		}
	}
	return best
}

func declarationOverlap(declared, keys []string) int {
	keySet := make(map[string]struct{}, len(keys))
	for _, key := range keys {
		keySet[key] = struct{}{}
	}
	score := 0
	for _, key := range declared {
		if _, exists := keySet[key]; exists {
			score++
		}
	}
	return score
}

func (o *OrderedSchema) declarationCandidates(schemaPath string) [][]string {
	var candidates [][]string
	if declared := o.orderByPath[schemaPath+"/properties"]; len(declared) > 0 {
		candidates = append(candidates, declared)
	}

	var appendBranches func(string, bool)
	appendBranches = func(keyword string, firstOnly bool) {
		prefix := schemaPath + "/" + keyword + "/"
		indices := map[int]bool{}
		for path := range o.orderByPath {
			if !strings.HasPrefix(path, prefix) {
				continue
			}
			remainder := strings.TrimPrefix(path, prefix)
			indexText, _, _ := strings.Cut(remainder, "/")
			index, err := strconv.Atoi(indexText)
			if err == nil {
				indices[index] = true
			}
		}
		orderedIndices := make([]int, 0, len(indices))
		for index := range indices {
			orderedIndices = append(orderedIndices, index)
		}
		slices.Sort(orderedIndices)
		for _, index := range orderedIndices {
			if firstOnly && index > 0 {
				break
			}
			branchPath := prefix + strconv.Itoa(index)
			candidates = append(candidates, o.declarationCandidates(branchPath)...)
		}
	}

	appendBranches("allOf", false)
	appendBranches("oneOf", true)
	appendBranches("anyOf", true)
	return candidates
}

func orderKeysByDeclaration(declared, keys []string) []string {
	if len(declared) == 0 {
		out := append([]string(nil), keys...)
		slices.Sort(out)
		return out
	}
	pos := make(map[string]int, len(declared))
	for i, k := range declared {
		pos[k] = i
	}
	known := make([]string, 0, len(keys))
	unknown := make([]string, 0)
	for _, k := range keys {
		if _, exists := pos[k]; exists {
			known = append(known, k)
		} else {
			unknown = append(unknown, k)
		}
	}
	slices.SortStableFunc(known, func(a, b string) int {
		return pos[a] - pos[b]
	})
	slices.Sort(unknown)
	return append(known, unknown...)
}
