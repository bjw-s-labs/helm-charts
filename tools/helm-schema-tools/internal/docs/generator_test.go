package docs

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestGenerator_Generate_CreatesIndexAndPropertyPages(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"description": "Test schema description",
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
			},
			"name": {
				"description": "Application name",
				"type": "string",
				"default": "my-app"
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	// Check index.md exists
	indexPath := filepath.Join(tmpDir, "index.mdx")
	if _, err := os.Stat(indexPath); os.IsNotExist(err) {
		t.Error("index.md not created")
	}

	// Check property directories exist
	configDir := filepath.Join(tmpDir, "config")
	if _, err := os.Stat(configDir); os.IsNotExist(err) {
		t.Error("config directory not created")
	}

	nameDir := filepath.Join(tmpDir, "name")
	if _, err := os.Stat(nameDir); os.IsNotExist(err) {
		t.Error("name directory not created")
	}
}

func TestGenerator_Generate_IndexContent(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"controllers": {
				"description": "Controller definitions",
				"type": "object"
			},
			"service": {
				"description": "Service definitions",
				"type": "object"
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	indexContent, err := os.ReadFile(filepath.Join(tmpDir, "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read index.md: %v", err)
	}

	content := string(indexContent)

	// Check Starlight frontmatter
	if !strings.Contains(content, "title: Values Reference") {
		t.Error("Missing title in frontmatter")
	}
	if !strings.Contains(content, "order: 1") {
		t.Error("Missing sidebar order in frontmatter")
	}
	if !strings.Contains(content, "label: Overview") {
		t.Error("Missing sidebar label in frontmatter")
	}

	// Check table
	if !strings.Contains(content, "| Key | Type | Description |") {
		t.Error("Missing property table header")
	}

	// Check properties listed
	if !strings.Contains(content, "[`controllers`]") {
		t.Error("Missing controllers link")
	}
	if !strings.Contains(content, "[`service`]") {
		t.Error("Missing service link")
	}
}

func TestGenerator_Generate_AdditionalPropertiesDocumentation(t *testing.T) {
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
						"enabled": {
							"description": "Enable this controller",
							"type": "boolean",
							"default": true
						},
						"replicas": {
							"description": "Number of replicas",
							"type": "integer",
							"default": 1
						}
					}
				}
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "controllers", "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read controllers/index.md: %v", err)
	}

	contentStr := string(content)

	// Check usage section
	if !strings.Contains(contentStr, "## Usage") {
		t.Error("Missing Usage section")
	}

	// Check instance properties
	if !strings.Contains(contentStr, "## Instance Properties") {
		t.Error("Missing Instance Properties section")
	}

	// Check properties from additionalProperties
	if !strings.Contains(contentStr, "| `enabled`") {
		t.Error("Missing enabled property in table")
	}
	if !strings.Contains(contentStr, "| `replicas`") {
		t.Error("Missing replicas property in table")
	}
}

func TestGenerator_Generate_PropertyPageWithDetails(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"config": {
				"description": "Configuration options",
				"type": "object",
				"properties": {
					"longDescription": {
						"description": "This is a very long description that should appear in the Property Details section because it exceeds the truncation limit",
						"type": "string"
					}
				}
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "config", "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read config/index.md: %v", err)
	}

	contentStr := string(content)

	// Check Property Details section exists for long descriptions
	if !strings.Contains(contentStr, "### Property Details") {
		t.Error("Missing Property Details section")
	}
	if !strings.Contains(contentStr, "#### longDescription") {
		t.Error("Missing longDescription detail section")
	}
}

func TestCollectAllProperties_WithAllOf(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"controllers": {
				"type": "object",
				"additionalProperties": {
					"type": "object",
					"allOf": [
						{
							"properties": {
								"fromAllOf": {
									"description": "Property from allOf",
									"type": "string"
								}
							}
						}
					],
					"properties": {
						"direct": {
							"description": "Direct property",
							"type": "string"
						}
					}
				}
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "controllers", "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read controllers/index.md: %v", err)
	}

	contentStr := string(content)

	// Should include both direct and allOf properties
	if !strings.Contains(contentStr, "| `direct`") {
		t.Error("Missing direct property from schema")
	}
	if !strings.Contains(contentStr, "| `fromAllOf`") {
		t.Error("Missing property from allOf")
	}
}

