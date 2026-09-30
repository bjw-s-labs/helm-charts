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
      {{- $controller := get $renderedRule $controllerField -}}
      {{- $selectorLabels := mergeOverwrite
        (include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | fromYaml)
        (dict "app.kubernetes.io/controller" $controller)
      -}}
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
