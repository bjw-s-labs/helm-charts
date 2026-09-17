{{/*
This template serves as a blueprint for all Secret objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.secret" -}}
  {{- $rootContext := .rootContext -}}
  {{- $secretObject := .object -}}

  {{- $labels := merge
    ($secretObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($secretObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}

  {{- $stringData := "" -}}
  {{- with $secretObject.stringData -}}
    {{- $stringData = (toYaml $secretObject.stringData) | trim -}}
  {{- end -}}
---
apiVersion: v1
kind: Secret
{{- with $secretObject.type }}
type: {{ . }}
{{- end }}
metadata:
  name: {{ $secretObject.name }}
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
{{- with $stringData }}
stringData: {{- include "bjw-s.common.lib.common.renderString" (dict "value" $stringData "rootContext" $rootContext "render" ($secretObject.renderFileContent | default false)) | nindent 2 }}
{{- end }}
{{- end -}}