func TestTruncateDescription(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		maxLen   int
		expected string
	}{
		{"short", "short", 10, "short"},
		{"long needs ellipsis", "this is a long description", 10, "this is..."},
		{"newlines collapsed", "with\nnewlines\nhere", 20, "with newlines here"},
		{"exactly at limit", "exactly ten", 11, "exactly ten"},
		// Regression guards added alongside the nil/panic/UTF-8 hardening pass.
		{"zero maxLen", "hello", 0, ""},
		{"negative maxLen", "hello", -5, ""},
		{"maxLen smaller than ellipsis", "abcdef", 2, "ab"},
		{"multibyte does not split runes", "héllo wörld", 8, "héllo..."},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := truncateDescription(tt.input, tt.maxLen)
			if result != tt.expected {
				t.Errorf("truncateDescription(%q, %d) = %q, want %q", tt.input, tt.maxLen, result, tt.expected)
			}
		})
	}
}

func TestTypeString_NilSchema(t *testing.T) {
	// Regression guard: typeString must not panic on nil input.
	if got := typeString(nil); got != "any" {
		t.Errorf("typeString(nil) = %q, want %q", got, "any")
	}
}

func TestDescription_NilSchema(t *testing.T) {
	// Regression guard: description must not panic on nil input.
	if got := description(nil); got != "" {
		t.Errorf("description(nil) = %q, want empty", got)
	}
}

func TestGenerator_Generate_OneOfSchema(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"persistence": {
				"type": "object",
				"additionalProperties": {
					"type": "object",
					"oneOf": [
						{
							"properties": {
								"type": {"type": "string", "const": "pvc", "description": "Type of persistence"},
								"enabled": {"type": "boolean", "description": "Enable persistence"}
							}
						}
					]
				}
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "persistence", "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read persistence/index.md: %v", err)
	}

	contentStr := string(content)

	// Const-discriminated oneOf branches are rendered as Type Variants tabs.
	if !strings.Contains(contentStr, "## Type Variants") {
		t.Error("Missing Type Variants section for const-discriminated oneOf")
	}
	if !strings.Contains(contentStr, "pvc") {
		t.Error("Missing variant tab label for pvc type")
	}
	// Properties from the variant should be listed.
	if !strings.Contains(contentStr, "| `enabled`") {
		t.Error("Missing enabled property from oneOf variant")
	}
}

func TestGenerator_Generate_AnyOfSchema(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"service": {
				"type": "object",
				"additionalProperties": {
					"type": "object",
					"anyOf": [
						{
							"properties": {
								"port": {"type": "integer", "description": "Service port"}
							}
						}
					]
				}
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "service", "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read service/index.md: %v", err)
	}

	contentStr := string(content)

	// Should include properties from anyOf
	if !strings.Contains(contentStr, "| `port`") {
		t.Error("Missing port property from anyOf")
	}
}

func TestGenerator_Generate_RequiredProperties(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"config": {
				"type": "object",
				"additionalProperties": {
					"type": "object",
					"properties": {
						"name": {"type": "string", "description": "The name"},
						"value": {"type": "string", "description": "The value"}
					},
					"required": ["name"]
				}
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "config", "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read config/index.md: %v", err)
	}

	contentStr := string(content)

	// Required property should be marked
	if !strings.Contains(contentStr, "| `name`") {
		t.Error("Missing name property")
	}
	if !strings.Contains(contentStr, "**Yes**") {
		t.Error("Required property should be marked with **Yes**")
	}
}

