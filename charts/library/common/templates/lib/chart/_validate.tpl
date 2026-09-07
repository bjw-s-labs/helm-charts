{{/*
Validate global chart values
*/}}
{{- define "bjw-s.common.lib.chart.validate" -}}
  {{- $rootContext := . -}}

  {{- $enabledSecrets := include "bjw-s.common.lib.secret.enabledSecrets" (dict "rootContext" $rootContext) | fromYaml -}}
  {{- $enabledExternalSecrets := include "bjw-s.common.lib.externalSecret.enabledExternalSecrets" (dict "rootContext" $rootContext) | fromYaml -}}
  {{- $nativeSecretNames := dict -}}

  {{- range $identifier, $values := $enabledSecrets -}}
    {{- $object := include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" (deepCopy $values) "itemCount" (len $enabledSecrets)) | fromYaml -}}
    {{- $_ := set $nativeSecretNames $object.name $identifier -}}
  {{- end -}}

  {{- range $identifier, $values := $enabledExternalSecrets -}}
    {{- $object := include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" (deepCopy $values) "itemCount" (len $enabledExternalSecrets)) | fromYaml -}}
    {{- $targetName := include "bjw-s.common.lib.externalSecret.getSecretName" $object -}}
    {{- if hasKey $nativeSecretNames $targetName -}}
      {{- $nativeIdentifier := get $nativeSecretNames $targetName -}}
      {{- fail (printf "Secret '%s': Rendered Secret name '%s' collides with ExternalSecret '%s'. Choose unique Secret names." $nativeIdentifier $targetName $identifier) -}}
    {{- end -}}
  {{- end -}}

  {{- /* Validate persistence values */ -}}
  {{- range $persistenceKey, $persistenceValues := .Values.persistence }}
    {{- $persistenceEnabled := true -}}
    {{- if hasKey $persistenceValues "enabled" -}}
      {{- $persistenceEnabled = $persistenceValues.enabled -}}
    {{- end -}}

    {{- if $persistenceEnabled -}}
      {{- /* Make sure that any advancedMounts controller references actually resolve */ -}}
      {{- range $key, $advancedMount := $persistenceValues.advancedMounts -}}
          {{- $mountController := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $key) -}}
          {{- if empty $mountController -}}
            {{- fail (printf "Persistence '%s': No enabled controller found with identifier '%s'. Ensure a controller with this identifier exists and is enabled under 'controllers.%s'." $persistenceKey $key $key) -}}
          {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
