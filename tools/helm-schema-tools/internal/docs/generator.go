package docs

import (
	"bytes"
	"embed"
	"fmt"
	"maps"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"text/template"

	"github.com/bjw-s-labs/helm-charts/tools/helm-schema-tools/internal/fileutil"
	schemautil "github.com/bjw-s-labs/helm-charts/tools/helm-schema-tools/internal/schema"
	"github.com/kaptinlin/jsonschema"
)

//go:embed templates/*.tmpl templates/partials/*.tmpl
var templateFS embed.FS

// maxRecursionDepth caps recursion across all schema walks (page generation
// and property flattening) so cyclic or pathological schemas can't exhaust
// the stack.
const maxRecursionDepth = 32

// Generator generates markdown documentation from JSON Schema.
type Generator struct {
	OutputDir string
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
	if g.OutputDir == "" {
		return fmt.Errorf("output directory is empty")
	}
	schema, err := schemautil.Compile(schemaBytes)
	if err != nil {
		return err
	}

	if err := os.MkdirAll(g.OutputDir, 0o750); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	if err := g.generateIndex(schema); err != nil {
		return fmt.Errorf("failed to generate index: %w", err)
	}

	rootProperties := schemautil.CollectAllProperties(schema)
	if len(rootProperties) > 0 {
		keys := schemautil.SortedKeys(rootProperties)
		generatedPaths := make(map[string]string)
		for _, name := range keys {
			prop := rootProperties[name]
			if err := g.generatePropertyPageRecursive(name, prop, "", 1, generatedPaths); err != nil {
				return fmt.Errorf("failed to generate page for %s: %w", name, err)
			}
		}
	}

	return nil
}

