{{/*
Validate networkPolicy values
*/}}
{{- define "bjw-s.common.lib.networkpolicy.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $networkpolicyObject := .object -}}

  {{- $enabledControllers := (include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml ) -}}
  {{- $hasController := and (hasKey $networkpolicyObject "controller") $networkpolicyObject.controller -}}
  {{- $hasPodSelector := hasKey $networkpolicyObject "podSelector" -}}

  {{- /* If neither is specified, check if we can auto-detect a single controller */ -}}
  {{- if and (not $hasController) (not $hasPodSelector) -}}
    {{- $enabledControllers := (include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml) -}}
    {{- if ne (len $enabledControllers) 1 -}}
      {{- fail (printf "NetworkPolicy '%s': controller or podSelector field is required because automatic controller detection is not possible (found %d enabled controllers). Please specify which controller this NetworkPolicy should reference." $networkpolicyObject.identifier (len $enabledControllers)) -}}
    {{- end -}}
  {{- end -}}

  {{- /* If a controller is specified, check if it exists */ -}}
  {{- if and ($hasController) (not $hasPodSelector) -}}
    {{- $networkpolicyController := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $networkpolicyObject.controller) -}}
    {{- if empty $networkpolicyController -}}
      {{- $availableControllers := list -}}
      {{- range $key, $ctrl := $enabledControllers -}}
        {{- $availableControllers = append $availableControllers $key -}}
      {{- end -}}
      {{- fail (printf "NetworkPolicy '%s': No enabled controller found with identifier '%s'. Available controllers: [%s]" $networkpolicyObject.identifier $networkpolicyObject.controller (join ", " $availableControllers)) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
