{{- /*
Returns topologySpreadConstraints, defaulting selectors to the controller.
*/ -}}
{{- define "bjw-s.common.lib.pod.field.topologySpreadConstraints" -}}
  {{- $ctx := .ctx -}}
  {{- $rootContext := $ctx.rootContext -}}
  {{- $controllerObject := $ctx.controllerObject -}}

  {{- with (include "bjw-s.common.lib.pod.getOption" (dict "ctx" $ctx "option" "topologySpreadConstraints")) -}}
    {{- $constraints := tpl . $rootContext | fromYamlArray -}}
    {{- range $constraint := $constraints -}}
      {{- $labelSelector := $constraint.labelSelector | default dict -}}
      {{- if empty $labelSelector.matchLabels -}}
        {{- $matchLabels := include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | fromYaml -}}
        {{- $_ := set $matchLabels "app.kubernetes.io/controller" $controllerObject.identifier -}}
        {{- $_ := set $labelSelector "matchLabels" $matchLabels -}}
      {{- end -}}
      {{- $_ := set $constraint "labelSelector" $labelSelector -}}
    {{- end -}}
    {{- $constraints | toYaml -}}
  {{- end -}}
{{- end -}}
