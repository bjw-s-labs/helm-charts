{{/*
Render Cilium rules, expanding the direction-specific controller shorthand into endpoint selectors.
*/}}
{{- define "bjw-s.common.lib.ciliumNetworkPolicy.rules" -}}
  {{- $rootContext := .rootContext -}}
  {{- $rules := .rules -}}
  {{- $direction := .direction -}}
  {{- $policyIdentifier := .policyIdentifier -}}
  {{- $resourceKind := .resourceKind -}}
  {{- $endpointField := ternary "fromEndpoints" "toEndpoints" (eq $direction "ingress") -}}
  {{- $controllerField := ternary "fromControllers" "toControllers" (eq $direction "ingress") -}}
  {{- $renderedRules := list -}}
  {{- range $ruleIndex, $rule := $rules -}}
    {{- $renderedRule := deepCopy $rule -}}
    {{- if hasKey $renderedRule $controllerField -}}
      {{- $identifiers := include "bjw-s.common.lib.controller.resolveReferences" (dict "rootContext" $rootContext "references" (get $renderedRule $controllerField) "resourceKind" $resourceKind "policyIdentifier" $policyIdentifier "referencePath" (printf "networkpolicies.%s.%s[%d].%s" $policyIdentifier $direction $ruleIndex $controllerField)) | fromYamlArray -}}
      {{- $endpoint := include "bjw-s.common.lib.networkpolicy.controllerSelector" (dict "rootContext" $rootContext "controllerIdentifiers" $identifiers) | fromYaml -}}
      {{- $_ := set $renderedRule $endpointField (list $endpoint) -}}
      {{- $_ := unset $renderedRule $controllerField -}}
    {{- end -}}
    {{- $renderedRules = append $renderedRules $renderedRule -}}
  {{- end -}}
  {{- toYaml $renderedRules -}}
{{- end -}}
