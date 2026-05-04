package main

import (
	"fmt"
	"os"

	"github.com/bjw-s-labs/helm-charts/tools/helm-schema-tools/internal/docs"
	"github.com/bjw-s-labs/helm-charts/tools/helm-schema-tools/internal/schema"
	"github.com/bjw-s-labs/helm-charts/tools/helm-schema-tools/internal/values"
	"github.com/spf13/cobra"
)

var version = "dev"

func main() {
	rootCmd := &cobra.Command{
		Use:     "helm-schema-tools",
		Short:   "Tools for generating files from Helm chart JSON schemas",
		Version: version,
	}

	rootCmd.AddCommand(generateCmd())

	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}

func generateCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "generate",
		Short: "Generate files from JSON schemas",
	}

	cmd.AddCommand(generateValuesCmd())
	cmd.AddCommand(generateDocsCmd())
	cmd.AddCommand(generateLlmsTxtCmd())

	return cmd
}

func generateLlmsTxtCmd() *cobra.Command {
	var (
		schemaPath string
		outputPath string
		baseURL    string
	)

	cmd := &cobra.Command{
		Use:   "llms-txt",
		Short: "Generate llms.txt from JSON schema",
		RunE: func(cmd *cobra.Command, args []string) error {
			return runGenerateLlmsTxt(schemaPath, outputPath, baseURL)
		},
	}

	cmd.Flags().StringVarP(&schemaPath, "schema", "s", "", "Path to the JSON schema file (required)")
	cmd.Flags().StringVarP(&outputPath, "output", "o", "", "Output path for llms.txt (required)")
	cmd.Flags().StringVar(&baseURL, "base-url", "", "Base URL for documentation links (required)")

	_ = cmd.MarkFlagRequired("schema")
	_ = cmd.MarkFlagRequired("output")
	_ = cmd.MarkFlagRequired("base-url")

	return cmd
}

func runGenerateLlmsTxt(schemaPath, outputPath, baseURL string) error {
	fmt.Printf("Dereferencing schema: %s\n", schemaPath)

	schemaBytes, err := schema.DereferenceSchema(schemaPath)
	if err != nil {
		return fmt.Errorf("failed to dereference schema: %w", err)
	}

	gen := docs.NewGenerator("")
	if err := gen.GenerateLlmsTxt(schemaBytes, outputPath, baseURL); err != nil {
		return fmt.Errorf("failed to generate llms.txt: %w", err)
	}

	fmt.Printf("Generated: %s\n", outputPath)
	return nil
}

func generateDocsCmd() *cobra.Command {
	var (
		schemaPath string
		outputDir  string
	)

	cmd := &cobra.Command{
		Use:   "docs",
		Short: "Generate markdown documentation from JSON schema",
		Long: `Generate markdown documentation pages from JSON Schema.

Creates an index page and individual pages for each top-level property,
with tables showing nested properties, types, and descriptions.

Example:
  helm-schema-tools generate docs \
    --schema charts/library/common/values.schema.json \
    --output docs/src/content/docs/reference/`,
		RunE: func(cmd *cobra.Command, args []string) error {
			return runGenerateDocs(schemaPath, outputDir)
		},
	}

	cmd.Flags().StringVarP(&schemaPath, "schema", "s", "", "Path to the JSON schema file (required)")
	cmd.Flags().StringVarP(&outputDir, "output", "o", "", "Output directory for documentation (required)")

	_ = cmd.MarkFlagRequired("schema")
	_ = cmd.MarkFlagRequired("output")

	return cmd
}

func runGenerateDocs(schemaPath, outputDir string) error {
	fmt.Printf("Dereferencing schema: %s\n", schemaPath)

	schemaBytes, err := schema.DereferenceSchema(schemaPath)
	if err != nil {
		return fmt.Errorf("failed to dereference schema: %w", err)
	}

	fmt.Printf("Generating documentation to: %s\n", outputDir)

	gen := docs.NewGenerator(outputDir)
	if err := gen.Generate(schemaBytes); err != nil {
		return fmt.Errorf("failed to generate docs: %w", err)
	}

	fmt.Println("Documentation generated successfully")
	return nil
}

func generateValuesCmd() *cobra.Command {
	var (
		schemaPath string
		outputPath string
		schemaRef  string
	)

	cmd := &cobra.Command{
		Use:   "values",
		Short: "Generate commented values.yaml from JSON schema",
		Long: `Generate a values.yaml file with comments derived from JSON Schema descriptions.

The schema is first dereferenced using schematools-cli to resolve all $ref references,
then converted to YAML with comments from the 'description' field of each property.

Example:
  helm-schema-tools generate values \
    --schema charts/library/common/values.schema.json \
    --output charts/library/common/values.yaml \
    --schema-ref values.schema.json`,
		RunE: func(cmd *cobra.Command, args []string) error {
			return runGenerateValues(schemaPath, outputPath, schemaRef)
		},
	}

	cmd.Flags().StringVarP(&schemaPath, "schema", "s", "", "Path to the JSON schema file (required)")
	cmd.Flags().StringVarP(&outputPath, "output", "o", "", "Output path for values.yaml (required)")
	cmd.Flags().StringVar(&schemaRef, "schema-ref", "",
		"Schema reference path in the YAML header (defaults to schema path)")

	_ = cmd.MarkFlagRequired("schema")
	_ = cmd.MarkFlagRequired("output")

	return cmd
}

func runGenerateValues(schemaPath, outputPath, schemaRef string) error {
	fmt.Printf("Dereferencing schema: %s\n", schemaPath)

	schemaBytes, err := schema.DereferenceSchema(schemaPath)
	if err != nil {
		return fmt.Errorf("failed to dereference schema: %w", err)
	}

	if schemaRef == "" {
		schemaRef = schemaPath
	}

	fmt.Println("Generating values.yaml")

	gen := values.NewGenerator()
	gen.SchemaPath = schemaRef

	yamlBytes, err := gen.Generate(schemaBytes)
	if err != nil {
		return fmt.Errorf("failed to generate YAML: %w", err)
	}

	if err := os.WriteFile(outputPath, yamlBytes, 0o600); err != nil {
		return fmt.Errorf("failed to write output: %w", err)
	}

	fmt.Printf("Generated: %s\n", outputPath)
	return nil
}
