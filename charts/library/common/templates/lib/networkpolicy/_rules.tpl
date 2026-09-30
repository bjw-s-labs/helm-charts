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
          {{- $selectorLabels := mergeOverwrite
            (include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | fromYaml)
            (dict "app.kubernetes.io/controller" $controllerIdentifier)
          -}}
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
