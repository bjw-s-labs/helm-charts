{{/*
This template serves as a blueprint for all PersistentVolumeClaim objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.pvc" -}}
  {{- $rootContext := .rootContext -}}
  {{- $pvcObject := .object -}}

  {{- $labels := merge
    ($pvcObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($pvcObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
  {{- if $pvcObject.retain }}
    {{- $annotations = merge
      (dict "helm.sh/resource-policy" "keep")
      $annotations
    -}}
  {{- end -}}
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: {{ $pvcObject.name }}
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
  accessModes:
    - {{ required (printf "accessMode is required for PVC %v" $pvcObject.name) $pvcObject.accessMode | quote }}
  resources:
    requests:
      storage: {{ required (printf "size is required for PVC %v" $pvcObject.name) $pvcObject.size | quote }}
  {{- if $pvcObject.storageClass }}
  storageClassName: {{ if (eq "-" $pvcObject.storageClass) }}""{{- else }}{{ $pvcObject.storageClass | quote }}{{- end }}
  {{- end }}
  {{- if $pvcObject.volumeName }}
  volumeName: {{ $pvcObject.volumeName | quote }}
  {{- end }}
  {{- with $pvcObject.dataSource }}
  dataSource: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml .) "rootContext" $rootContext) | nindent 10 }}
  {{- end }}
  {{- with $pvcObject.dataSourceRef }}
  dataSourceRef: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml .) "rootContext" $rootContext) | nindent 10 }}
  {{- end }}
{{- end -}}
