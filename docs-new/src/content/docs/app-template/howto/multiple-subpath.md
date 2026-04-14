---
title: "Multiple subPaths for 1 volume"
description: "How to mount multiple subPaths from a single volume to containers"
sidebar:
  label: "Multiple SubPaths"
---

It is possible to mount multiple subPaths from the same volume to a
container. This can be achieved by specifying `subPath` with a list
instead of a string.

## Example

```yaml
persistence:
  config:
    type: configMap
    name: my-configMap
    advancedMounts:
      main: # the controller with the "main" identifier
        main: # the container with the "main" identifier
          - path: /data/config.yaml
            readOnly: false
            subPath: config.yaml
          - path: /data/secondConfigFile.yaml
            readOnly: false
            subPath: secondConfigFile.yaml
        second-container: # the container with the "second-container" identifier
          - path: /appdata/config
            readOnly: true
      second-controller: # the controller with the "second-controller" identifier
        main: # the container with the "main" identifier
          - path: /data/config.yaml
            readOnly: false
            subPath: config.yaml
```
