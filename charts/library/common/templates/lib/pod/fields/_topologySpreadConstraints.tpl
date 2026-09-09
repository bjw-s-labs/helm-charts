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
      {{- if not (hasKey $constraint "labelSelector") -}}
        {{- $matchLabels := include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | fromYaml -}}
        {{- $_ := set $matchLabels "app.kubernetes.io/controller" $controllerObject.identifier -}}
        {{- $_ := set $constraint "labelSelector" (dict "matchLabels" $matchLabels) -}}
      {{- end -}}
    {{- end -}}
    {{- $constraints | toYaml -}}
  {{- end -}}
{{- end -}}
