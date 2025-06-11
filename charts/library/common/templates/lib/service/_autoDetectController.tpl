{{/*
Autodetects the controller for a Service object
*/}}
{{- define "bjw-s.common.lib.service.autoDetectController" -}}
  {{- $rootContext := .rootContext -}}
  {{- $serviceObject := .object -}}
  {{- $enabledControllers := (include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml ) -}}

  {{- if eq 1 (len $enabledControllers) -}}
    {{- if (empty (dig "controller" nil $serviceObject)) -}}
      {{- $_ := set $serviceObject "controller" ($enabledControllers | keys | first) -}}
    {{- end -}}
  {{- end -}}
  {{- $serviceObject | toYaml -}}
{{- end -}}
