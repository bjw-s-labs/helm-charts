---
title: "Default Pod Options"
description: "Configure default options that apply to all Pods in the chart"
---

It is possible to configure default Pod options under the `defaultPodOptions` key. These options will be applied to all Pods specified in the chart values.

To see which fields can be configured, please take a look at the Chart values schema specific to your Common library version. The latest version can be found here: <https://github.com/bjw-s-labs/helm-charts/blob/main/charts/library/common/schemas/pod.json>

## Default value strategies

### Overwrite

The default strategy for configuring default Pod options is `overwrite`. This means that if a controller has an entry for a default Pod option it will be overwritten entirely by the Pod-specific configuration.

This behavior can be set explicitly by setting `defaultPodOptionsStrategy` to `overwrite`.

An (abbreviated) example of the `overwrite` strategy:

```yaml
defaultPodOptions:
  resources:
    requests:
      memory: 1Gi
      cpu: 150m

controllers:
  main:
    pod:
      resources:
        requests:
          cpu: 100m

    containers:
      main: ...
```

The expected `resources` field on the `main` Deployment is expected to look like this:

```yaml
resources:
  requests:
    cpu: 100m
```

### Merge

An alternative strategy for configuring default Pod options is `merge`. This means that if a Pod has an entry for a default Pod option it will be merged with the Pod-specific configuration.

This behavior can be set explicitly by setting `defaultPodOptionsStrategy` to `merge`.

An (abbreviated) example of the `merge` strategy:

```yaml
defaultPodOptionsStrategy: merge
defaultPodOptions:
  resources:
    requests:
      memory: 1Gi
      cpu: 150m

controllers:
  main:
    pod:
      resources:
        requests:
          cpu: 100m

    containers:
      main: ...
```

The expected `resources` field on the `main` Deployment is expected to look like this:

```yaml
resources:
  requests:
    memory: 1Gi
    cpu: 100m
```
