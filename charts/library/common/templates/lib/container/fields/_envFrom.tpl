{{/*
envFrom field used by the container.
*/}}
{{- define "bjw-s.common.lib.container.field.envFrom" -}}
  {{- $ctx := .ctx -}}
  {{- $rootContext := $ctx.rootContext -}}
  {{- $containerObject := $ctx.containerObject -}}
  {{- $envFromValues := get $containerObject "envFrom" -}}

  {{- if not (empty $envFromValues) -}}
    {{- $envFrom := list -}}
    {{- range $envFromValues -}}
      {{- $item := dict -}}

      {{- if hasKey . "configMap" -}}
        {{- $configMap := include "bjw-s.common.lib.configMap.getByIdentifier" (dict "rootContext" $rootContext "id" .configMap) | fromYaml -}}
        {{- $configMapName := default (tpl .configMap $rootContext) $configMap.name -}}
        {{- $_ := set $item "configMapRef" (dict "name" $configMapName) -}}
      {{- else if hasKey . "configMapRef" -}}
        {{- if not (empty (dig "identifier" nil .configMapRef)) -}}
          {{- $configMap := include "bjw-s.common.lib.configMap.getByIdentifier" (dict "rootContext" $rootContext "id" .configMapRef.identifier) | fromYaml -}}
          {{- if empty $configMap -}}
            {{- fail (printf "Container '%s': No ConfigMap found with identifier '%s'. Ensure a ConfigMap with this identifier exists and is enabled under 'configMaps.%s'." $containerObject.identifier .configMapRef.identifier .configMapRef.identifier) -}}
          {{- end -}}

          {{- $_ := set $item "configMapRef" (dict "name" $configMap.name) -}}
        {{- else -}}
          {{- $_ := set $item "configMapRef" (dict "name" (tpl .configMapRef.name $rootContext)) -}}
        {{- end -}}
        {{- if not (empty (dig "optional" nil .configMapRef)) -}}
          {{- $_ := set $item.configMapRef "optional" .configMapRef.optional -}}
        {{- end -}}
      {{- else if hasKey . "secret" -}}
        {{- $secret := include "bjw-s.common.lib.secret.getByIdentifier" (dict "rootContext" $rootContext "id" .secret) | fromYaml -}}
        {{- $secretName := default (tpl .secret $rootContext) $secret.name -}}
        {{- $_ := set $item "secretRef" (dict "name" $secretName) -}}
      {{- else if hasKey . "externalSecretRef" -}}
        {{- $secret := include "bjw-s.common.lib.externalSecret.getByIdentifier" (dict "rootContext" $rootContext "id" .externalSecretRef.identifier) | fromYaml -}}
        {{- if empty $secret -}}
          {{- fail (printf "Container '%s': No ExternalSecret found with identifier '%s'. Ensure an ExternalSecret with this identifier exists and is enabled under 'externalSecrets.%s'" $containerObject.identifier .externalSecretRef.identifier .externalSecretRef.identifier) -}}
        {{- end -}}

        {{- $secretName := include "bjw-s.common.lib.externalSecret.getSecretName" $secret -}}
        {{- $_ := set $item "secretRef" (dict "name" $secretName) -}}
        {{- if not (empty (dig "optional" nil .externalSecretRef)) -}}
          {{- $_ := set $item.secretRef "optional" .externalSecretRef.optional -}}
        {{- end -}}
      {{- else if hasKey . "secretRef" -}}
        {{- if not (empty (dig "identifier" nil .secretRef)) -}}
          {{- $secret := include "bjw-s.common.lib.secret.getByIdentifier" (dict "rootContext" $rootContext "id" .secretRef.identifier) | fromYaml -}}
          {{- if empty $secret -}}
            {{- fail (printf "Container '%s': No Secret found with identifier '%s'. Ensure a Secret with this identifier exists and is enabled under 'secrets.%s'." $containerObject.identifier .secretRef.identifier .secretRef.identifier) -}}
          {{- end -}}

          {{- $_ := set $item "secretRef" (dict "name" $secret.name) -}}
        {{- else -}}
          {{- $_ := set $item "secretRef" (dict "name" (tpl .secretRef.name $rootContext)) -}}
        {{- end -}}
        {{- if not (empty (dig "optional" nil .secretRef)) -}}
          {{- $_ := set $item.secretRef "optional" .secretRef.optional -}}
        {{- end -}}
      {{- end -}}

      {{- if not (empty (dig "prefix" nil .)) -}}
        {{- $_ := set $item "prefix" .prefix -}}
      {{- end -}}

      {{- if not (empty $item) -}}
        {{- $envFrom = append $envFrom $item -}}
      {{- end -}}
    {{- end -}}

    {{- $envFrom | toYaml -}}
  {{- end -}}
{{- end -}}
