{{/*
This template serves as a blueprint for HorizontalPodAutoscaler objects that are created
using the common library.
*/}}
{{- define "bjw-s.common.class.horizontalPodAutoscaler" -}}
  {{- $rootContext := .rootContext -}}
  {{- $hpaObject := .object -}}

  {{- $labels := merge
    (dict "app.kubernetes.io/controller" $hpaObject.controller)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($hpaObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}

  {{- /* Resolve the controller to determine scaleTargetRef kind */ -}}
  {{- $controllerObject := (include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $hpaObject.controller) | fromYaml) -}}
  {{- $targetKind := "Deployment" -}}
  {{- if eq $controllerObject.type "statefulset" -}}
    {{- $targetKind = "StatefulSet" -}}
  {{- end -}}
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $hpaObject.name }}
  {{- with $labels }}
  labels:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (tpl $value $rootContext | toYaml) | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- with $annotations }}
  annotations:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (tpl $value $rootContext | toYaml) | nindent 4 }}
    {{- end }}
  {{- end }}
  namespace: {{ $rootContext.Release.Namespace }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: {{ $targetKind }}
    name: {{ $hpaObject.name }}
  {{- if and (hasKey $hpaObject "minReplicas") (ne $hpaObject.minReplicas nil) }}
  minReplicas: {{ $hpaObject.minReplicas }}
  {{- end }}
  maxReplicas: {{ $hpaObject.maxReplicas }}
  {{- with $hpaObject.metrics }}
  metrics: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $hpaObject.behavior }}
  behavior: {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
