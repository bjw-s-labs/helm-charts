package schema

import (
	"testing"

	"github.com/kaptinlin/jsonschema"
)

func TestMakeSet(t *testing.T) {
	input := []string{"a", "b", "c"}
	result := MakeSet(input)

	if !result["a"] || !result["b"] || !result["c"] {
		t.Error("MakeSet should contain all input elements")
	}
	if result["d"] {
		t.Error("MakeSet should not contain elements not in input")
	}
	if len(result) != 3 {
		t.Errorf("MakeSet should have 3 elements, got %d", len(result))
	}
}

func TestMakeSet_Empty(t *testing.T) {
	result := MakeSet(nil)
	if len(result) != 0 {
		t.Error("MakeSet of nil should be empty")
	}

	result = MakeSet([]string{})
	if len(result) != 0 {
		t.Error("MakeSet of empty slice should be empty")
	}
}

func TestSortedKeys(t *testing.T) {
	m := map[string]*jsonschema.Schema{
		"zebra":  {},
		"alpha":  {},
		"middle": {},
	}
	keys := SortedKeys(m)

	if len(keys) != 3 {
		t.Fatalf("Expected 3 keys, got %d", len(keys))
	}
	if keys[0] != "alpha" || keys[1] != "middle" || keys[2] != "zebra" {
		t.Errorf("Expected [alpha, middle, zebra], got %v", keys)
	}
}

func TestCollectAllRequired(t *testing.T) {
	schema := &jsonschema.Schema{
		Required: []string{"a", "b"},
		AllOf: []*jsonschema.Schema{
			{Required: []string{"c"}},
		},
	}
	required := CollectAllRequired(schema)
	if len(required) != 3 {
		t.Fatalf("Expected 3 required, got %d", len(required))
	}

	set := MakeSet(required)
	for _, key := range []string{"a", "b", "c"} {
		if !set[key] {
			t.Errorf("Expected required to contain %q", key)
		}
	}
}

func TestHasAnyProperties_Nil(t *testing.T) {
	if HasAnyProperties(nil) {
		t.Error("HasAnyProperties(nil) should return false")
	}
}

func TestHasAnyProperties_Direct(t *testing.T) {
	props := jsonschema.SchemaMap{"foo": {}}
	schema := &jsonschema.Schema{Properties: &props}
	if !HasAnyProperties(schema) {
		t.Error("HasAnyProperties should return true for schema with properties")
	}
}

func TestHasAnyProperties_ViaAllOf(t *testing.T) {
	props := jsonschema.SchemaMap{"foo": {}}
	schema := &jsonschema.Schema{
		AllOf: []*jsonschema.Schema{
			{Properties: &props},
		},
	}
	if !HasAnyProperties(schema) {
		t.Error("HasAnyProperties should return true for schema with allOf properties")
	}
}
