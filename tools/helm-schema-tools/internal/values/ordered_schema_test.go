package values

import (
	"strings"
	"testing"
)

func TestOrderedSchema_PreservesTopLevelOrder(t *testing.T) {
	raw := []byte(`{
		"type": "object",
		"properties": {
			"global": {"type": "object"},
			"defaultPodOptionsStrategy": {"type": "string"},
			"controllers": {"type": "object"},
			"rawResources": {"type": "object"}
		}
	}`)

	o, err := NewOrderedSchema(raw)
	if err != nil {
		t.Fatalf("NewOrderedSchema failed: %v", err)
	}

	// Request keys in a randomized alphabetic order.
	got := o.OrderKeys("/properties", []string{"controllers", "defaultPodOptionsStrategy", "global", "rawResources"})
	want := []string{"global", "defaultPodOptionsStrategy", "controllers", "rawResources"}
	if !equalStrings(got, want) {
		t.Fatalf("OrderKeys = %v, want %v", got, want)
	}
}

func TestOrderedSchema_UnknownKeysAppendedAlphabetically(t *testing.T) {
	raw := []byte(`{
		"type": "object",
		"properties": {
			"first": {"type": "string"},
			"second": {"type": "string"}
		}
	}`)
	o, _ := NewOrderedSchema(raw)

	// "extra" and "bonus" are unknown; they should come after declared keys
	// in alphabetical order.
	got := o.OrderKeys("/properties", []string{"second", "extra", "first", "bonus"})
	want := []string{"first", "second", "bonus", "extra"}
	if !equalStrings(got, want) {
		t.Fatalf("OrderKeys = %v, want %v", got, want)
	}
}

func TestOrderedSchema_UnknownPathFallsBackToAlphabetical(t *testing.T) {
	raw := []byte(`{"type": "object"}`)
	o, _ := NewOrderedSchema(raw)

	got := o.OrderKeys("/properties", []string{"b", "a", "c"})
	want := []string{"a", "b", "c"}
	if !equalStrings(got, want) {
		t.Fatalf("OrderKeys = %v, want %v", got, want)
	}
}

func TestOrderedSchema_NestedProperties(t *testing.T) {
	raw := []byte(`{
		"type": "object",
		"properties": {
			"controllers": {
				"type": "object",
				"additionalProperties": {
					"type": "object",
					"properties": {
						"enabled": {"type": "boolean"},
						"type": {"type": "string"},
						"replicas": {"type": "integer"}
					}
				}
			}
		}
	}`)
	o, _ := NewOrderedSchema(raw)

	got := o.OrderKeys("/properties/controllers/additionalProperties/properties",
		[]string{"replicas", "type", "enabled"})
	want := []string{"enabled", "type", "replicas"}
	if !equalStrings(got, want) {
		t.Fatalf("OrderKeys = %v, want %v", got, want)
	}
}

func TestGenerator_Generate_PreservesSchemaOrder(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"zebra": {"type": "string", "default": "z"},
			"alpha": {"type": "string", "default": "a"},
			"mango": {"type": "string", "default": "m"}
		}
	}`)
	g := NewGenerator()
	out, err := g.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}
	yaml := string(out)

	iZebra := strings.Index(yaml, "zebra:")
	iAlpha := strings.Index(yaml, "alpha:")
	iMango := strings.Index(yaml, "mango:")
	if iZebra < 0 || iAlpha < 0 || iMango < 0 {
		t.Fatalf("expected all three keys, got:\n%s", yaml)
	}
	// Declaration order is zebra, alpha, mango — not alphabetical.
	if iZebra >= iAlpha || iAlpha >= iMango {
		t.Errorf("keys not in declaration order (zebra < alpha < mango):\n%s", yaml)
	}
}

func TestGenerator_Generate_OptionalStringWithoutDefaultCommentedOut(t *testing.T) {
	// Optional strings without a default are commented out — the field stays
	// visible as documentation but doesn't trip Helm's schema validation or
	// mutual-exclusion (`not`) constraints.
	schema := []byte(`{
		"type": "object",
		"properties": {
			"hostname": {
				"description": "Pod hostname override",
				"type": "string"
			}
		}
	}`)
	g := NewGenerator()
	out, err := g.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}
	yaml := string(out)
	if !strings.Contains(yaml, "# hostname:") {
		t.Errorf("optional string without default should be commented out; got:\n%s", yaml)
	}
	if !strings.Contains(yaml, "# -- (string) Pod hostname override") {
		t.Errorf("description comment should be preserved with type hint; got:\n%s", yaml)
	}
	// Verify no raw YAML value is emitted for the commented-out field.
	if strings.Contains(yaml, "hostname: ") {
		t.Errorf("commented-out field should have no value; got:\n%s", yaml)
	}
}

func TestGenerator_Generate_RequiredStringWithoutDefaultEmitsDummy(t *testing.T) {
	// Required non-nullable strings without a default emit `""` so the
	// values.yaml stays valid — the field must be present for Helm.
	schema := []byte(`{
		"type": "object",
		"required": ["hostname"],
		"properties": {
			"hostname": {
				"description": "Pod hostname override",
				"type": "string"
			}
		}
	}`)
	g := NewGenerator()
	out, err := g.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}
	yaml := string(out)
	if !strings.Contains(yaml, `hostname: ""`) {
		t.Errorf("required string without default should emit empty dummy; got:\n%s", yaml)
	}
}

func TestGenerator_Generate_RequiredIntegerWithoutDefaultEmitsZero(t *testing.T) {
	schema := []byte(`{
		"type": "object",
		"required": ["port"],
		"properties": {
			"port": {
				"description": "Service port",
				"type": "integer"
			}
		}
	}`)
	g := NewGenerator()
	out, err := g.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}
	yaml := string(out)
	if !strings.Contains(yaml, "port: 0") {
		t.Errorf("required integer without default should emit `0`; got:\n%s", yaml)
	}
}

func TestGenerator_Generate_RequiredEnumWithoutDefaultPicksFirst(t *testing.T) {
	// Required enum strings without a default pick the first enum value so
	// the emitted dummy satisfies the enum constraint.
	schema := []byte(`{
		"type": "object",
		"required": ["policy"],
		"properties": {
			"policy": {
				"type": "string",
				"enum": ["Always", "Never", "OnFailure"]
			}
		}
	}`)
	g := NewGenerator()
	out, err := g.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}
	yaml := string(out)
	if !strings.Contains(yaml, "policy: Always") {
		t.Errorf("required enum should use first enum value as dummy; got:\n%s", yaml)
	}
}

func TestGenerator_Generate_NoTypeHintWhenValuePresent(t *testing.T) {
	schema := []byte(`{
		"type": "object",
		"properties": {
			"enabled": {
				"description": "Is enabled",
				"type": "boolean",
				"default": true
			}
		}
	}`)
	g := NewGenerator()
	out, err := g.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}
	yaml := string(out)
	// Booleans with a default render as a real value, so no type hint needed.
	if strings.Contains(yaml, "(bool)") {
		t.Errorf("unexpected type hint on field with concrete default; got:\n%s", yaml)
	}
	if !strings.Contains(yaml, "# -- Is enabled") {
		t.Errorf("expected plain `-- Is enabled` comment; got:\n%s", yaml)
	}
}

// equalStrings reports whether a and b contain the same elements in the same
// order.
func equalStrings(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}
