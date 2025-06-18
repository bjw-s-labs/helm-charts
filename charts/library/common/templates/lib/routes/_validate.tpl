{{/*
Validate Route values
*/}}
{{- define "bjw-s.common.lib.route.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $routeObject := .object -}}

  {{- $enabledServices := (include "bjw-s.common.lib.service.enabledServices" (dict "rootContext" $rootContext) | fromYaml ) -}}

  {{/* Verify automatic Service detection */}}
  {{- if not (eq 1 (len $enabledServices)) -}}
    {{- if empty $routeObject.rules -}}
      {{- fail (printf "An explicit rule is required because automatic Service detection is not possible. (route: %s)" $routeObject.identifier) -}}
    {{- end -}}

    {{- range $routeObject.rules -}}
      {{- $rule := . -}}
      {{- range $rule.backendRefs }}
        {{- $backendRef := . -}}
        {{- if and (empty (dig "name" nil $backendRef)) (empty (dig "identifier" nil $backendRef)) -}}
          {{- fail (printf "Either name or identifier is required because automatic Service detection is not possible. (route: %s)" $routeObject.identifier) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{/* Route Types */}}
  {{- $routeKind := $routeObject.kind | default "HTTPRoute"}}
  {{- if and (ne $routeKind "GRPCRoute") (ne $routeKind "HTTPRoute") (ne $routeKind "TCPRoute") (ne $routeKind "TLSRoute") (ne $routeKind "UDPRoute") }}
    {{- fail (printf "Not a valid route kind (%s)" $routeKind) }}
  {{- end }}

  {{/* Route Rules */}}
  {{- range $routeObject.rules }}
  {{- if and (.filters) (.backendRefs) }}
    {{- range .filters }}
      {{- if eq .type "RequestRedirect" }}
        {{- fail (printf "backend refs and request redirect filters cannot co-exist.")}}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end -}}
