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

  {{/* Render defaults explicitly to prevent Argo CD drift. Unlike ESO, default
       deletionPolicy is set to Delete to favor cleanup of old secrets. */}}
  {{- $target := mergeOverwrite
    (dict "creationPolicy" "Owner" "deletionPolicy" "Delete")
    (deepCopy ($externalSecretObject.target | default dict))
  -}}
  {{- if hasKey $target "template" -}}
    {{- $_ := set $target "template" (mergeOverwrite
      (dict "engineVersion" "v2" "mergePolicy" "Replace")
      (deepCopy $target.template)
    ) -}}
  {{- end -}}

  {{- $data := deepCopy ($externalSecretObject.data | default list) -}}
  {{- $dataFrom := deepCopy ($externalSecretObject.dataFrom | default list) -}}
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
  refreshInterval: {{ $externalSecretObject.refreshInterval | default "1h0m0s" | quote }}
  {{- with $secretStoreRef }}
  secretStoreRef: {{- toYaml . | nindent 4 -}}
  {{- end }}
  {{- with $externalSecretObject.syncWindows }}
  syncWindows: {{- toYaml . | nindent 4 -}}
  {{- end }}
  {{- with $target }}
  target: {{- toYaml . | nindent 4 -}}
  {{- end }}
  {{- with $data }}
  data: {{- toYaml . | nindent 4 -}}
  {{- end }}
  {{- with $dataFrom }}
  dataFrom: {{- toYaml . | nindent 4 -}}
  {{- end }}
{{- end -}}
