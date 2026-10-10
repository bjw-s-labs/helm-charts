{{/* Expand controller references in native NetworkPolicy rule peers. */}}
{{- define "bjw-s.common.lib.networkpolicy.rules" -}}
  {{- $rootContext := .rootContext -}}
  {{- $rules := .rules -}}
  {{- $direction := .direction -}}
  {{- $policyIdentifier := .policyIdentifier -}}
  {{- $peerField := ternary "from" "to" (eq $direction "ingress") -}}
  {{- $renderedRules := list -}}
  {{- range $ruleIndex, $rule := $rules -}}
    {{- $renderedRule := deepCopy $rule -}}
    {{- if hasKey $renderedRule $peerField -}}
      {{- $renderedPeers := list -}}
      {{- range $peerIndex, $peer := get $renderedRule $peerField -}}
        {{- $renderedPeer := deepCopy $peer -}}
        {{- if hasKey $renderedPeer "controllers" -}}
          {{- $identifiers := include "bjw-s.common.lib.controller.resolveReferences" (dict "rootContext" $rootContext "references" $renderedPeer.controllers "resourceKind" "NetworkPolicy" "policyIdentifier" $policyIdentifier "referencePath" (printf "networkpolicies.%s.rules.%s[%d].%s[%d].controllers" $policyIdentifier $direction $ruleIndex $peerField $peerIndex)) | fromYamlArray -}}
          {{- $selector := include "bjw-s.common.lib.networkpolicy.controllerSelector" (dict "rootContext" $rootContext "controllerIdentifiers" $identifiers) | fromYaml -}}
          {{- $_ := set $renderedPeer "podSelector" $selector -}}
          {{- $_ := unset $renderedPeer "controllers" -}}
        {{- end -}}
        {{- $renderedPeers = append $renderedPeers $renderedPeer -}}
      {{- end -}}
      {{- $_ := set $renderedRule $peerField $renderedPeers -}}
    {{- end -}}
    {{- $renderedRules = append $renderedRules $renderedRule -}}
  {{- end -}}
  {{- toYaml $renderedRules -}}
{{- end -}}
