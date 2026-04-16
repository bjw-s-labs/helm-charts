package docs

import (
	"bytes"
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"text/template"

	schemautil "github.com/bjw-s-labs/helm-charts/tools/helm-schema-tools/internal/schema"
	"github.com/kaptinlin/jsonschema"
)

//go:embed templates/*.tmpl templates/partials/*.tmpl
var templateFS embed.FS

// maxFlattenDepth caps recursion in flattenProperties so pathological schemas
// (self-referential or extremely deep) can't exhaust the stack.
const maxFlattenDepth = 10

// Generator generates markdown documentation from JSON Schema.
type Generator struct {
	OutputDir string
	MaxDepth  int // max nesting depth for sub-pages (0 = unlimited)
	tmpl      *template.Template
}

// NewGenerator creates a new docs Generator with embedded templates.
func NewGenerator(outputDir string) *Generator {
	tmpl := template.Must(
		template.New("").Funcs(funcMap()).ParseFS(
			templateFS,
			"templates/*.tmpl",
			"templates/partials/*.tmpl",
		),
	)
	return &Generator{OutputDir: outputDir, tmpl: tmpl}
}

// Generate produces markdown documentation from a JSON Schema.
func (g *Generator) Generate(schemaBytes []byte) error {
	compiler := jsonschema.NewCompiler()
	schema, err := compiler.Compile(schemaBytes)
	if err != nil {
		return fmt.Errorf("failed to compile schema: %w", err)
	}

	if err := os.MkdirAll(g.OutputDir, 0o750); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	if err := g.generateIndex(schema); err != nil {
		return fmt.Errorf("failed to generate index: %w", err)
	}

	if schema.Properties != nil {
		keys := schemautil.SortedKeys(*schema.Properties)
		for _, name := range keys {
			prop := (*schema.Properties)[name]
			if err := g.generatePropertyPageRecursive(name, prop, "", 1); err != nil {
				return fmt.Errorf("failed to generate page for %s: %w", name, err)
			}
		}
	}

	return nil
}

// GenerateLlmsTxt produces an llms.txt file listing all documentation pages.
func (g *Generator) GenerateLlmsTxt(schemaBytes []byte, outputPath, baseURL string) error {
	compiler := jsonschema.NewCompiler()
	schema, err := compiler.Compile(schemaBytes)
	if err != nil {
		return fmt.Errorf("failed to compile schema: %w", err)
	}

	ctx := LlmsTxtContext{BaseURL: baseURL}
	if schema.Properties != nil {
		keys := schemautil.SortedKeys(*schema.Properties)
		for _, key := range keys {
			prop := (*schema.Properties)[key]
			desc := ""
			if prop.Description != nil {
				d := *prop.Description
				// Use first line only.
				if i := strings.Index(d, "\n"); i > 0 {
					d = d[:i]
				}
				desc = truncateDescription(d, 80)
			}
			ctx.Properties = append(ctx.Properties, LlmsTxtProperty{
				Name:        key,
				Description: desc,
			})
		}
	}

	return g.renderToFile(outputPath, "llms.txt.tmpl", ctx)
}

// generateIndex renders the index page from the schema's top-level properties.
func (g *Generator) generateIndex(schema *jsonschema.Schema) error {
	ctx := IndexContext{
		Description: description(schema),
	}
	if schema.Properties != nil {
		props := *schema.Properties
		keys := schemautil.SortedKeys(props)
		for _, key := range keys {
			ctx.Properties = append(ctx.Properties, &NamedProperty{
				Key:    key,
				Schema: props[key],
			})
		}
	}
	return g.renderToFile(filepath.Join(g.OutputDir, "index.mdx"), "index.mdx.tmpl", ctx)
}

// shouldRecurse returns true if sub-pages should be generated at this depth.
func (g *Generator) shouldRecurse(depth int) bool {
	return g.MaxDepth == 0 || depth < g.MaxDepth
}

