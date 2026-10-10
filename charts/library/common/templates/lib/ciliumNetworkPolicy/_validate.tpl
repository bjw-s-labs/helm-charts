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
  {{- $hasControllers := and (hasKey $ciliumnetworkpolicyObject "controllers") $ciliumnetworkpolicyObject.controllers -}}
  {{- $hasEndpointSelector := hasKey $ciliumnetworkpolicyObject "endpointSelector" -}}
  {{- $hasNodeSelector := hasKey $ciliumnetworkpolicyObject "nodeSelector" -}}

  {{- /* If neither is specified, check if we can auto-detect a single controller */ -}}
  {{- if and (not $hasController) (not $hasControllers) (not $hasEndpointSelector) (not $hasNodeSelector) -}}
    {{- if ne (len $enabledControllers) 1 -}}
       {{- fail (printf "%s '%s': controller, controllers, or endpointSelector field is required because automatic controller detection is not possible (found %d enabled controllers). Please specify which controllers this %s should reference." $resourceKind $ciliumnetworkpolicyObject.identifier (len $enabledControllers) $resourceKind) -}}
    {{- end -}}
  {{- end -}}

  {{- /* If a controller is specified, check if it exists */ -}}
  {{- if and $hasController (not $hasEndpointSelector) (not $hasNodeSelector) -}}
    {{- $controller := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $ciliumnetworkpolicyObject.controller) -}}
    {{- if empty $controller -}}
      {{- fail (printf "%s '%s': No enabled controller found with identifier '%s'. Available controllers: [%s]" $resourceKind $ciliumnetworkpolicyObject.identifier $ciliumnetworkpolicyObject.controller (join ", " (keys $enabledControllers | sortAlpha))) -}}
    {{- end -}}
  {{- end -}}

  {{- if $hasControllers -}}
    {{- $_ := include "bjw-s.common.lib.controller.resolveReferences" (dict "rootContext" $rootContext "references" $ciliumnetworkpolicyObject.controllers "resourceKind" $resourceKind "policyIdentifier" $ciliumnetworkpolicyObject.identifier "referencePath" (printf "networkpolicies.%s.controllers" $ciliumnetworkpolicyObject.identifier)) -}}
  {{- end -}}

  {{- range $direction := list "ingress" "egress" -}}
    {{- $controllerField := ternary "fromControllers" "toControllers" (eq $direction "ingress") -}}
    {{- range $ruleIndex, $rule := (get $ciliumnetworkpolicyObject $direction | default list) -}}
      {{- if hasKey $rule $controllerField -}}
        {{- $_ := include "bjw-s.common.lib.controller.resolveReferences" (dict "rootContext" $rootContext "references" (get $rule $controllerField) "resourceKind" $resourceKind "policyIdentifier" $ciliumnetworkpolicyObject.identifier "referencePath" (printf "networkpolicies.%s.%s[%d].%s" $ciliumnetworkpolicyObject.identifier $direction $ruleIndex $controllerField)) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
