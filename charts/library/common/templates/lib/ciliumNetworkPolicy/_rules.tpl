{{/*
Render Cilium rules, expanding the direction-specific controller shorthand into endpoint selectors.
*/}}
{{- define "bjw-s.common.lib.ciliumNetworkPolicy.rules" -}}
  {{- $rootContext := .rootContext -}}
  {{- $rules := .rules -}}
  {{- $direction := .direction -}}
  {{- $endpointField := ternary "fromEndpoints" "toEndpoints" (eq $direction "ingress") -}}
  {{- $controllerField := ternary "fromController" "toController" (eq $direction "ingress") -}}
  {{- $renderedRules := list -}}
  {{- range $rule := $rules -}}
    {{- $renderedRule := deepCopy $rule -}}
    {{- if hasKey $renderedRule $controllerField -}}
      {{- $controllerIdentifier := get $renderedRule $controllerField -}}
      {{- $controllerObject := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $controllerIdentifier) | fromYaml -}}
      {{- $selectorLabels := include "bjw-s.common.lib.controller.metadata.selectorLabels" (dict "rootContext" $rootContext "controllerObject" $controllerObject) | fromYaml -}}
      {{- $endpoint := dict "matchLabels" $selectorLabels -}}
      {{- $endpoints := list $endpoint -}}
      {{- if hasKey $renderedRule $endpointField -}}
        {{- $endpoints = concat (get $renderedRule $endpointField) $endpoints -}}
      {{- end -}}
      {{- $_ := set $renderedRule $endpointField $endpoints -}}
      {{- $_ := unset $renderedRule $controllerField -}}
    {{- end -}}
    {{- $renderedRules = append $renderedRules $renderedRule -}}
  {{- end -}}
  {{- toYaml $renderedRules -}}
{{- end -}}
