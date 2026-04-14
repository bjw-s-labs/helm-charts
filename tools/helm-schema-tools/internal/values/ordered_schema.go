package values

import (
	"fmt"
	"slices"
	"strconv"

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
}

// NewOrderedSchema parses rawJSON and indexes property-declaration order at
// every `properties` object it contains.
func NewOrderedSchema(rawJSON []byte) (*OrderedSchema, error) {
	var doc yaml.Node
	if err := yaml.Unmarshal(rawJSON, &doc); err != nil {
		return nil, fmt.Errorf("parse schema for ordering: %w", err)
	}
	o := &OrderedSchema{orderByPath: map[string][]string{}}
	o.index(&doc, "")
	return o, nil
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
		childPath := path + "/" + k
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

// OrderKeys sorts keys using the declared order at propertiesPath. Any keys
// that have no declared position (typically keys merged in from `allOf` or
// `oneOf` branches) are appended in alphabetical order after the declared
// ones, keeping output deterministic.
func (o *OrderedSchema) OrderKeys(propertiesPath string, keys []string) []string {
	declared, ok := o.orderByPath[propertiesPath]
	if !ok || len(declared) == 0 {
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
