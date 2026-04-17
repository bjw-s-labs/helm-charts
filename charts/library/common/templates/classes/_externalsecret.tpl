{{/*
This template serves as a blueprint for all ExternalSecret objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.externalsecret" -}}
  {{- $rootContext := .rootContext -}}
  {{- $externalsecretObject := .object -}}

  {{- $apiVersion := "external-secrets.io/v1" -}}
  {{- if $rootContext.Capabilities.APIVersions.Has "external-secrets.io/v1beta1" -}}
    {{- $apiVersion = "external-secrets.io/v1beta1" -}}
  {{- end -}}
  {{- if $rootContext.Capabilities.APIVersions.Has "external-secrets.io/v1" -}}
    {{- $apiVersion = "external-secrets.io/v1" -}}
  {{- end -}}
  {{- $labels := merge
    ($externalsecretObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($externalsecretObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}

---
apiVersion: {{ $apiVersion }}
kind: ExternalSecret
metadata:
  name: {{ $externalsecretObject.name }}
  namespace: {{ $rootContext.Release.Namespace }}
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
spec:
  {{- with $externalsecretObject.refreshInterval }}
  refreshInterval: {{ . }}
  {{- end }}
  {{- with $externalsecretObject.secretStoreRef }}
  secretStoreRef:
    name: {{ .name }}
    kind: {{ .kind }}
  {{- end }}
  {{- with $externalsecretObject.target }}
  target:
    {{- with .name }}
    name: {{ . }}
    {{- end }}
    {{- with .creationPolicy }}
    creationPolicy: {{ . }}
    {{- end }}
    {{- with .deletionPolicy }}
    deletionPolicy: {{ . }}
    {{- end }}
    {{- with .template }}
    template:
      {{- with .type }}
      type: {{ . }}
      {{- end }}
      {{- with .metadata }}
      metadata:
        {{- with .labels }}
        labels:
          {{- range $key, $value := . }}
          {{- printf "%s: %s" $key (tpl $value $rootContext | toYaml ) | nindent 10 }}
          {{- end }}
        {{- end }}
        {{- with .annotations }}
        annotations:
          {{- range $key, $value := . }}
          {{- printf "%s: %s" $key (tpl $value $rootContext | toYaml ) | nindent 10 }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- with .data }}
      data:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .templateFrom }}
      templateFrom:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- with $externalsecretObject.data }}
  data:
    {{- tpl (toYaml .) $rootContext | nindent 2 }}
  {{- end }}
  {{- with $externalsecretObject.dataFrom }}
  dataFrom:
    {{- tpl (toYaml .) $rootContext | nindent 2 }}
  {{- end }}
{{- end -}}
