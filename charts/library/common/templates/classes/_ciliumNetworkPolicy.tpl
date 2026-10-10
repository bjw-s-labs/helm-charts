{{/*
This template serves as a blueprint for all ciliumNetworkPolicy objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.ciliumNetworkPolicy" -}}
  {{- $rootContext := .rootContext -}}
  {{- $ciliumNetworkPolicyObject := .object -}}

  {{- $labels := mergeOverwrite
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
    ($ciliumNetworkPolicyObject.labels | default dict)
  -}}
  {{- $annotations := mergeOverwrite
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
    ($ciliumNetworkPolicyObject.annotations | default dict)
  -}}
  {{- $clusterwide := eq ($ciliumNetworkPolicyObject.type | default "cilium") "ciliumClusterwide" -}}
  {{- $resourceKind := ternary "CiliumClusterwideNetworkPolicy" "CiliumNetworkPolicy" $clusterwide -}}
  {{- $endpointSelector := dict -}}
  {{- if hasKey $ciliumNetworkPolicyObject "nodeSelector" -}}
    {{- /* CiliumClusterwideNetworkPolicy node selectors replace endpoint selectors. */ -}}
  {{- else if (hasKey $ciliumNetworkPolicyObject "endpointSelector") -}}
    {{- $endpointSelector = $ciliumNetworkPolicyObject.endpointSelector -}}
  {{- else -}}
    {{- $controllerIdentifiers := list -}}
    {{- if $ciliumNetworkPolicyObject.controllers -}}
      {{- $controllerIdentifiers = include "bjw-s.common.lib.controller.resolveReferences" (dict "rootContext" $rootContext "references" $ciliumNetworkPolicyObject.controllers "resourceKind" $resourceKind "policyIdentifier" $ciliumNetworkPolicyObject.identifier "referencePath" (printf "networkpolicies.%s.controllers" $ciliumNetworkPolicyObject.identifier)) | fromYamlArray -}}
    {{- else if $ciliumNetworkPolicyObject.controller -}}
      {{- $controllerIdentifiers = list $ciliumNetworkPolicyObject.controller -}}
    {{- else -}}
      {{- $enabledControllers := include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml -}}
      {{- if eq (len $enabledControllers) 1 -}}
        {{- $controllerIdentifiers = keys $enabledControllers -}}
      {{- end -}}
    {{- end -}}
    {{- $endpointSelector = include "bjw-s.common.lib.networkpolicy.controllerSelector" (dict "rootContext" $rootContext "controllerIdentifiers" $controllerIdentifiers "extraSelectorLabels" $ciliumNetworkPolicyObject.extraSelectorLabels) | fromYaml -}}
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
  ingress: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (include "bjw-s.common.lib.ciliumNetworkPolicy.rules" (dict "rootContext" $rootContext "rules" . "direction" "ingress" "policyIdentifier" $ciliumNetworkPolicyObject.identifier "resourceKind" $resourceKind)) "rootContext" $rootContext) | nindent 4 -}}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.ingressDeny }}
  ingressDeny: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (toYaml .) "rootContext" $rootContext) | nindent 4 -}}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.egress }}
  egress: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (include "bjw-s.common.lib.ciliumNetworkPolicy.rules" (dict "rootContext" $rootContext "rules" . "direction" "egress" "policyIdentifier" $ciliumNetworkPolicyObject.identifier "resourceKind" $resourceKind)) "rootContext" $rootContext) | nindent 4 -}}
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
