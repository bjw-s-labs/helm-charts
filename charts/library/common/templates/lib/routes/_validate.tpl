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
          {{- fail (printf "Route '%s': Either 'name' or 'identifier' is required in backendRef because automatic Service detection is not possible (found %d enabled services). Specify the target service explicitly." $routeObject.identifier (len $enabledServices)) -}}
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
        {{- fail (printf "Route '%s': RequestRedirect filter cannot be used together with backendRefs. Remove either the filter or the backendRefs." $routeObject.identifier) -}}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end -}}
