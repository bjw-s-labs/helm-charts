{{- define "bjw-s.common.class.serviceMonitor" -}}
  {{- $rootContext := .rootContext -}}
  {{- $serviceMonitorObject := .object -}}
  {{- $labels := merge
    ($serviceMonitorObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($serviceMonitorObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
  {{ $service := dict -}}
  {{ $serviceName := "" -}}
  {{ if $serviceMonitorObject.serviceName -}}
    {{ $serviceName = tpl $serviceMonitorObject.serviceName $rootContext -}}
  {{ else if not (empty (dig "service" "name" nil $serviceMonitorObject)) -}}
    {{ $serviceName = tpl $serviceMonitorObject.service.name $rootContext -}}
  {{ else if not (empty (dig "service" "identifier" nil $serviceMonitorObject)) -}}
    {{ $service = (include "bjw-s.common.lib.service.getByIdentifier" (dict "rootContext" $rootContext "id" $serviceMonitorObject.service.identifier) | fromYaml ) -}}
    {{ if not $service -}}
      {{fail (printf "No enabled Service found with this identifier. (serviceMonitor: '%s', identifier: '%s')" $serviceMonitorObject.identifier $serviceMonitorObject.service.identifier)}}
    {{ end -}}
    {{ $serviceName = $service.name -}}
  {{ end -}}
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ $serviceMonitorObject.name }}
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
  jobLabel: "{{ $serviceMonitorObject.name }}"
  namespaceSelector:
    matchNames:
      - {{ $rootContext.Release.Namespace }}
  selector:
    {{- if $serviceMonitorObject.selector -}}
      {{- tpl ($serviceMonitorObject.selector | toYaml) $rootContext | nindent 4}}
    {{- else }}
    matchLabels:
      app.kubernetes.io/service: {{ $serviceName }}
      {{- include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | nindent 6 }}
    {{- end }}
  endpoints: {{- tpl (toYaml $serviceMonitorObject.endpoints) $rootContext | nindent 4 }}
  {{- if not (empty $serviceMonitorObject.targetLabels )}}
  targetLabels:
    {{- toYaml $serviceMonitorObject.targetLabels | nindent 4 }}
  {{- end }}
{{- end }}
