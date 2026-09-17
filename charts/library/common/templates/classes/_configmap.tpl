{{/*
This template serves as a blueprint for all configMap objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.configMap" -}}
  {{- $rootContext := .rootContext -}}
  {{- $configMapObject := .object -}}

  {{- $labels := merge
    ($configMapObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($configMapObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $configMapObject.name }}
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
{{- with $configMapObject.data }}
data:
    {{- include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml .) "rootContext" $rootContext "render" ($configMapObject.renderFileContent | default false)) | nindent 2 }}
{{- end }}
{{- with $configMapObject.binaryData }}
binaryData:
    {{- include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml .) "rootContext" $rootContext "render" ($configMapObject.renderFileContent | default false)) | nindent 2 }}
{{- end }}
{{- end -}}
