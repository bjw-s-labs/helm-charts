{{/*
This template serves as a blueprint for all raw resource objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.rawResource" -}}
  {{- $rootContext := .rootContext -}}
  {{- $manifest := .object.manifest -}}
  {{- $internalData := .object._internal -}}

  {{- $userLabels := dict -}}
  {{- $userAnnotations := dict -}}
  {{- if $manifest.metadata -}}
    {{- $userLabels = $manifest.metadata.labels | default dict -}}
    {{- $userAnnotations = $manifest.metadata.annotations | default dict -}}
  {{- end -}}
  {{- $labels := merge
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
    $userLabels
  -}}
  {{- $annotations := merge
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
    $userAnnotations
  -}}
  {{- $manifestWithoutMetadata := omit $manifest "metadata" "apiVersion" "kind" -}}
---
apiVersion: {{ $manifest.apiVersion }}
kind: {{ $manifest.kind }}
metadata:
  name: {{ $internalData.name }}
  {{- with ($manifest.metadata).namespace }}
  namespace: {{ tpl . $rootContext | quote }}
  {{- end }}
  {{- with $labels }}
  labels:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- tpl (toYaml $manifestWithoutMetadata) $rootContext | nindent 0 }}
{{- end -}}
