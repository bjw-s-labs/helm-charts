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

    {{- /* Build the pod selector */ -}}
    {{- $selectorLabels := dict "app.kubernetes.io/controller" $controllerIdentifier -}}
    {{- /* Add global selector labels first */ -}}
    {{- $selectorLabels = merge
      (include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | fromYaml)
      $selectorLabels
    -}}
    {{- /* Add extra selector labels last (takes precedence) */ -}}
    {{- if hasKey $networkPolicyObject "extraSelectorLabels" -}}
      {{- $selectorLabels = merge
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
  podSelector: {{- toYaml $podSelector | nindent 4 }}
  {{- with $networkPolicyObject.policyTypes }}
  policyTypes: {{- toYaml . | nindent 4 -}}
  {{- end }}
  {{- with $networkPolicyObject.rules.ingress }}
  ingress: {{- tpl (toYaml .) $rootContext | nindent 4 -}}
  {{- end }}
  {{- with $networkPolicyObject.rules.egress }}
  egress: {{- tpl (toYaml .) $rootContext | nindent 4 -}}
  {{- end }}
{{- end -}}
