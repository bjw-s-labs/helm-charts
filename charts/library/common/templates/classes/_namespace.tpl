{{/*
This template serves as a blueprint for the Namespace object that is created
using the common library.
*/}}
{{- define "bjw-s.common.class.namespace" -}}
  {{- $rootContext := .rootContext -}}
  {{- $namespaceObject := .object -}}

  {{- $labels := mergeOverwrite
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
    ($namespaceObject.labels | default dict)
  -}}
  {{- $annotations := mergeOverwrite
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
    ($namespaceObject.annotations | default dict)
  -}}
---
apiVersion: v1
kind: Namespace
metadata:
  name: {{ $rootContext.Release.Namespace }}
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
{{- end -}}
