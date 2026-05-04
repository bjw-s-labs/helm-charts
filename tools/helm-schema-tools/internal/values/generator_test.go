package values

import (
	"regexp"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"
)

func TestGenerator_Generate_SimpleSchema(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"name": {
				"description": "The application name",
				"type": "string",
				"default": "my-app"
			},
			"replicas": {
				"description": "Number of replicas",
				"type": "integer",
				"default": 3
			},
			"enabled": {
				"description": "Enable the feature",
				"type": "boolean",
				"default": true
			}
		}
	}`)

	gen := NewGenerator()
	gen.SchemaPath = "test.schema.json"

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	// Check header
	if !strings.Contains(yaml, "yaml-language-server: $schema=test.schema.json") {
		t.Error("Missing yaml-language-server header")
	}

	// Check properties are present
	if !strings.Contains(yaml, "name: my-app") {
		t.Error("Missing name property with default value")
	}
	if !strings.Contains(yaml, "replicas: 3") {
		t.Error("Missing replicas property with default value")
	}
	if !strings.Contains(yaml, "enabled: true") {
		t.Error("Missing enabled property with default value")
	}

	// Check comments (helm-docs style)
	if !strings.Contains(yaml, "# -- The application name") {
		t.Error("Missing description comment for name")
	}
}

func TestGenerator_Generate_NestedObject(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"config": {
				"description": "Configuration options",
				"type": "object",
				"properties": {
					"debug": {
						"description": "Enable debug mode",
						"type": "boolean",
						"default": false
					}
				}
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	// Check nested property
	if !strings.Contains(yaml, "config:") {
		t.Error("Missing config object")
	}
	if !strings.Contains(yaml, "debug: false") {
		t.Error("Missing nested debug property")
	}
}

func TestGenerator_Generate_AdditionalProperties(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"controllers": {
				"description": "Controller definitions",
				"type": "object",
				"additionalProperties": {
					"type": "object",
					"properties": {
						"enabled": {"type": "boolean", "default": true}
					}
				}
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	// additionalProperties maps get a synthetic `main:` entry showing the
	// expected structure. Optional fields without defaults are commented out
	// so they don't trip mutual-exclusion or oneOf constraints.
	if !strings.Contains(yaml, "controllers:") {
		t.Error("Should have controllers key")
	}
	if !strings.Contains(yaml, "main:") {
		t.Errorf("additionalProperties should emit synthetic 'main:' example; got:\n%s", yaml)
	}
	if !strings.Contains(yaml, "enabled: true") {
		t.Errorf("default-valued fields should be present in the example; got:\n%s", yaml)
	}
}

func TestGenerator_Generate_RequiredFieldsExpanded(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"config": {
				"type": "object",
				"properties": {
					"requiredField": {"type": "string"}
				},
				"required": ["requiredField"]
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	// A simple optional object with a required unconstrained string is expanded:
	// the required field is emitted as a required dummy ("") since there are no
	// oneOf/anyOf constraints that a dummy value could violate.
	if !strings.Contains(yaml, "config:") {
		t.Errorf("Object with required unconstrained fields should be expanded; got:\n%s", yaml)
	}
	if !strings.Contains(yaml, `requiredField: ""`) {
		t.Errorf("Required string field should be emitted as empty dummy; got:\n%s", yaml)
	}
}

func TestGenerator_Generate_OptionalObjectWithOneOfAndRequiredString(t *testing.T) {
	// An optional object with oneOf composition and a required string field
	// must be skipped: emitting a dummy string value could satisfy the wrong
	// oneOf branch and make an otherwise-invalid document appear valid.
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"ref": {
				"type": "object",
				"required": ["kind"],
				"oneOf": [
					{"required": ["name"]},
					{"required": ["identifier"]}
				],
				"properties": {
					"kind":       {"type": "string"},
					"name":       {"type": "string"},
					"identifier": {"type": "string"}
				}
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	out := string(result)

	if strings.Contains(out, "ref:") {
		t.Errorf("Optional object with oneOf + required string should be skipped; got:\n%s", out)
	}
	// Regression guard: the old skip signal was `e.Key = ""` which leaked a
	// bare `: ` line into the output. Assert that every mapping line has a
	// non-empty key and that the document is valid YAML.
	assertNoEmptyKeyLine(t, out)
	assertValidYAML(t, result)
}

// bareColonLine matches indented lines that start with `:` — the artifact
// produced by the old empty-key bug.
var bareColonLine = regexp.MustCompile(`(?m)^\s*:\s`)

func assertNoEmptyKeyLine(t *testing.T, out string) {
	t.Helper()
	if loc := bareColonLine.FindStringIndex(out); loc != nil {
		t.Errorf("empty-key line detected at byte %d:\n%s", loc[0], out)
	}
}

func assertValidYAML(t *testing.T, raw []byte) {
	t.Helper()
	var v any
	if err := yaml.Unmarshal(raw, &v); err != nil {
		t.Fatalf("generated YAML is invalid: %v\n%s", err, string(raw))
	}
}

func TestTemplateDict(t *testing.T) {
	t.Run("valid pairs", func(t *testing.T) {
		got, err := templateDict("a", 1, "b", "x")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if got["a"] != 1 || got["b"] != "x" {
			t.Errorf("got %v, want {a:1 b:x}", got)
		}
	})
	t.Run("odd number of args", func(t *testing.T) {
		if _, err := templateDict("a"); err == nil {
			t.Error("expected error for odd argc")
		}
	})
	t.Run("non-string key", func(t *testing.T) {
		if _, err := templateDict(1, "v"); err == nil {
			t.Error("expected error for non-string key")
		}
	})
}

func TestGenerator_Generate_ArrayType(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"items": {
				"description": "List of items",
				"type": "array",
				"items": {"type": "string"}
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	// Arrays should render as []
	if !strings.Contains(yaml, "items: []") {
		t.Error("Array should be empty []")
	}
}

func TestGenerator_Generate_OptionalStringsCommentedOut(t *testing.T) {
	// Optional strings without a default are commented out; strings with a
	// default are emitted normally.
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"optional": {
				"description": "Optional string without default",
				"type": "string"
			},
			"withDefault": {
				"description": "String with default",
				"type": "string",
				"default": "hello"
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	if !strings.Contains(yaml, "# optional:") {
		t.Errorf("Optional string without default should be commented out; got:\n%s", yaml)
	}
	if !strings.Contains(yaml, "withDefault: hello") {
		t.Error("String with default should be present")
	}
}

func TestGenerator_Generate_NullableTypes(t *testing.T) {
	// Optional nullable scalars emit `null` rather than the schema default, so
	// chart templates that distinguish "unset" from "explicit zero" (via
	// `kindIs` or `hasKey`) keep working. Users who want the default can set
	// it explicitly; the values.yaml should not pre-fill a potentially
	// meaningful value on their behalf.
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"nullableString": {
				"description": "Can be string or null",
				"type": ["string", "null"],
				"default": "value"
			},
			"nullableInt": {
				"description": "Can be int or null",
				"type": ["integer", "null"],
				"default": 42
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	if !strings.Contains(yaml, "nullableString: null") {
		t.Errorf("Optional nullable string should emit null; got:\n%s", yaml)
	}
	if !strings.Contains(yaml, "nullableInt: null") {
		t.Errorf("Optional nullable integer should emit null; got:\n%s", yaml)
	}
}

func TestGenerator_Generate_RequiredNullableUsesDefault(t *testing.T) {
	// When the field is required, the schema default wins — emitting null
	// would leave the required field semantically "unset" in the chart.
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"required": ["timeout"],
		"properties": {
			"timeout": {
				"type": ["integer", "null"],
				"default": 30
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	if !strings.Contains(string(result), "timeout: 30") {
		t.Errorf("Required nullable integer should emit its default; got:\n%s", string(result))
	}
}

func TestGenerator_Generate_InferredObjectType(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"implicitObject": {
				"description": "Object without explicit type",
				"properties": {
					"nested": {"type": "string", "default": "test"}
				}
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	// Should infer object type from properties
	if !strings.Contains(yaml, "implicitObject:") {
		t.Error("Should generate implicitObject as object")
	}
	if !strings.Contains(yaml, "nested: test") {
		t.Error("Should include nested property")
	}
}

func TestGenerator_Generate_InferredArrayType(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"implicitArray": {
				"description": "Array without explicit type",
				"items": {"type": "string"}
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	// Should infer array type from items
	if !strings.Contains(yaml, "implicitArray: []") {
		t.Error("Should generate implicitArray as empty array")
	}
}

func TestGenerator_Generate_NumberWithFloatDefault(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"ratio": {
				"description": "A ratio value",
				"type": "number",
				"default": 0.5
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	if !strings.Contains(yaml, "ratio:") {
		t.Error("Should include ratio property")
	}
}

func TestGenerator_Generate_BooleanWithoutDefault(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"enabled": {
				"description": "Enable feature",
				"type": "boolean"
			},
			"debug": {
				"description": "Debug mode",
				"type": "boolean",
				"default": true
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	// Optional boolean without a default is commented out (consistent with
	// string/number handling) so it doesn't silently override chart defaults.
	if !strings.Contains(yaml, "# enabled:") {
		t.Error("Optional boolean without default should be commented out")
	}
	// Boolean with explicit default true should be emitted as-is.
	if !strings.Contains(yaml, "debug: true") {
		t.Error("Boolean with default true should be true")
	}
}

func TestGenerator_Generate_InvalidSchema(t *testing.T) {
	schema := []byte(`{invalid json`)

	gen := NewGenerator()

	_, err := gen.Generate(schema)
	if err == nil {
		t.Error("Expected error for invalid schema")
	}
	if !strings.Contains(err.Error(), "failed to compile schema") {
		t.Errorf("Expected compile error, got: %v", err)
	}
}

func TestGenerator_Generate_EmptySchema(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object"
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	// Should produce valid but minimal YAML
	if yaml == "" {
		t.Error("Should produce non-empty output")
	}
}

func TestWrapText(t *testing.T) {
	tests := []struct {
		name     string
		text     string
		width    int
		expected []string
	}{
		{
			name:     "short text",
			text:     "hello",
			width:    80,
			expected: []string{"hello"},
		},
		{
			name:     "exactly at width",
			text:     "hello world",
			width:    11,
			expected: []string{"hello world"},
		},
		{
			name:     "needs wrapping",
			text:     "this is a longer text that needs to be wrapped",
			width:    20,
			expected: []string{"this is a longer", "text that needs to", "be wrapped"},
		},
		{
			name:     "single long word",
			text:     "superlongwordthatcannotbewrapped",
			width:    10,
			expected: []string{"superlongwordthatcannotbewrapped"},
		},
		{
			name:     "empty text",
			text:     "",
			width:    80,
			expected: []string{""},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := wrapText(tt.text, tt.width)
			if len(result) != len(tt.expected) {
				t.Errorf("wrapText(%q, %d) returned %d lines, expected %d", tt.text, tt.width, len(result), len(tt.expected))
				return
			}
			for i, line := range result {
				if line != tt.expected[i] {
					t.Errorf("wrapText(%q, %d)[%d] = %q, expected %q", tt.text, tt.width, i, line, tt.expected[i])
				}
			}
		})
	}
}

func TestNewGenerator_Defaults(t *testing.T) {
	gen := NewGenerator()

	if gen.SchemaPath != "" {
		t.Errorf("Default SchemaPath should be empty, got %q", gen.SchemaPath)
	}
}

func TestGenerator_Generate_NullType(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"nullable": {
				"description": "Explicit null type",
				"type": "null"
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	// Null type should render as null
	if !strings.Contains(yaml, "nullable: null") {
		t.Error("Null type should render as null")
	}
}

func TestGenerator_Generate_UnknownType(t *testing.T) {
	// Schema with no type info at all
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"unknown": {
				"description": "No type specified"
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	// Unknown type should render as null
	if !strings.Contains(yaml, "unknown: null") {
		t.Error("Unknown type should render as null")
	}
}

func TestGenerator_Generate_OnlyNullTypes(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"alwaysNull": {
				"description": "Can only be null",
				"type": ["null"]
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	// Should handle array with only null type
	if !strings.Contains(yaml, "alwaysNull: null") {
		t.Error("Type array with only null should render as null")
	}
}

func TestGenerator_Generate_NumberWithoutDefault(t *testing.T) {
	// Optional integers without a default are commented out so they don't
	// trip Helm's schema validation while staying visible as documentation.
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"optionalNumber": {
				"description": "Optional number",
				"type": "integer"
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	if !strings.Contains(yaml, "# optionalNumber:") {
		t.Errorf("Optional integer without default should be commented out; got:\n%s", yaml)
	}
}

func TestGenerator_Generate_NestedArrayEmpty(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"level1": {
				"type": "object",
				"properties": {
					"level2": {
						"type": "object",
						"properties": {
							"items": {
								"type": "array",
								"items": {"type": "string"}
							}
						}
					}
				}
			}
		}
	}`)

	gen := NewGenerator()

	result, err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	yaml := string(result)

	if !strings.Contains(yaml, "items: []") {
		t.Error("Nested array should render as []")
	}
}
