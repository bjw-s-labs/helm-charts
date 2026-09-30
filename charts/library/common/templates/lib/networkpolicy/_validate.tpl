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

  {{- range $direction := list "ingress" "egress" -}}
    {{- $peerField := ternary "from" "to" (eq $direction "ingress") -}}
    {{- range $rule := (get ($networkpolicyObject.rules | default dict) $direction | default list) -}}
      {{- range $peer := (get $rule $peerField | default list) -}}
        {{- if hasKey $peer "controller" -}}
          {{- $controllerIdentifier := get $peer "controller" -}}
          {{- $controller := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $controllerIdentifier) -}}
          {{- if empty $controller -}}
            {{- fail (printf "NetworkPolicy '%s': %s rule references controller '%s', but no enabled controller exists with that identifier. Enable 'controllers.%s' or choose an enabled controller." $networkpolicyObject.identifier (title $direction) $controllerIdentifier $controllerIdentifier) -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
