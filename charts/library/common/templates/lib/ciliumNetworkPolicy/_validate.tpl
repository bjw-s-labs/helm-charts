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
{{- end -}}
