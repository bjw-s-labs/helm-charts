{{/*
This template serves as a blueprint for all ListenerSet objects that are
created within the common library.
*/}}
{{- define "bjw-s.common.class.listenerSet" -}}
  {{- $rootContext := .rootContext -}}
  {{- $listenerSetObject := .object -}}

  {{- $labels := merge
    ($listenerSetObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($listenerSetObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
---
apiVersion: {{ $listenerSetObject.apiVersion }}
kind: {{ $listenerSetObject.kind }}
metadata:
  name: {{ $listenerSetObject.name }}
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
  namespace: {{ $listenerSetObject.namespaceOverride | default $rootContext.Release.Namespace }}
spec:
  parentRef:
    group: {{ $listenerSetObject.parentRef.group | default "gateway.networking.k8s.io" }}
    kind: {{ $listenerSetObject.parentRef.kind | default "Gateway" }}
    name: {{ $listenerSetObject.parentRef.name }}
    {{- if $listenerSetObject.parentRef.namespace }}
    namespace: {{ $listenerSetObject.parentRef.namespace | quote }}
    {{- end }}
  listeners:
  {{- range $listenerSetObject.listeners }}
    - name: {{ .name }}
      {{- if .hostname }}
      hostname: {{ tpl .hostname $rootContext | quote }}
      {{- end }}
      port: {{ .port }}
      protocol: {{ .protocol }}
      {{- with .tls }}
      tls: {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .allowedRoutes }}
      allowedRoutes: {{- toYaml . | nindent 8 }}
      {{- end }}
  {{- end }}
{{- end -}}
