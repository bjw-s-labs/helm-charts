{{/*
This template serves as the blueprint for the StatefulSet objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.statefulset" -}}
  {{- $rootContext := .rootContext -}}
  {{- $statefulsetObject := .object -}}

  {{- $labels := merge
    (dict "app.kubernetes.io/controller" $statefulsetObject.identifier)
    ($statefulsetObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($statefulsetObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ $statefulsetObject.name }}
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
  revisionHistoryLimit: {{ include "bjw-s.common.lib.defaultKeepNonNullValue" (dict "value" $statefulsetObject.revisionHistoryLimit "default" 3) }}
  replicas: {{ $statefulsetObject.replicas }}
  podManagementPolicy: {{ dig "statefulset" "podManagementPolicy" "OrderedReady" $statefulsetObject }}
  updateStrategy:
    type: {{ $statefulsetObject.strategy }}
    {{- if and (eq $statefulsetObject.strategy "RollingUpdate") (dig "rollingUpdate" "partition" nil $statefulsetObject) }}
    rollingUpdate:
      partition: {{ $statefulsetObject.rollingUpdate.partition }}
    {{- end }}
  selector:
    matchLabels:
      app.kubernetes.io/controller: {{ $statefulsetObject.identifier }}
      {{- include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | nindent 6 }}
  {{- $serviceName := include "bjw-s.common.lib.chart.names.fullname" $rootContext }}
  {{- with (dig "statefulset" "serviceName" nil $statefulsetObject) }}
    {{- if kindIs "map" . }}
      {{- $serviceName = (include "bjw-s.common.lib.service.getByIdentifier" (dict "rootContext" $rootContext "id" .identifier) | fromYaml ).name }}
    {{- else }}
      {{- $serviceName = tpl . $rootContext }}
    {{- end }}
  {{- end }}
  serviceName: {{ $serviceName }}
  {{- with (dig "statefulset" "persistentVolumeClaimRetentionPolicy" nil $statefulsetObject) }}
  persistentVolumeClaimRetentionPolicy:  {{ . | toYaml | nindent 4 }}
  {{- end }}
  template:
    metadata:
      {{- with (include "bjw-s.common.lib.pod.metadata.annotations" (dict "rootContext" $rootContext "controllerObject" $statefulsetObject)) }}
      annotations: {{ . | nindent 8 }}
      {{- end -}}
      {{- with (include "bjw-s.common.lib.pod.metadata.labels" (dict "rootContext" $rootContext "controllerObject" $statefulsetObject)) }}
      labels: {{ . | nindent 8 }}
      {{- end }}
    spec: {{ include "bjw-s.common.lib.pod.spec" (dict "rootContext" $rootContext "controllerObject" $statefulsetObject) | nindent 6 }}
  {{- with (include "bjw-s.common.lib.statefulset.volumeclaimtemplates" (dict "rootContext" $rootContext "statefulsetObject" $statefulsetObject)) }}
  volumeClaimTemplates: {{ . | nindent 4 }}
  {{- end }}
{{- end }}
