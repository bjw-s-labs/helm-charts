---
title: "Helm Templates"
description: "How to use Helm template expressions in common library values"
sidebar:
  label: "Helm Templates"
---

Some fields in the common library `values.yaml` allow the use of Helm templates for their values.
This is often indicated by a remark similar to `Helm template enabled` in the field description.

This feature allows you to set the value of that key to the output of the given Helm template.

## Example

Given the following `values.yaml`

```yaml
containers:
  subcleaner:
    name: subcleaner

    image:
      repository: k8s.gcr.io/git-sync/git-sync
      tag: {{.Chart.AppVersion}}

    args:
      - --repo=https://github.com/KBlixt/subcleaner.git
      - --branch=master
      - --depth=1
      - --root=/add-ons/subcleaner
```

This would render as follows:

```yaml
containers:
  subcleaner:
    name: subcleaner

    image:
      repository: k8s.gcr.io/git-sync/git-sync
      tag: v3.6.2

    args:
      - --repo=https://github.com/KBlixt/subcleaner.git
      - --branch=master
      - --depth=1
      - --root=/add-ons/subcleaner
```
