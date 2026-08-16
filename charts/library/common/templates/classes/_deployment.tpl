{{/*
This template serves as a blueprint for Deployment objects that are created
using the common library.
*/}}
{{- define "bjw-s.common.class.deployment" -}}
  {{- $rootContext := .rootContext -}}
  {{- $deploymentObject := .object -}}

  {{- $labels := merge
    (dict "app.kubernetes.io/controller" $deploymentObject.identifier)
    ($deploymentObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($deploymentObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $deploymentObject.name }}
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
  revisionHistoryLimit: {{ include "bjw-s.common.lib.defaultKeepNonNullValue" (dict "value" $deploymentObject.revisionHistoryLimit "default" 3) }}
  {{- if hasKey $deploymentObject "replicas" }}
    {{- if not (eq $deploymentObject.replicas nil) }}
  replicas: {{ $deploymentObject.replicas }}
    {{- end }}
  {{- else }}
  replicas: 1
  {{- end }}
  strategy:
    type: {{ $deploymentObject.strategy }}
    {{- with $deploymentObject.rollingUpdate }}
      {{- $hasUnavailable := or (hasKey . "maxUnavailable") (hasKey . "unavailable") }}
      {{- $hasSurge := or (hasKey . "maxSurge") (hasKey . "surge") }}
      {{- if and (eq $deploymentObject.strategy "RollingUpdate") (or $hasUnavailable $hasSurge) }}
    rollingUpdate:
        {{- if $hasUnavailable }}
          {{- if hasKey . "maxUnavailable" }}
      maxUnavailable: {{ .maxUnavailable }}
          {{- else }}
      maxUnavailable: {{ .unavailable }}
          {{- end }}
        {{- end }}
        {{- if $hasSurge }}
          {{- if hasKey . "maxSurge" }}
      maxSurge: {{ .maxSurge }}
          {{- else }}
      maxSurge: {{ .surge }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  selector:
    matchLabels:
      app.kubernetes.io/controller: {{ $deploymentObject.identifier }}
      {{- include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | nindent 6 }}
  template:
    metadata:
      {{- with (include "bjw-s.common.lib.pod.metadata.annotations" (dict "rootContext" $rootContext "controllerObject" $deploymentObject)) }}
      annotations: {{ . | nindent 8 }}
      {{- end -}}
      {{- with (include "bjw-s.common.lib.pod.metadata.labels" (dict "rootContext" $rootContext "controllerObject" $deploymentObject)) }}
      labels: {{ . | nindent 8 }}
      {{- end }}
    spec: {{ include "bjw-s.common.lib.pod.spec" (dict "rootContext" $rootContext "controllerObject" $deploymentObject) | nindent 6 }}
{{- end -}}
