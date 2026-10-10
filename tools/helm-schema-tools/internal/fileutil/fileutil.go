// Package fileutil contains small filesystem helpers shared by commands and
// generators.
package fileutil

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

// WriteFileAtomically replaces path only after data has been fully written to
// and synced from a temporary file in the same directory. Keeping the
// temporary file beside the destination makes the final rename atomic on a
// single filesystem.
func WriteFileAtomically(path string, data []byte, perm fs.FileMode) error {
	tmp, err := os.CreateTemp(filepath.Dir(path), "."+filepath.Base(path)+".tmp-*")
	if err != nil {
		return fmt.Errorf("create temporary output file: %w", err)
	}
	tmpPath := tmp.Name()
	defer os.Remove(tmpPath)

	if err := tmp.Chmod(perm); err != nil {
		_ = tmp.Close()
		return fmt.Errorf("set temporary output file permissions: %w", err)
	}
	if _, err := tmp.Write(data); err != nil {
		_ = tmp.Close()
		return fmt.Errorf("write temporary output file: %w", err)
	}
	if err := tmp.Sync(); err != nil {
		_ = tmp.Close()
		return fmt.Errorf("sync temporary output file: %w", err)
	}
	if err := tmp.Close(); err != nil {
		return fmt.Errorf("close temporary output file: %w", err)
	}
	if err := os.Rename(tmpPath, path); err != nil {
		return fmt.Errorf("publish output file: %w", err)
	}
	return nil
}
