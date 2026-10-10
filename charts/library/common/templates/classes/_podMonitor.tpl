{{- define "bjw-s.common.class.podMonitor" -}}
  {{- $rootContext := .rootContext -}}
  {{- $podMonitorObject := .object -}}
  {{- $ctx := dict "rootContext" $rootContext "podMonitorObject" $podMonitorObject -}}
  {{- $labels := mergeOverwrite
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
    ($podMonitorObject.labels | default dict)
  -}}
  {{- $annotations := mergeOverwrite
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
    ($podMonitorObject.annotations | default dict)
  -}}

  {{- $controllerObject := dict -}}
  {{- if not (empty (dig "controller" "identifier" nil $podMonitorObject)) -}}
    {{- $controllerObject = (include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $podMonitorObject.controller.identifier) | fromYaml) -}}
    {{- if not $controllerObject -}}
      {{- fail (printf "No enabled controller found with this identifier. (podMonitor: '%s', identifier: '%s')" $podMonitorObject.identifier $podMonitorObject.controller.identifier) -}}
    {{- end -}}
  {{- end -}}
---
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: {{ $podMonitorObject.name }}
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
  jobLabel: {{ include "bjw-s.common.lib.podMonitor.field.jobLabel" (dict "ctx" $ctx) | trim }}
  namespaceSelector:
    matchNames:
      - {{ $rootContext.Release.Namespace }}
  selector:
    {{- if hasKey $podMonitorObject "selector" -}}
      {{- include "bjw-s.common.lib.common.renderString" (dict "value" ($podMonitorObject.selector | toYaml) "rootContext" $rootContext) | nindent 4}}
    {{- else }}
    matchLabels:
      {{- include "bjw-s.common.lib.controller.metadata.selectorLabels" (dict "rootContext" $rootContext "controllerObject" $controllerObject) | nindent 6 }}
    {{- end }}
  podMetricsEndpoints: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml $podMonitorObject.podMetricsEndpoints) "rootContext" $rootContext) | nindent 4 }}
  {{- if not (empty $podMonitorObject.podTargetLabels) }}
  podTargetLabels:
    {{- toYaml $podMonitorObject.podTargetLabels | nindent 4 }}
  {{- end }}
{{- end }}
