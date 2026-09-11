import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


HELPER = Path(__file__).with_name("prepare_schema_refs.py")


class PrepareSchemaRefsTest(unittest.TestCase):
    def test_rewrites_versioned_repository_urls_without_reserializing(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            schema_dir = root / "charts" / "example"
            schema_dir.mkdir(parents=True)
            schema = schema_dir / "values.schema.json"
            original = (
                "{\n"
                '  "$ref": "https://raw.githubusercontent.com/acme/charts/v1.2.3/charts/common.json",\n'
                '  "relative": "schemas/other.json",\n'
                '  "external": "https://raw.githubusercontent.com/other/project/v1/file.json"\n'
                "}\n"
            )
            schema.write_text(original)

            subprocess.run(
                [
                    sys.executable,
                    str(HELPER),
                    "--repository",
                    "acme/charts",
                    "--revision",
                    "0123456789abcdef",
                    "--root",
                    str(root),
                    "--path",
                    "charts",
                ],
                check=True,
            )

            self.assertEqual(
                schema.read_text(),
                original.replace(
                    "acme/charts/v1.2.3/", "acme/charts/0123456789abcdef/"
                ),
            )


if __name__ == "__main__":
    unittest.main()
