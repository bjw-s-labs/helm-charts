set shell := ["bash", "-euo", "pipefail", "-c"]

serve:
  mkdocs serve -c -f .ci/mkdocs/mkdocs.yml

install_prereqs:
  pip install -r docs/requirements.txt
