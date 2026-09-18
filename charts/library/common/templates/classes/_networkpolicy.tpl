{{/*
This template serves as a blueprint for all networkPolicy objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.networkpolicy" -}}
  {{- $rootContext := .rootContext -}}
  {{- $networkPolicyObject := .object -}}

  {{- $labels := merge
    ($networkPolicyObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($networkPolicyObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
  {{- $podSelector := dict -}}
  {{- if (hasKey $networkPolicyObject "podSelector") -}}
    {{- $podSelector = $networkPolicyObject.podSelector -}}
  {{- else -}}
    {{- $podSelector = include "bjw-s.common.lib.networkpolicy.controllerSelector" (dict "rootContext" $rootContext "object" $networkPolicyObject "resourceKind" "NetworkPolicy") | fromYaml -}}
  {{- end -}}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ $networkPolicyObject.name }}
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
  podSelector: {{- toYaml $podSelector | nindent 4 }}
  {{- with $networkPolicyObject.policyTypes }}
  policyTypes: {{- toYaml . | nindent 4 -}}
  {{- end }}
  {{- with $networkPolicyObject.rules.ingress }}
  ingress: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml .) "rootContext" $rootContext) | nindent 4 -}}
  {{- end }}
  {{- with $networkPolicyObject.rules.egress }}
  egress: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml .) "rootContext" $rootContext) | nindent 4 -}}
  {{- end }}
{{- end -}}