// GenerateLlmsTxt produces an llms.txt file listing all documentation pages.
func (g *Generator) GenerateLlmsTxt(schemaBytes []byte, outputPath, baseURL string) error {
	schema, err := schemautil.Compile(schemaBytes)
	if err != nil {
		return err
	}

	ctx := LlmsTxtContext{BaseURL: baseURL}
	rootProperties := schemautil.CollectAllProperties(schema)
	if len(rootProperties) > 0 {
		keys := schemautil.SortedKeys(rootProperties)
		for _, key := range keys {
			prop := rootProperties[key]
			desc := ""
			if prop.Description != nil {
				d := *prop.Description
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
	props := schemautil.CollectAllProperties(schema)
	if len(props) > 0 {
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

// generatePropertyPageRecursive walks the schema tree, generating a page for
// each property and recursing into nested objects. The depth limit is a
// safety net against pathological schemas; exceeding it is an error so the
// generated documentation is never silently incomplete.
func (g *Generator) generatePropertyPageRecursive(name string, prop *jsonschema.Schema, parentPath string, depth int, generatedPaths map[string]string) error {
	if depth > maxRecursionDepth {
		return fmt.Errorf("schema nesting exceeds the supported documentation depth of %d at %q", maxRecursionDepth, name)
	}

	dirName := documentationSlug(name)
	currentPath := dirName
	if parentPath != "" {
		currentPath = parentPath + "/" + dirName
	}

	childPages := collectChildPages(prop)
	ctx, err := g.buildPageContext(name, prop, childPages)
	if err != nil {
		return err
	}
	outDir := filepath.Join(g.OutputDir, currentPath)

	// Guard against path traversal from untrusted schema property names.
	if !isSubPath(g.OutputDir, outDir) {
		return fmt.Errorf("property name %q escapes output directory", name)
	}
	if previousName, exists := generatedPaths[currentPath]; exists {
		return fmt.Errorf("properties %q and %q map to the same documentation path %q", previousName, name, currentPath)
	}
	generatedPaths[currentPath] = name

	if err := os.MkdirAll(outDir, 0o750); err != nil {
		return err
	}
	if err := g.renderToFile(filepath.Join(outDir, "index.mdx"), "property.mdx.tmpl", ctx); err != nil {
		return err
	}

	properties := schemautil.CollectAllProperties(prop)
	if len(properties) > 0 {
		subKeys := schemautil.SortedKeys(properties)
		for _, subName := range subKeys {
			subProp := properties[subName]
			if hasNestedContent(subProp) {
				if err := g.generatePropertyPageRecursive(subName, subProp, currentPath, depth+1, generatedPaths); err != nil {
					return fmt.Errorf("failed to generate sub-page for %s: %w", subName, err)
				}
			}
		}
	}

	if prop.AdditionalProperties != nil {
		allProps := schemautil.CollectAllProperties(prop.AdditionalProperties)
		subKeys := schemautil.SortedKeys(allProps)
		for _, subName := range subKeys {
			if _, alreadyHandled := properties[subName]; alreadyHandled {
				continue
			}
			subProp := allProps[subName]
			if hasNestedContent(subProp) {
				if err := g.generatePropertyPageRecursive(subName, subProp, currentPath, depth+1, generatedPaths); err != nil {
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

	example := ""
	if len(branch.Examples) > 0 {
		if s, ok := branch.Examples[0].(string); ok {
			example = s
		}
	}

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
func (g *Generator) buildPageContext(name string, prop *jsonschema.Schema, childPages []string) (PageContext, error) {
	ctx := PageContext{
		Name:        name,
		Description: description(prop),
		Schema:      prop,
		ChildPages:  childPages,
	}

	allProps := schemautil.CollectAllProperties(prop)
	if prop.AdditionalProperties != nil && len(allProps) == 0 {
		ctx.IsMap = true
		ctx.ParentName = name
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
				var err error
				np.SubProperties, err = collectSubProperties(allProps[key])
				if err != nil {
					return PageContext{}, err
				}
			}
			ctx.Properties = append(ctx.Properties, np)
		}
		return ctx, nil
	}

	if len(allProps) > 0 {
		keys := schemautil.SortedKeys(allProps)
		requiredSet := schemautil.MakeSet(schemautil.CollectAllRequired(prop))
		for _, key := range keys {
			hasPage := len(childPages) > 0 && slices.Contains(childPages, key)
			np := &NamedProperty{
				Key:        key,
				Schema:     allProps[key],
				Required:   requiredSet[key],
				HasSubPage: hasPage,
			}
			if !hasPage {
				var err error
				np.SubProperties, err = collectSubProperties(allProps[key])
				if err != nil {
					return PageContext{}, err
				}
			}
			ctx.Properties = append(ctx.Properties, np)
		}
	}

	return ctx, nil
}

// collectSubProperties recursively flattens all descendant properties of a
// schema for inline display. Nested keys use dotted paths (e.g.
// "spec.exec.command"). This ensures deep K8s API fields are visible even
// when the page depth limit prevents generating sub-pages for them.
func collectSubProperties(schema *jsonschema.Schema) ([]*NamedProperty, error) {
	return flattenProperties(schema, "", 0)
}

func flattenProperties(schema *jsonschema.Schema, prefix string, depth int) ([]*NamedProperty, error) {
	if depth > maxRecursionDepth {
		return nil, fmt.Errorf("schema nesting exceeds the supported documentation depth of %d below %q", maxRecursionDepth, prefix)
	}
	allProps := schemautil.CollectAllProperties(schema)
	if len(allProps) == 0 {
		return nil, nil
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
			nested, err := flattenProperties(child, fullKey, depth+1)
			if err != nil {
				return nil, err
			}
			props = append(props, nested...)
		} else {
			props = append(props, &NamedProperty{
				Key:      fullKey,
				Schema:   child,
				Required: requiredSet[key],
			})
		}
	}
	return props, nil
}

// collectChildPages returns a sorted list of child property names that warrant sub-pages.
func collectChildPages(prop *jsonschema.Schema) []string {
	children := make(map[string]struct{})
	for subName, subProp := range schemautil.CollectAllProperties(prop) {
		if hasNestedContent(subProp) {
			children[subName] = struct{}{}
		}
	}
	if prop.AdditionalProperties != nil {
		allProps := schemautil.CollectAllProperties(prop.AdditionalProperties)
		for subName, subProp := range allProps {
			if hasNestedContent(subProp) {
				children[subName] = struct{}{}
			}
		}
	}
	return slices.Sorted(maps.Keys(children))
}

// renderToFile executes a named template and writes the result to path.
func (g *Generator) renderToFile(path, tmplName string, data any) error {
	var buf bytes.Buffer
	if err := g.tmpl.ExecuteTemplate(&buf, tmplName, data); err != nil {
		return fmt.Errorf("template %s: %w", tmplName, err)
	}
	return fileutil.WriteFileAtomically(path, buf.Bytes(), 0o600)
}

// isSubPath returns true if child is rooted under parent.
func isSubPath(parent, child string) bool {
	rel, err := filepath.Rel(parent, child)
	if err != nil {
		return false
	}
	return rel != ".." && !strings.HasPrefix(rel, ".."+string(os.PathSeparator))
}
