package fileutil

import (
	"os"
	"path/filepath"
	"testing"
)

func TestWriteFileAtomicallyReplacesExistingFile(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "output.yaml")
	if err := os.WriteFile(path, []byte("old"), 0o600); err != nil {
		t.Fatal(err)
	}

	if err := WriteFileAtomically(path, []byte("new"), 0o640); err != nil {
		t.Fatal(err)
	}

	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if got, want := string(contents), "new"; got != want {
		t.Errorf("contents = %q, want %q", got, want)
	}
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if got, want := info.Mode().Perm(), os.FileMode(0o640); got != want {
		t.Errorf("mode = %o, want %o", got, want)
	}
	matches, err := filepath.Glob(filepath.Join(filepath.Dir(path), ".output.yaml.tmp-*"))
	if err != nil {
		t.Fatal(err)
	}
	if len(matches) != 0 {
		t.Errorf("temporary files remain: %v", matches)
	}
}
