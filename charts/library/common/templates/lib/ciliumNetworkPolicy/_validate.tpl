{{/*
Validate ciliumNetworkPolicy values
*/}}
{{- define "bjw-s.common.lib.ciliumNetworkPolicy.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $ciliumnetworkpolicyObject := .object -}}
  {{- $clusterwide := eq ($ciliumnetworkpolicyObject.type | default "cilium") "ciliumClusterwide" -}}
  {{- $resourceKind := ternary "CiliumClusterwideNetworkPolicy" "CiliumNetworkPolicy" $clusterwide -}}

  {{- $enabledControllers := (include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml ) -}}
  {{- $hasController := and (hasKey $ciliumnetworkpolicyObject "controller") $ciliumnetworkpolicyObject.controller -}}
  {{- $hasEndpointSelector := hasKey $ciliumnetworkpolicyObject "endpointSelector" -}}
  {{- $hasNodeSelector := hasKey $ciliumnetworkpolicyObject "nodeSelector" -}}

  {{- /* If neither is specified, check if we can auto-detect a single controller */ -}}
  {{- if and (not $hasController) (not $hasEndpointSelector) (not $hasNodeSelector) -}}
    {{- $enabledControllers := (include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml) -}}
    {{- if ne (len $enabledControllers) 1 -}}
       {{- fail (printf "%s '%s': controller or endpointSelector field is required because automatic controller detection is not possible (found %d enabled controllers). Please specify which controller this %s should reference." $resourceKind $ciliumnetworkpolicyObject.identifier (len $enabledControllers) $resourceKind) -}}
    {{- end -}}
  {{- end -}}

  {{- /* If a controller is specified, check if it exists */ -}}
  {{- if and ($hasController) (not $hasEndpointSelector) (not $hasNodeSelector) -}}
    {{- $ciliumNetworkPolicyController := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $ciliumnetworkpolicyObject.controller) -}}
    {{- if empty $ciliumNetworkPolicyController -}}
      {{- $availableControllers := list -}}
      {{- range $key, $ctrl := $enabledControllers -}}
        {{- $availableControllers = append $availableControllers $key -}}
      {{- end -}}
       {{- fail (printf "%s '%s': No enabled controller found with identifier '%s'. Available controllers: [%s]" $resourceKind $ciliumnetworkpolicyObject.identifier $ciliumnetworkpolicyObject.controller (join ", " $availableControllers)) -}}
    {{- end -}}
  {{- end -}}

  {{- range $direction := list "ingress" "egress" -}}
    {{- $controllerField := ternary "fromController" "toController" (eq $direction "ingress") -}}
    {{- range $rule := (get $ciliumnetworkpolicyObject $direction | default list) -}}
      {{- if hasKey $rule $controllerField -}}
        {{- $controllerIdentifier := get $rule $controllerField -}}
        {{- $controller := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $controllerIdentifier) -}}
        {{- if empty $controller -}}
          {{- fail (printf "%s '%s': %s rule references controller '%s', but no enabled controller exists with that identifier. Enable 'controllers.%s' or choose an enabled controller." $resourceKind $ciliumnetworkpolicyObject.identifier (title $direction) $controllerIdentifier $controllerIdentifier) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