// generatePropertyPageRecursive walks the schema tree, generating a page for
// each property and recursing into nested objects up to MaxDepth.
func (g *Generator) generatePropertyPageRecursive(name string, prop *jsonschema.Schema, parentPath string, depth int) error {
	// Use lowercase directory names to match Starlight's slug normalization.
	dirName := strings.ToLower(name)
	currentPath := dirName
	if parentPath != "" {
		currentPath = parentPath + "/" + dirName
	}

	canRecurse := g.shouldRecurse(depth)

	var childPages []string
	if canRecurse {
		childPages = collectChildPages(prop)
	}

	ctx := g.buildPageContext(name, prop, childPages)
	outDir := filepath.Join(g.OutputDir, currentPath)

	// Guard against path traversal from untrusted schema property names.
	if !isSubPath(g.OutputDir, outDir) {
		return fmt.Errorf("property name %q escapes output directory", name)
	}

	if err := os.MkdirAll(outDir, 0o750); err != nil {
		return err
	}
	if err := g.renderToFile(filepath.Join(outDir, "index.mdx"), "property.mdx.tmpl", ctx); err != nil {
		return err
	}

	if !canRecurse {
		return nil
	}

	// Recurse into nested object properties.
	if prop.Properties != nil {
		subKeys := schemautil.SortedKeys(*prop.Properties)
		for _, subName := range subKeys {
			subProp := (*prop.Properties)[subName]
			if hasNestedContent(subProp) {
				if err := g.generatePropertyPageRecursive(subName, subProp, currentPath, depth+1); err != nil {
					return fmt.Errorf("failed to generate sub-page for %s: %w", subName, err)
				}
			}
		}
	}

	// Recurse into additionalProperties.
	if prop.AdditionalProperties != nil {
		allProps := schemautil.CollectAllProperties(prop.AdditionalProperties)
		subKeys := schemautil.SortedKeys(allProps)
		for _, subName := range subKeys {
			subProp := allProps[subName]
			if hasNestedContent(subProp) {
				if err := g.generatePropertyPageRecursive(subName, subProp, currentPath, depth+1); err != nil {
					return fmt.Errorf("failed to generate sub-page for %s: %w", subName, err)
				}
			}
		}
	}

	return nil
}

// collectVariants extracts oneOf branches that use a const type field.
func (g *Generator) collectVariants(schema *jsonschema.Schema) []*TypeVariant {
	if schema == nil || len(schema.OneOf) == 0 {
		return nil
	}

	var variants []*TypeVariant
	for _, branch := range schema.OneOf {
		tv := extractTypeVariant(branch)
		if tv != nil {
			variants = append(variants, tv)
		}
	}

	// Count occurrences to detect duplicates, then disambiguate with a suffix.
	totals := map[string]int{}
	for _, tv := range variants {
		totals[tv.TypeValue]++
	}
	counters := map[string]int{}
	for _, tv := range variants {
		if totals[tv.TypeValue] > 1 {
			counters[tv.TypeValue]++
			tv.TypeValue = fmt.Sprintf("%s (%d)", tv.TypeValue, counters[tv.TypeValue])
		}
	}

	return variants
}

// extractTypeVariant checks if a schema branch has a const type field and extracts it.
func extractTypeVariant(branch *jsonschema.Schema) *TypeVariant {
	if branch == nil || branch.Properties == nil {
		return nil
	}
	props := *branch.Properties
	typeProp, ok := props["type"]
	if !ok || typeProp.Const == nil || !typeProp.Const.IsSet {
		return nil
	}

	typeValue := fmt.Sprintf("%v", typeProp.Const.Value)
	desc := ""
	if branch.Description != nil {
		desc = mdxSafe(*branch.Description)
	}

	// Use first example if available.
	example := ""
	if len(branch.Examples) > 0 {
		if s, ok := branch.Examples[0].(string); ok {
			example = s
		}
	}

	// Collect properties (excluding the type field itself).
	allProps := schemautil.CollectAllProperties(branch)
	allRequired := schemautil.CollectAllRequired(branch)
	requiredSet := schemautil.MakeSet(allRequired)
	keys := schemautil.SortedKeys(allProps)

	var namedProps []*NamedProperty
	for _, k := range keys {
		if k == "type" {
			continue
		}
		namedProps = append(namedProps, &NamedProperty{
			Key:      k,
			Schema:   allProps[k],
			Required: requiredSet[k],
		})
	}

	return &TypeVariant{
		TypeValue:   typeValue,
		Description: desc,
		Example:     example,
		Properties:  namedProps,
	}
}

