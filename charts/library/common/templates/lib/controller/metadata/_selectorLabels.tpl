{{/*
Return the labels identifying a controller's pods. Regular metadata labels are excluded.
Accepts rootContext and controllerObject.
*/}}
{{- define "bjw-s.common.lib.controller.metadata.selectorLabels" -}}
  {{- $rootContext := .rootContext -}}
  {{- $controllerObject := .controllerObject -}}
  {{- $extraSelectorLabels := include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml ($controllerObject.extraSelectorLabels | default dict)) "rootContext" $rootContext) | fromYaml -}}
  {{- $selectorLabels := mergeOverwrite
    (dict)
    (include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | fromYaml)
    (dict "app.kubernetes.io/controller" $controllerObject.identifier)
    $extraSelectorLabels
  -}}
  {{- toYaml $selectorLabels -}}
{{- end -}}
