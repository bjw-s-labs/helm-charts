{{/*
Return a Route object by its Identifier.
*/}}
{{- define "bjw-s.common.lib.route.getByIdentifier" -}}
  {{- $rootContext := .rootContext -}}
  {{- $identifier := .id -}}

  {{- $enabledRoutes := (include "bjw-s.common.lib.route.enabledRoutes" (dict "rootContext" $rootContext) | fromYaml ) }}

  {{- if (hasKey $enabledRoutes $identifier) -}}
    {{- get $enabledRoutes $identifier | toYaml -}}
  {{- end -}}
{{- end -}}
