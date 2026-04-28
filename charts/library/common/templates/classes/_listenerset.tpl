{{/*
This template serves as a blueprint for all ListenerSet objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.listenerSet" -}}
  {{- $rootContext := .rootContext -}}
  {{- $listenerSetObject := .object -}}

  {{- $apiVersion := "gateway.networking.k8s.io/v1alpha2" -}}
  {{- if $rootContext.Capabilities.APIVersions.Has "gateway.networking.k8s.io/v1/ListenerSet" }}
    {{- $apiVersion = "gateway.networking.k8s.io/v1" -}}
  {{- end -}}
  {{- $labels := merge
    ($listenerSetObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($listenerSetObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
---
apiVersion: {{ $apiVersion }}
kind: ListenerSet
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
  namespace: {{ $rootContext.Release.Namespace }}
spec:
  parentRef:
    group: {{ $listenerSetObject.parentRef.group | default "gateway.networking.k8s.io" }}
    kind: {{ $listenerSetObject.parentRef.kind | default "Gateway" }}
    name: {{ required (printf "parentRef name is required for ListenerSet %v" $listenerSetObject.identifier) $listenerSetObject.parentRef.name }}
    {{- with $listenerSetObject.parentRef.namespace }}
    namespace: {{ . }}
    {{- end }}
  listeners:
  {{- toYaml $listenerSetObject.listeners | nindent 4 }}
{{- end }}
