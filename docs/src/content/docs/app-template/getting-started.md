---
title: Getting Started
description: Deploy your first application using the app-template chart
---

## Prerequisites

- Helm 3.x installed
- A Kubernetes cluster (or a local one like kind/k3d)

## Add the Helm repository

```bash
helm repo add bjw-s https://bjw-s-labs.github.io/helm-charts
helm repo update
```

## Deploy an application

Create a `values.yaml` file:

```yaml
controllers:
  main:
    containers:
      main:
        image:
          repository: nginx
          tag: latest

service:
  main:
    controller: main
    ports:
      http:
        port: 80
```

Install the chart:

```bash
helm install my-app bjw-s/app-template -f values.yaml
```

## Enable IDE autocompletion

Add a `$schema` reference at the top of your values file for full autocompletion and validation:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/bjw-s-labs/helm-charts/main/charts/library/common/values.schema.json
controllers:
  main:
    # ...
```

## Next steps

- Browse the [Values Reference](./reference/) for all available options
- See [How-to guides](./howto/) for common configuration patterns
- Check out [Examples](./examples/) for complex deployments
