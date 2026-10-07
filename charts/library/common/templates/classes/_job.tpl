{{/*
This template serves as the blueprint for the job objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.job" -}}
  {{- $rootContext := .rootContext -}}
  {{- $jobObject := .object -}}

  {{- $labels := mergeOverwrite
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
    (dict "app.kubernetes.io/controller" $jobObject.identifier)
    ($jobObject.labels | default dict)
  -}}
  {{- $annotations := mergeOverwrite
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
    ($jobObject.annotations | default dict)
  -}}

  {{- $jobSettings := dig "job" dict $jobObject -}}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $jobObject.name }}
  {{- with $labels }}
  labels:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (include "bjw-s.common.lib.common.renderString" (dict "value" $value "rootContext" $rootContext) | toYaml ) | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- with $annotations }}
  annotations:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (include "bjw-s.common.lib.common.renderString" (dict "value" $value "rootContext" $rootContext) | toYaml ) | nindent 4 }}
    {{- end }}
  {{- end }}
  namespace: {{ $rootContext.Release.Namespace }}
spec:
  suspend: {{ default false $jobSettings.suspend }}
  {{- with $jobSettings.activeDeadlineSeconds }}
  activeDeadlineSeconds: {{ . }}
  {{- end }}
  {{- with $jobSettings.ttlSecondsAfterFinished }}
  ttlSecondsAfterFinished: {{ . }}
  {{- end }}
  {{- with $jobSettings.parallelism }}
  parallelism: {{ . }}
  {{- end }}
  {{- with $jobSettings.completions }}
  completions: {{ . }}
  {{- end }}
  {{- with $jobSettings.completionMode }}
  completionMode: {{ . }}
  {{- end }}
  backoffLimit: {{ include "bjw-s.common.lib.defaultKeepNonNullValue" (dict "value" $jobSettings.backoffLimit "default" 6) }}
  template:
    metadata:
      {{- with (include "bjw-s.common.lib.pod.metadata.annotations" (dict "rootContext" $rootContext "controllerObject" $jobObject)) }}
      annotations: {{ . | nindent 8 }}
      {{- end -}}
      {{- with (include "bjw-s.common.lib.pod.metadata.labels" (dict "rootContext" $rootContext "controllerObject" $jobObject)) }}
      labels: {{ . | nindent 8 }}
      {{- end }}
    spec: {{ include "bjw-s.common.lib.pod.spec" (dict "rootContext" $rootContext "controllerObject" $jobObject) | nindent 6 }}
{{- end -}}
