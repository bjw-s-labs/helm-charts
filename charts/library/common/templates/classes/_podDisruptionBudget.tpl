{{/*
This template serves as a blueprint for PodDisruptionBudget objects that are created
using the common library.
*/}}
{{- define "bjw-s.common.class.podDisruptionBudget" -}}
  {{- $rootContext := .rootContext -}}
  {{- $podDisruptionBudgetObject := .object -}}

  {{- $labels := merge
    (dict "app.kubernetes.io/controller" $podDisruptionBudgetObject.controller)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($podDisruptionBudgetObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}

  {{- $selector := dict "matchLabels" (merge
    (dict "app.kubernetes.io/controller" $podDisruptionBudgetObject.controller)
    (include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | fromYaml)
  ) -}}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ $podDisruptionBudgetObject.name }}
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
  selector: {{- toYaml $selector | nindent 4 }}
  {{- with $podDisruptionBudgetObject }}
  {{- if .minAvailable }}
  minAvailable: {{ .minAvailable }}
  {{- end }}
  {{- if .maxUnavailable }}
  maxUnavailable: {{ .maxUnavailable }}
  {{- end }}
  {{- end }}
{{- end -}}
