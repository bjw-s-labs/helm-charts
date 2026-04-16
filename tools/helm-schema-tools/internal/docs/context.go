package docs

import "github.com/kaptinlin/jsonschema"

// IndexContext is the template data for the index page.
type IndexContext struct {
	Description string
	Properties  []*NamedProperty
}

// PageContext is the template data for a single property page.
type PageContext struct {
	Name        string
	Description string
	Schema      *jsonschema.Schema
	Properties  []*NamedProperty // direct or instance properties, sorted
	ChildPages  []string
	IsMap       bool           // true when the property uses additionalProperties
	ParentName  string         // only set when IsMap is true
	Variants    []*TypeVariant // oneOf branches with const type fields
}

// NamedProperty pairs a property key with its schema and precomputed metadata.
type NamedProperty struct {
	Key           string
	Schema        *jsonschema.Schema
	Required      bool
	HasSubPage    bool
	SubProperties []*NamedProperty // populated when HasSubPage is false but schema has nested properties
}

// LlmsTxtContext is the template data for the llms.txt file.
type LlmsTxtContext struct {
	BaseURL    string
	Properties []LlmsTxtProperty
}

// LlmsTxtProperty is a top-level property entry for llms.txt.
type LlmsTxtProperty struct {
	Name        string
	Description string
}

// TypeVariant represents a oneOf branch selected by a const type field.
type TypeVariant struct {
	TypeValue   string
	Description string
	Example     string
	Properties  []*NamedProperty
}
