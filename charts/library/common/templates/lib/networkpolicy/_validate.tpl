{{/*
Validate networkPolicy values
*/}}
{{- define "bjw-s.common.lib.networkpolicy.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $networkpolicyObject := .object -}}

  {{- $enabledControllers := (include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml ) -}}
  {{- $hasController := and (hasKey $networkpolicyObject "controller") $networkpolicyObject.controller -}}
  {{- $hasControllers := and (hasKey $networkpolicyObject "controllers") $networkpolicyObject.controllers -}}
  {{- $hasPodSelector := hasKey $networkpolicyObject "podSelector" -}}

  {{- /* If neither is specified, check if we can auto-detect a single controller */ -}}
  {{- if and (not $hasController) (not $hasControllers) (not $hasPodSelector) -}}
    {{- if ne (len $enabledControllers) 1 -}}
      {{- fail (printf "NetworkPolicy '%s': controller, controllers, or podSelector field is required because automatic controller detection is not possible (found %d enabled controllers). Please specify which controllers this NetworkPolicy should reference." $networkpolicyObject.identifier (len $enabledControllers)) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
