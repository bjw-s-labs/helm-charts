{{/*
Secondary entrypoint and primary loader for the common chart
*/}}
{{- define "bjw-s.common.loader.generate" -}}
  {{- $rootContext := $ -}}

  {{- /* Evaluate templates against the post-merge root context. */ -}}
  {{- $passes := dig "global" "templateEvaluation" "passes" 1 $rootContext.Values -}}
  {{- $excludePaths := dig "global" "templateEvaluation" "excludePaths" list $rootContext.Values -}}
  {{- $evaluatedValues := include "bjw-s.common.values.evaluateTemplate" (dict "rootContext" $rootContext "value" (deepCopy $rootContext.Values) "passes" $passes "excludePaths" $excludePaths) | fromJson -}}
  {{- $renderContext := merge (dict) $rootContext -}}
  {{- $_ := set $renderContext "Values" (index $evaluatedValues "value") -}}
  {{- $_ := set $renderContext "TemplateRendering" (dict "valuesRendered" true) -}}

  {{- /* Run global chart validations */ -}}
  {{- include "bjw-s.common.lib.chart.validate" $renderContext -}}

  {{- /* Build the templates */ -}}
  {{- include "bjw-s.common.render.pvcs" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.serviceAccount" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.configMaps.fromFolder" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.configMaps" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.secrets.fromFolder" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.controllers" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.services" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.ingresses" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.serviceMonitors" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.podMonitors" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.listenerSets" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.routes" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.secrets" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.externalSecrets" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.networkpolicies" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.rawResources" $renderContext | nindent 0 -}}
  {{- include "bjw-s.common.render.rbac" $renderContext | nindent 0 -}}
{{- end -}}
