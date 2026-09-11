{{/*
This template serves as a blueprint for all ExternalSecret objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.externalSecret" -}}
  {{- $rootContext := .rootContext -}}
  {{- $externalSecretObject := .object -}}

  {{- $labels := merge
    ($externalSecretObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($externalSecretObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
  {{- $secretStoreRef := mergeOverwrite
    (deepCopy ($rootContext.Values.defaultExternalSecretStoreRef | default dict))
    (deepCopy ($externalSecretObject.secretStoreRef | default dict))
  -}}
  {{- $target := mergeOverwrite
    (dict "deletionPolicy" "Delete")
    (deepCopy ($externalSecretObject.target | default dict))
  -}}

---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: {{ $externalSecretObject.name }}
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
  {{- with $externalSecretObject.refreshPolicy }}
  refreshPolicy: {{ . }}
  {{- end }}
  {{- with $externalSecretObject.refreshInterval }}
  refreshInterval: {{ . | quote }}
  {{- end }}
  {{- if $secretStoreRef.name }}
  secretStoreRef: {{- toYaml $secretStoreRef | nindent 4 -}}
  {{- end }}
  {{- with $externalSecretObject.syncWindows }}
  syncWindows: {{- toYaml . | nindent 4 -}}
  {{- end }}
  {{- with $target }}
  target: {{- toYaml . | nindent 4 -}}
  {{- end }}
  {{- with $externalSecretObject.data }}
  data: {{- toYaml . | nindent 4 -}}
  {{- end }}
  {{- with $externalSecretObject.dataFrom }}
  dataFrom: {{- toYaml . | nindent 4 -}}
  {{- end }}
{{- end -}}
