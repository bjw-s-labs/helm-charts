{{/*
Return the enabled routes.
*/}}
{{- define "bjw-s.common.lib.route.enabledRoutes" -}}
  {{- $rootContext := .rootContext -}}
  {{- $enabledRoutes := dict -}}

  {{- range $name, $route := $rootContext.Values.route -}}
    {{- if kindIs "map" $route -}}
      {{- /* Enable Route by default, but allow override */ -}}
      {{- $routeEnabled := true -}}
      {{- if hasKey $route "enabled" -}}
        {{- $routeEnabled = $route.enabled -}}
      {{- end -}}

      {{- if $routeEnabled -}}
        {{- $_ := set $enabledRoutes $name . -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- range $identifier, $objectValues := $enabledRoutes -}}
    {{- $object := include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $objectValues "itemCount" (len $enabledRoutes)) | fromYaml -}}
    {{- $object = include "bjw-s.common.lib.route.autoDetectService" (dict "rootContext" $rootContext "object" $object) | fromYaml -}}
    {{- $_ := set $enabledRoutes $identifier $object -}}
  {{- end -}}

  {{- $enabledRoutes | toYaml -}}
{{- end -}}
