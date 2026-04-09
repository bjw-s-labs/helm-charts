{{- define "bjw-s.common.class.podMonitor" -}}
  {{- $rootContext := .rootContext -}}
  {{- $podMonitorObject := .object -}}
  {{- $ctx := dict "rootContext" $rootContext "podMonitorObject" $podMonitorObject -}}
  {{- $labels := merge
    ($podMonitorObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($podMonitorObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}

  {{- $controllerIdentifier := "" -}}
  {{- if not (empty (dig "controller" "identifier" nil $podMonitorObject)) -}}
    {{- $controllerObject := (include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $podMonitorObject.controller.identifier) | fromYaml) -}}
    {{- if not $controllerObject -}}
      {{- fail (printf "No enabled controller found with this identifier. (podMonitor: '%s', identifier: '%s')" $podMonitorObject.identifier $podMonitorObject.controller.identifier) -}}
    {{- end -}}
    {{- $controllerIdentifier = $podMonitorObject.controller.identifier -}}
  {{- end -}}
---
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: {{ $podMonitorObject.name }}
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
  jobLabel: {{ include "bjw-s.common.lib.podMonitor.field.jobLabel" (dict "ctx" $ctx) | trim }}
  namespaceSelector:
    matchNames:
      - {{ $rootContext.Release.Namespace }}
  selector:
    {{- if $podMonitorObject.selector -}}
      {{- tpl ($podMonitorObject.selector | toYaml) $rootContext | nindent 4}}
    {{- else }}
    matchLabels:
      app.kubernetes.io/controller: {{ $controllerIdentifier }}
      {{- include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | nindent 6 }}
    {{- end }}
  podMetricsEndpoints: {{- tpl (toYaml $podMonitorObject.podMetricsEndpoints) $rootContext | nindent 4 }}
  {{- if not (empty $podMonitorObject.podTargetLabels) }}
  podTargetLabels:
    {{- toYaml $podMonitorObject.podTargetLabels | nindent 4 }}
  {{- end }}
{{- end }}
