{{/*
This template serves as a blueprint for all ciliumNetworkPolicy objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.ciliumNetworkPolicy" -}}
  {{- $rootContext := .rootContext -}}
  {{- $ciliumNetworkPolicyObject := .object -}}

  {{- $labels := merge
    ($ciliumNetworkPolicyObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($ciliumNetworkPolicyObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
  {{- $clusterwide := eq ($ciliumNetworkPolicyObject.type | default "cilium") "ciliumClusterwide" -}}
  {{- $endpointSelector := dict -}}
  {{- if hasKey $ciliumNetworkPolicyObject "nodeSelector" -}}
    {{- /* CiliumClusterwideNetworkPolicy node selectors replace endpoint selectors. */ -}}
  {{- else if (hasKey $ciliumNetworkPolicyObject "endpointSelector") -}}
    {{- $endpointSelector = $ciliumNetworkPolicyObject.endpointSelector -}}
  {{- else -}}
    {{- $resourceKind := ternary "CiliumClusterwideNetworkPolicy" "CiliumNetworkPolicy" $clusterwide -}}
    {{- $endpointSelector = include "bjw-s.common.lib.networkpolicy.controllerSelector" (dict "rootContext" $rootContext "object" $ciliumNetworkPolicyObject "resourceKind" $resourceKind) | fromYaml -}}
  {{- end -}}
---
apiVersion: cilium.io/v2
kind: {{ if $clusterwide }}CiliumClusterwideNetworkPolicy{{ else }}CiliumNetworkPolicy{{ end }}
metadata:
  name: {{ $ciliumNetworkPolicyObject.name }}
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
  {{ if not $clusterwide }}namespace: {{ $rootContext.Release.Namespace }}{{ end }}
spec:
  {{ if hasKey $ciliumNetworkPolicyObject "nodeSelector" }}nodeSelector: {{ include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml $ciliumNetworkPolicyObject.nodeSelector) "rootContext" $rootContext) | nindent 4 }}
  {{ else }}endpointSelector: {{ toYaml $endpointSelector | nindent 4 }}{{ end }}
  {{- with $ciliumNetworkPolicyObject.description }}
  description: {{ include "bjw-s.common.lib.common.renderString" (dict "value" . "rootContext" $rootContext) | quote }}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.ingress }}
  ingress: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml .) "rootContext" $rootContext) | nindent 4 -}}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.ingressDeny }}
  ingressDeny: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml .) "rootContext" $rootContext) | nindent 4 -}}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.egress }}
  egress: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml .) "rootContext" $rootContext) | nindent 4 -}}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.egressDeny }}
  egressDeny: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml .) "rootContext" $rootContext) | nindent 4 -}}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.enableDefaultDeny }}
  enableDefaultDeny: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.log }}
  log:
    value: {{ . | quote }}
  {{- end }}
{{- end -}}
