{{/*
This template serves as a blueprint for HorizontalPodAutoscaler objects that are created
using the common library.
*/}}
{{- define "bjw-s.common.class.horizontalPodAutoscaler" -}}
  {{- $rootContext := .rootContext -}}
  {{- $horizontalPodAutoscalerObject := .object -}}

  {{- $labels := merge
    (dict "app.kubernetes.io/controller" $horizontalPodAutoscalerObject.controller)
    ($horizontalPodAutoscalerObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($horizontalPodAutoscalerObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $horizontalPodAutoscalerObject.name }}
  {{- with $labels }}
  labels:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (tpl $value $rootContext | toYaml ) | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- with $annotations }}
  annotations:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (tpl $value $rootContext | toYaml ) | nindent 4 }}
    {{- end }}
  {{- end }}
  namespace: {{ $rootContext.Release.Namespace }}
spec:
  scaleTargetRef:
    apiVersion: {{ $horizontalPodAutoscalerObject.targetApiVersion }}
    kind: {{ $horizontalPodAutoscalerObject.targetKind }}
    name: {{ $horizontalPodAutoscalerObject.targetName }}
  minReplicas: {{ $horizontalPodAutoscalerObject.minReplicas | default 1 }}
  maxReplicas: {{ $horizontalPodAutoscalerObject.maxReplicas }}
  {{- with $horizontalPodAutoscalerObject.metrics }}
  metrics:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $horizontalPodAutoscalerObject.behavior }}
  behavior:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
