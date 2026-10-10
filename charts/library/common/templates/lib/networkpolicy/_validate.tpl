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

  {{- /* If a controller is specified, check if it exists */ -}}
  {{- if and $hasController (not $hasPodSelector) -}}
    {{- $controller := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $networkpolicyObject.controller) -}}
    {{- if empty $controller -}}
      {{- fail (printf "NetworkPolicy '%s': No enabled controller found with identifier '%s'. Available controllers: [%s]" $networkpolicyObject.identifier $networkpolicyObject.controller (join ", " (keys $enabledControllers | sortAlpha))) -}}
    {{- end -}}
  {{- end -}}

  {{- if $hasControllers -}}
    {{- $_ := include "bjw-s.common.lib.controller.resolveReferences" (dict "rootContext" $rootContext "references" $networkpolicyObject.controllers "resourceKind" "NetworkPolicy" "policyIdentifier" $networkpolicyObject.identifier "referencePath" (printf "networkpolicies.%s.controllers" $networkpolicyObject.identifier)) -}}
  {{- end -}}

  {{- range $direction := list "ingress" "egress" -}}
    {{- $peerField := ternary "from" "to" (eq $direction "ingress") -}}
    {{- range $ruleIndex, $rule := (get ($networkpolicyObject.rules | default dict) $direction | default list) -}}
      {{- range $peerIndex, $peer := (get $rule $peerField | default list) -}}
        {{- if hasKey $peer "controllers" -}}
          {{- $_ := include "bjw-s.common.lib.controller.resolveReferences" (dict "rootContext" $rootContext "references" $peer.controllers "resourceKind" "NetworkPolicy" "policyIdentifier" $networkpolicyObject.identifier "referencePath" (printf "networkpolicies.%s.rules.%s[%d].%s[%d].controllers" $networkpolicyObject.identifier $direction $ruleIndex $peerField $peerIndex)) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
