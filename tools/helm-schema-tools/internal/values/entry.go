package values

// Entry is a single key-value pair in the generated values.yaml, with all
// rendering decisions already resolved. The template needs no schema logic.
type Entry struct {
	Key        string
	Comment    string   // helm-docs formatted comment lines (no leading "# ")
	Examples   []string // raw string examples, each may be multi-line
	Value      string   // scalar: `my-app`, `""`, `0`, `false`, `[]`, `{}`, `null`
	CommentOut bool     // emit `# key:` instead of `key: value`
	Children   []*Entry // non-nil → key is a mapping; Value is ignored

	// ExampleBlock is a rendered YAML fragment shown as commented-out lines
	// beneath `key: {}`. Used for `additionalProperties` map types so the
	// generated values.yaml stays schema-valid (empty map passes validation)
	// while still showing users the expected entry shape.
	ExampleBlock string
}

// allCommentedOut reports whether every direct child is commented out.
// Used by the template to emit `{}` instead of an empty mapping body.
func allCommentedOut(entries []*Entry) bool {
	if len(entries) == 0 {
		return false
	}
	for _, e := range entries {
		if !e.CommentOut {
			return false
		}
	}
	return true
}
