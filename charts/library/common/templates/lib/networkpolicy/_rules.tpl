{{/* Expand controller references in native NetworkPolicy rule peers. */}}
{{- define "bjw-s.common.lib.networkpolicy.rules" -}}
  {{- $rootContext := .rootContext -}}
  {{- $rules := .rules -}}
  {{- $direction := .direction -}}
  {{- $peerField := ternary "from" "to" (eq $direction "ingress") -}}
  {{- $renderedRules := list -}}
  {{- range $rule := $rules -}}
    {{- $renderedRule := deepCopy $rule -}}
    {{- if hasKey $renderedRule $peerField -}}
      {{- $renderedPeers := list -}}
      {{- range $peer := get $renderedRule $peerField -}}
        {{- $renderedPeer := deepCopy $peer -}}
        {{- if hasKey $renderedPeer "controller" -}}
          {{- $controllerIdentifier := get $renderedPeer "controller" -}}
          {{- $controllerObject := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $controllerIdentifier) | fromYaml -}}
          {{- $selectorLabels := include "bjw-s.common.lib.controller.metadata.selectorLabels" (dict "rootContext" $rootContext "controllerObject" $controllerObject) | fromYaml -}}
          {{- $_ := set $renderedPeer "podSelector" (dict "matchLabels" $selectorLabels) -}}
          {{- $_ := unset $renderedPeer "controller" -}}
        {{- end -}}
        {{- $renderedPeers = append $renderedPeers $renderedPeer -}}
      {{- end -}}
      {{- $_ := set $renderedRule $peerField $renderedPeers -}}
    {{- end -}}
    {{- $renderedRules = append $renderedRules $renderedRule -}}
  {{- end -}}
  {{- toYaml $renderedRules -}}
{{- end -}}
