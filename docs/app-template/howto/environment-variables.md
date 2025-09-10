# Environment Variables

## Set environment variables directly

Setting environment variables for a container can be done in several ways. The simplest is to define them directly in the container settings using the `env` field. This can be done with a list of key/value items or a dictionary of items:

**List of key / values items:**

```yaml
containers:
  main:
    env:
      - name: ENV_VAR_NAME
        value: "value"
      - name: ANOTHER_ENV_VAR
        value: "another value"
```

**Dictionary style:**

```yaml
containers:
  main:
    env:
      ENV_VAR_NAME: "value"
      ANOTHER_ENV_VAR: "another value"
```

### Environment variables ordering

Sometimes (for example, when relying on [dependent environment variables](https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/)) the order of the environment variables is important. In those cases it is possible to explicitly define environment variable dependency through the `dependsOn` field:

```yaml
containers:
  main:
    env:
      STATIC_ENV: 1
      DYNAMIC_ENV:
        valueFrom:
          fieldRef:
            fieldPath: spec.nodeName
        dependsOn: STATIC_ENV
      ORDERED_ENV:
        value: true
        dependsOn: STATIC_ENV
      DEPENDENT_ENV:
        value: moo_two
        dependsOn:
          - DYNAMIC_ENV
          - ORDERED_ENV
```

## ConfigMaps

You can also create a ConfigMap for shared environment variables:

```yaml
configMaps:
  app-config:
    data:
      ENV_VAR_NAME: "value"
      ANOTHER_ENV_VAR: "another value"

controllers:
  main:
    containers:
      main:
        envFrom:
          - configMapRef:
              # Reference an app-template ConfigMap
              identifier: app-config

              # Reference a preexisting ConfigMap
              # name: preexisting-configmap-name
```

## Secrets

Secrets are managed in the same way:

```yaml
secrets:
  app-secrets:
    SECRET_KEY: "s3cr3t"
controllers:
  main:
    containers:
      main:
        envFrom:
          - secretRef:
              identifier: app-secrets
```
