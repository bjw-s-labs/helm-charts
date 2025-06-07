{{/*
Return a service Object by its Identifier.
*/}}
{{- define "bjw-s.common.lib.service.getByIdentifier" -}}
  {{- $rootContext := .rootContext -}}
  {{- $identifier := .id -}}
  {{- $enabledServices := (include "bjw-s.common.lib.service.enabledServices" (dict "rootContext" $rootContext) | fromYaml ) }}

  {{- if (hasKey $enabledServices $identifier) -}}
    {{- get $enabledServices $identifier | toYaml -}}
  {{- end -}}
{{- end -}}
