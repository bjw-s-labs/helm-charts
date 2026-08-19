{{/*
Return an ExternalSecret Object by its Identifier.
*/}}
{{- define "bjw-s.common.lib.externalSecret.getByIdentifier" -}}
  {{- $rootContext := .rootContext -}}
  {{- $identifier := .id -}}
  {{- $enabledExternalSecrets := (include "bjw-s.common.lib.externalSecret.enabledExternalSecrets" (dict "rootContext" $rootContext) | fromYaml ) }}

  {{- if (hasKey $enabledExternalSecrets $identifier) -}}
    {{- $objectValues := get $enabledExternalSecrets $identifier -}}
    {{- include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $objectValues "itemCount" (len $enabledExternalSecrets)) -}}
  {{- end -}}
{{- end -}}
