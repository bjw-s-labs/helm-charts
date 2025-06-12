{{/*
Autodetects the service for a Route object
*/}}
{{- define "bjw-s.common.lib.route.autoDetectService" -}}
  {{- $rootContext := .rootContext -}}
  {{- $routeObject := .object -}}
  {{- $enabledServices := (include "bjw-s.common.lib.service.enabledServices" (dict "rootContext" $rootContext) | fromYaml ) -}}

  {{- if eq 1 (len $enabledServices) -}}
    {{- if empty $routeObject.rules -}}
      {{- $_ := set $routeObject "rules" (list (dict "backendRefs" (list dict))) -}}
    {{- end -}}

    {{- range $routeObject.rules -}}
      {{- range .backendRefs }}
        {{- $backendRef := . -}}
        {{- if and (empty (dig "name" nil $backendRef)) (empty (dig "identifier" nil $backendRef)) -}}
          {{- $_ := set $backendRef "identifier" ($enabledServices | keys | first) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- $routeObject | toYaml -}}
{{- end -}}
