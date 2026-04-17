package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

// requireSchematoolsCLI skips the test when the external dereferencer is not on
// PATH. These end-to-end tests shell out to schematools-cli (installed via
// `mise install` in this repo) and would otherwise fail in bare environments.
func requireSchematoolsCLI(t *testing.T) {
	t.Helper()
	if _, err := exec.LookPath("schematools-cli"); err != nil {
		t.Skip("schematools-cli not found in PATH; run `mise install` to install")
	}
}

func TestRunGenerateValues_Success(t *testing.T) {
	requireSchematoolsCLI(t)
	// Create a temp directory with a test schema
	tmpDir := t.TempDir()
	schemaPath := filepath.Join(tmpDir, "test.schema.json")
	outputPath := filepath.Join(tmpDir, "values.yaml")

	schema := `{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"name": {
				"description": "Application name",
				"type": "string",
				"default": "my-app"
			}
		}
	}`

	if err := os.WriteFile(schemaPath, []byte(schema), 0o600); err != nil {
		t.Fatalf("Failed to write schema: %v", err)
	}

	err := runGenerateValues(schemaPath, outputPath, "")
	if err != nil {
		t.Fatalf("runGenerateValues failed: %v", err)
	}

	// Verify output exists
	if _, err := os.Stat(outputPath); os.IsNotExist(err) {
		t.Error("Output file not created")
	}

	// Verify content
	content, err := os.ReadFile(outputPath) //nolint:gosec // test reads from t.TempDir()
	if err != nil {
		t.Fatalf("Failed to read output: %v", err)
	}

	if len(content) == 0 {
		t.Error("Output file is empty")
	}
}

func TestRunGenerateValues_InvalidSchema(t *testing.T) {
	tmpDir := t.TempDir()
	schemaPath := filepath.Join(tmpDir, "invalid.json")
	outputPath := filepath.Join(tmpDir, "values.yaml")

	// Write invalid JSON
	if err := os.WriteFile(schemaPath, []byte("{invalid"), 0o600); err != nil {
		t.Fatalf("Failed to write schema: %v", err)
	}

	err := runGenerateValues(schemaPath, outputPath, "")
	if err == nil {
		t.Error("Expected error for invalid schema")
	}
}

func TestRunGenerateValues_MissingSchema(t *testing.T) {
	tmpDir := t.TempDir()
	outputPath := filepath.Join(tmpDir, "values.yaml")

	err := runGenerateValues("/nonexistent/schema.json", outputPath, "")
	if err == nil {
		t.Error("Expected error for missing schema file")
	}
}

func TestRunGenerateDocs_Success(t *testing.T) {
	requireSchematoolsCLI(t)
	tmpDir := t.TempDir()
	schemaPath := filepath.Join(tmpDir, "test.schema.json")
	outputDir := filepath.Join(tmpDir, "docs")

	schema := `{
		"$schema": "https://json-schema.org/draft/2020-12/schema",
		"type": "object",
		"properties": {
			"config": {
				"description": "Configuration",
				"type": "object"
			}
		}
	}`

	if err := os.WriteFile(schemaPath, []byte(schema), 0o600); err != nil {
		t.Fatalf("Failed to write schema: %v", err)
	}

	err := runGenerateDocs(schemaPath, outputDir)
	if err != nil {
		t.Fatalf("runGenerateDocs failed: %v", err)
	}

	// Verify index.mdx exists
	indexPath := filepath.Join(outputDir, "index.mdx")
	if _, err := os.Stat(indexPath); os.IsNotExist(err) {
		t.Error("index.mdx not created")
	}
}

func TestRunGenerateDocs_InvalidSchema(t *testing.T) {
	tmpDir := t.TempDir()
	schemaPath := filepath.Join(tmpDir, "invalid.json")
	outputDir := filepath.Join(tmpDir, "docs")

	if err := os.WriteFile(schemaPath, []byte("{invalid"), 0o600); err != nil {
		t.Fatalf("Failed to write schema: %v", err)
	}

	err := runGenerateDocs(schemaPath, outputDir)
	if err == nil {
		t.Error("Expected error for invalid schema")
	}
}

func TestRunGenerateDocs_MissingSchema(t *testing.T) {
	tmpDir := t.TempDir()
	outputDir := filepath.Join(tmpDir, "docs")

	err := runGenerateDocs("/nonexistent/schema.json", outputDir)
	if err == nil {
		t.Error("Expected error for missing schema file")
	}
}
