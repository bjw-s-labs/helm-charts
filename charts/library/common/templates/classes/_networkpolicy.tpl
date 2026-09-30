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
    {{- /* Determine the controller identifier to use */ -}}
    {{- $controllerIdentifier := "" -}}
    {{- if and (hasKey $networkPolicyObject "controller") $networkPolicyObject.controller -}}
      {{- $controllerIdentifier = $networkPolicyObject.controller -}}
    {{- else -}}
      {{- /* Auto-detect: if only one controller exists, use it */ -}}
      {{- $enabledControllers := (include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml) -}}
      {{- if eq (len $enabledControllers) 1 -}}
        {{- $controllerIdentifier = keys $enabledControllers | first -}}
      {{- end -}}
    {{- end -}}

    {{- $controllerObject := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $controllerIdentifier) | fromYaml -}}
    {{- $selectorLabels := include "bjw-s.common.lib.controller.metadata.selectorLabels" (dict "rootContext" $rootContext "controllerObject" $controllerObject) | fromYaml -}}
    {{- /* Add extra selector labels last (takes precedence) */ -}}
    {{- if hasKey $networkPolicyObject "extraSelectorLabels" -}}
      {{- $selectorLabels = mergeOverwrite
        (dict)
        $selectorLabels
        ($networkPolicyObject.extraSelectorLabels | default dict)
      -}}
    {{- end -}}
    {{- $podSelector = dict "matchLabels" $selectorLabels -}}
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
  ingress: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (include "bjw-s.common.lib.networkpolicy.rules" (dict "rootContext" $rootContext "rules" . "direction" "ingress")) "rootContext" $rootContext) | nindent 4 -}}
  {{- end }}
  {{- with $networkPolicyObject.rules.egress }}
  egress: {{- include "bjw-s.common.lib.common.renderString" (dict "value" (include "bjw-s.common.lib.networkpolicy.rules" (dict "rootContext" $rootContext "rules" . "direction" "egress")) "rootContext" $rootContext) | nindent 4 -}}
  {{- end }}
{{- end -}}
