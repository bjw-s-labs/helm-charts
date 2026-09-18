package schema

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
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

func TestDereferenceSchema_PreservesRefSibling(t *testing.T) {
	tmpDir := t.TempDir()
	rootPath := filepath.Join(tmpDir, "root.json")
	childPath := filepath.Join(tmpDir, "child.json")

	if err := os.WriteFile(rootPath, []byte(`{
		"$id": "https://example.test/root.json",
		"type": "object",
		"properties": {
			"value": {
				"$ref": "child.json",
				"description": "local description"
			}
		}
	}`), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(childPath, []byte(`{
		"$id": "https://example.test/child.json",
		"type": "string",
		"description": "target description"
	}`), 0o600); err != nil {
		t.Fatal(err)
	}

	output, err := DereferenceSchema(rootPath)
	if err != nil {
		t.Fatal(err)
	}
	var schema map[string]any
	if err := json.Unmarshal(output, &schema); err != nil {
		t.Fatal(err)
	}
	properties := schema["properties"].(map[string]any)
	value := properties["value"].(map[string]any)
	if _, exists := value["$ref"]; exists {
		t.Fatal("dereferenced property still contains $ref")
	}
	if got := value["description"]; got != "local description" {
		t.Errorf("description = %v, want local description", got)
	}
	if got := value["type"]; got != "string" {
		t.Errorf("type = %v, want string", got)
	}
}

func writeSchemaFile(t *testing.T, path, contents string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
}

func TestDereferenceSchema_ResolvesAnchor(t *testing.T) {
	tmpDir := t.TempDir()
	rootPath := filepath.Join(tmpDir, "root.json")
	childPath := filepath.Join(tmpDir, "child.json")

	writeSchemaFile(t, rootPath, `{
		"$id": "https://example.test/root.json",
		"type": "object",
		"properties": {
			"value": {"$ref": "child.json#value"}
		}
	}`)
	writeSchemaFile(t, childPath, `{
		"$id": "https://example.test/child.json",
		"$defs": {
			"value": {"$anchor": "value", "type": "string", "minLength": 1}
		}
	}`)

	output, err := DereferenceSchema(rootPath)
	if err != nil {
		t.Fatal(err)
	}
	var document map[string]any
	if err := json.Unmarshal(output, &document); err != nil {
		t.Fatal(err)
	}
	properties := document["properties"].(map[string]any)
	value := properties["value"].(map[string]any)
	if _, exists := value["$ref"]; exists {
		t.Fatal("anchored reference still contains $ref")
	}
	if got := value["type"]; got != "string" {
		t.Errorf("type = %v, want string", got)
	}
}

func TestDereferenceSchema_PreservesDynamicReference(t *testing.T) {
	tmpDir := t.TempDir()
	rootPath := filepath.Join(tmpDir, "root.json")

	writeSchemaFile(t, rootPath, `{
		"$id": "https://example.test/root.json",
		"$defs": {
			"node": {
				"$dynamicAnchor": "node",
				"type": "object",
				"properties": {"child": {"$dynamicRef": "#node"}}
			}
		},
		"$ref": "#/$defs/node"
	}`)

	output, err := DereferenceSchema(rootPath)
	if err != nil {
		t.Fatal(err)
	}
	var document map[string]any
	if err := json.Unmarshal(output, &document); err != nil {
		t.Fatal(err)
	}
	properties := document["properties"].(map[string]any)
	child := properties["child"].(map[string]any)
	if got := child["$dynamicRef"]; got != "#node" {
		t.Errorf("$dynamicRef = %v, want #node", got)
	}
}

func TestDereferenceSchema_RejectsUnresolvedReference(t *testing.T) {
	tmpDir := t.TempDir()
	rootPath := filepath.Join(tmpDir, "root.json")
	writeSchemaFile(t, rootPath, `{
		"$id": "https://example.test/root.json",
		"properties": {"value": {"$ref": "missing.json#/$defs/value"}}
	}`)

	_, err := DereferenceSchema(rootPath)
	if err == nil {
		t.Fatal("DereferenceSchema should reject an unresolved reference")
	}
	if !strings.Contains(err.Error(), `unresolved $ref "missing.json#/$defs/value"`) {
		t.Fatalf("error = %q, want unresolved reference context", err)
	}
}