// buildPageContext constructs the template data for a property page.
func (g *Generator) buildPageContext(name string, prop *jsonschema.Schema, childPages []string) PageContext {
	ctx := PageContext{
		Name:        name,
		Description: description(prop),
		Schema:      prop,
		ChildPages:  childPages,
	}

	// Map type (additionalProperties without direct properties).
	if prop.AdditionalProperties != nil && prop.Properties == nil {
		ctx.IsMap = true
		ctx.ParentName = name

		// Collect variants from oneOf branches with const type fields.
		ctx.Variants = g.collectVariants(prop.AdditionalProperties)

		allProps := schemautil.CollectAllProperties(prop.AdditionalProperties)
		allRequired := schemautil.CollectAllRequired(prop.AdditionalProperties)
		requiredSet := schemautil.MakeSet(allRequired)
		keys := schemautil.SortedKeys(allProps)
		for _, key := range keys {
			hasPage := len(childPages) > 0 && slices.Contains(childPages, key)
			np := &NamedProperty{
				Key:        key,
				Schema:     allProps[key],
				Required:   requiredSet[key],
				HasSubPage: hasPage,
			}
			if !hasPage {
				np.SubProperties = collectSubProperties(allProps[key])
			}
			ctx.Properties = append(ctx.Properties, np)
		}
		return ctx
	}

	// Regular object with defined properties.
	if prop.Properties != nil {
		props := *prop.Properties
		keys := schemautil.SortedKeys(props)
		// Use CollectAllRequired so required fields from allOf branches are included.
		requiredSet := schemautil.MakeSet(schemautil.CollectAllRequired(prop))
		for _, key := range keys {
			hasPage := len(childPages) > 0 && slices.Contains(childPages, key)
			np := &NamedProperty{
				Key:        key,
				Schema:     props[key],
				Required:   requiredSet[key],
				HasSubPage: hasPage,
			}
			if !hasPage {
				np.SubProperties = collectSubProperties(props[key])
			}
			ctx.Properties = append(ctx.Properties, np)
		}
	}

	return ctx
}

// collectSubProperties recursively flattens all descendant properties of a
// schema for inline display. Nested keys use dotted paths (e.g.
// "spec.exec.command"). This ensures deep K8s API fields are visible even
// when the page depth limit prevents generating sub-pages for them.
func collectSubProperties(schema *jsonschema.Schema) []*NamedProperty {
	return flattenProperties(schema, "", 0)
}

func flattenProperties(schema *jsonschema.Schema, prefix string, depth int) []*NamedProperty {
	if depth > maxFlattenDepth {
		return nil
	}
	allProps := schemautil.CollectAllProperties(schema)
	if len(allProps) == 0 {
		return nil
	}
	allRequired := schemautil.CollectAllRequired(schema)
	requiredSet := schemautil.MakeSet(allRequired)
	keys := schemautil.SortedKeys(allProps)
	var props []*NamedProperty
	for _, key := range keys {
		fullKey := key
		if prefix != "" {
			fullKey = prefix + "." + key
		}
		child := allProps[key]
		childProps := schemautil.CollectAllProperties(child)
		if len(childProps) > 0 {
			// Has nested properties — flatten them instead of showing as "object".
			props = append(props, flattenProperties(child, fullKey, depth+1)...)
		} else {
			props = append(props, &NamedProperty{
				Key:      fullKey,
				Schema:   child,
				Required: requiredSet[key],
			})
		}
	}
	return props
}

// collectChildPages returns a sorted list of child property names that warrant sub-pages.
func collectChildPages(prop *jsonschema.Schema) []string {
	var children []string
	if prop.Properties != nil {
		for subName, subProp := range *prop.Properties {
			if hasNestedContent(subProp) {
				children = append(children, subName)
			}
		}
	}
	if prop.AdditionalProperties != nil {
		allProps := schemautil.CollectAllProperties(prop.AdditionalProperties)
		for subName, subProp := range allProps {
			if hasNestedContent(subProp) {
				children = append(children, subName)
			}
		}
	}
	slices.Sort(children)
	return children
}

// renderToFile executes a named template and writes the result to path.
func (g *Generator) renderToFile(path, tmplName string, data any) error {
	var buf bytes.Buffer
	if err := g.tmpl.ExecuteTemplate(&buf, tmplName, data); err != nil {
		return fmt.Errorf("template %s: %w", tmplName, err)
	}
	return os.WriteFile(path, buf.Bytes(), 0o600)
}

// isSubPath returns true if child is rooted under parent after cleaning.
func isSubPath(parent, child string) bool {
	p := filepath.Clean(parent) + string(os.PathSeparator)
	c := filepath.Clean(child) + string(os.PathSeparator)
	return strings.HasPrefix(c, p)
}