func TestGenerator_Generate_MultipleTypes(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"value": {
				"description": "Can be string or integer",
				"type": ["string", "integer"]
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	indexContent, err := os.ReadFile(filepath.Join(tmpDir, "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read index.md: %v", err)
	}

	content := string(indexContent)

	// Should show multiple types
	if !strings.Contains(content, "string / integer") {
		t.Error("Multiple types should be shown with / separator")
	}
}

func TestGenerator_Generate_EnumType(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"status": {
				"description": "Status value",
				"enum": ["active", "inactive", "pending"]
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	indexContent, err := os.ReadFile(filepath.Join(tmpDir, "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read index.md: %v", err)
	}

	content := string(indexContent)

	// Should detect enum type
	if !strings.Contains(content, "`enum`") {
		t.Error("Enum type should be detected")
	}
}

func TestGenerator_Generate_InferredTypes(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"inferredObject": {
				"description": "Has properties so should be object",
				"properties": {
					"nested": {"type": "string"}
				}
			},
			"inferredArray": {
				"description": "Has items so should be array",
				"items": {"type": "string"}
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	indexContent, err := os.ReadFile(filepath.Join(tmpDir, "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read index.md: %v", err)
	}

	content := string(indexContent)

	// Should show inferred object type
	if !strings.Contains(content, "[`inferredObject`]") {
		t.Error("Should include inferredObject")
	}
	// Should show inferred array type
	if !strings.Contains(content, "[`inferredArray`]") {
		t.Error("Should include inferredArray")
	}
}

func TestGenerator_Generate_WithExamples(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"port": {
				"description": "Port number",
				"type": "integer",
				"examples": [8080, 3000]
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "port", "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read port/index.md: %v", err)
	}

	contentStr := string(content)

	// Should include examples section
	if !strings.Contains(contentStr, "## Examples") {
		t.Error("Missing Examples section")
	}
}

func TestGenerator_Generate_WithDefaultValue(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"timeout": {
				"description": "Timeout in seconds",
				"type": "integer",
				"default": 30
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "timeout", "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read timeout/index.md: %v", err)
	}

	contentStr := string(content)

	// Should include default section
	if !strings.Contains(contentStr, "## Default") {
		t.Error("Missing Default section")
	}
	if !strings.Contains(contentStr, "30") {
		t.Error("Missing default value")
	}
}

func TestGenerator_Generate_StarlightPropertyFrontmatter(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"service": {
				"description": "Service configuration",
				"type": "object"
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	if err := gen.Generate(schema); err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "service", "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read service/index.md: %v", err)
	}

	contentStr := string(content)
	if !strings.Contains(contentStr, `title: "service"`) {
		t.Error("Missing quoted title in property page frontmatter")
	}
	if !strings.Contains(contentStr, `label: "service"`) {
		t.Error("Missing sidebar label in property page frontmatter")
	}
	// Should not generate _category_.json (Starlight uses frontmatter)
	if _, err := os.Stat(filepath.Join(tmpDir, "service", "_category_.json")); err == nil {
		t.Error("Should not generate _category_.json for Starlight")
	}
}

func TestGenerator_Generate_InvalidSchema(t *testing.T) {
	schema := []byte(`{invalid json`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err == nil {
		t.Error("Expected error for invalid schema")
	}
	if !strings.Contains(err.Error(), "failed to compile schema") {
		t.Errorf("Expected compile error, got: %v", err)
	}
}

func TestSortedKeys(t *testing.T) {
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"zebra": {"type": "string"},
			"alpha": {"type": "string"},
			"middle": {"type": "string"}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read index.md: %v", err)
	}

	contentStr := string(content)

	// Properties should be alphabetically sorted
	alphaIdx := strings.Index(contentStr, "alpha")
	middleIdx := strings.Index(contentStr, "middle")
	zebraIdx := strings.Index(contentStr, "zebra")

	if alphaIdx > middleIdx || middleIdx > zebraIdx {
		t.Error("Properties should be sorted alphabetically")
	}
}

func TestGenerator_Generate_NestedAllOf(t *testing.T) {
	// Test deeply nested allOf structure
	schema := []byte(`{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"complex": {
				"type": "object",
				"additionalProperties": {
					"type": "object",
					"allOf": [
						{
							"allOf": [
								{
									"properties": {
										"deepProp": {"type": "string", "description": "Deep property"}
									}
								}
							]
						}
					],
					"properties": {
						"topProp": {"type": "string", "description": "Top property"}
					}
				}
			}
		}
	}`)

	tmpDir := t.TempDir()
	gen := NewGenerator(tmpDir)

	err := gen.Generate(schema)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "complex", "index.mdx"))
	if err != nil {
		t.Fatalf("Failed to read complex/index.md: %v", err)
	}

	contentStr := string(content)

	// Should include both direct and nested allOf properties
	if !strings.Contains(contentStr, "| `topProp`") {
		t.Error("Missing topProp from direct properties")
	}
	if !strings.Contains(contentStr, "| `deepProp`") {
		t.Error("Missing deepProp from nested allOf")
	}
}
