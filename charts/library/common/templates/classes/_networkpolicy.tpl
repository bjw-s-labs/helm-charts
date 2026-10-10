{{/*
This template serves as a blueprint for all networkPolicy objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.networkpolicy" -}}
  {{- $rootContext := .rootContext -}}
  {{- $networkPolicyObject := .object -}}

  {{- $labels := mergeOverwrite
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
    ($networkPolicyObject.labels | default dict)
  -}}
  {{- $annotations := mergeOverwrite
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
    ($networkPolicyObject.annotations | default dict)
  -}}
  {{- $podSelector := dict -}}
  {{- if (hasKey $networkPolicyObject "podSelector") -}}
    {{- $podSelector = $networkPolicyObject.podSelector -}}
  {{- else -}}
    {{- $controllerIdentifiers := list -}}
    {{- if $networkPolicyObject.controllers -}}
      {{- $controllerIdentifiers = include "bjw-s.common.lib.controller.resolveReferences" (dict "rootContext" $rootContext "references" $networkPolicyObject.controllers "resourceKind" "NetworkPolicy" "policyIdentifier" $networkPolicyObject.identifier "referencePath" (printf "networkpolicies.%s.controllers" $networkPolicyObject.identifier)) | fromYamlArray -}}
    {{- else if $networkPolicyObject.controller -}}
      {{- $controllerIdentifiers = list $networkPolicyObject.controller -}}
    {{- else -}}
      {{- $enabledControllers := include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml -}}
      {{- if eq (len $enabledControllers) 1 -}}
        {{- $controllerIdentifiers = keys $enabledControllers -}}
      {{- end -}}
    {{- end -}}
    {{- $podSelector = include "bjw-s.common.lib.networkpolicy.controllerSelector" (dict "rootContext" $rootContext "controllerIdentifiers" $controllerIdentifiers "extraSelectorLabels" $networkPolicyObject.extraSelectorLabels) | fromYaml -}}
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
  ingress: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (include "bjw-s.common.lib.networkpolicy.rules" (dict "rootContext" $rootContext "rules" . "direction" "ingress" "policyIdentifier" $networkPolicyObject.identifier)) "rootContext" $rootContext) | nindent 4 -}}
  {{- end }}
  {{- with $networkPolicyObject.rules.egress }}
  egress: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (include "bjw-s.common.lib.networkpolicy.rules" (dict "rootContext" $rootContext "rules" . "direction" "egress" "policyIdentifier" $networkPolicyObject.identifier)) "rootContext" $rootContext) | nindent 4 -}}
  {{- end }}
{{- end -}}
