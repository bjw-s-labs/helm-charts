# Environment Variables

## Set environment variables directly

Setting environment variables for a container can be done in several ways. The simplest is to define them directly in the container settings using the `env` field:


```yaml
    containers:
      main:
        env:
          - name: ENV_VAR_NAME
            value: "value"
          - name: ANOTHER_ENV_VAR
            value: "another value"
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
