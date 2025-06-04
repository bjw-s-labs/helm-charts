{{/*
This template serves as a blueprint for all Service objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.service" -}}
  {{- $rootContext := .rootContext -}}
  {{- $serviceObject := .object -}}

  {{- $svcType := default "ClusterIP" $serviceObject.type -}}
  {{- $enabledPorts := include "bjw-s.common.lib.service.enabledPorts" (dict "rootContext" $rootContext "serviceObject" $serviceObject) | fromYaml }}
  {{- $labels := merge
    (dict "app.kubernetes.io/service" $serviceObject.name)
    ($serviceObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($serviceObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $serviceObject.name }}
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
  {{- if (eq $svcType "ClusterIP") }}
  type: ClusterIP
  {{- if $serviceObject.clusterIP }}
  clusterIP: {{ $serviceObject.clusterIP }}
  {{end}}
  {{- else if eq $svcType "LoadBalancer" }}
  type: {{ $svcType }}
  {{- if $serviceObject.loadBalancerIP }}
  loadBalancerIP: {{ $serviceObject.loadBalancerIP }}
  {{- end }}
  {{- if $serviceObject.loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
    {{ toYaml $serviceObject.loadBalancerSourceRanges | nindent 4 }}
  {{- end -}}
  {{- if $serviceObject.loadBalancerClass }}
  loadBalancerClass: {{ $serviceObject.loadBalancerClass }}
  {{- end -}}
  {{- else if eq $svcType "ExternalName" }}
  type: {{ $svcType }}
  {{- if $serviceObject.externalName }}
  externalName: {{ $serviceObject.externalName }}
  {{- end }}
  {{- else }}
  type: {{ $svcType }}
  {{- end }}
  {{- if $serviceObject.internalTrafficPolicy }}
  internalTrafficPolicy: {{ $serviceObject.internalTrafficPolicy }}
  {{- end }}
  {{- if $serviceObject.externalTrafficPolicy }}
  externalTrafficPolicy: {{ $serviceObject.externalTrafficPolicy }}
  {{- end }}
  {{- if hasKey $serviceObject "allocateLoadBalancerNodePorts" }}
  allocateLoadBalancerNodePorts: {{ $serviceObject.allocateLoadBalancerNodePorts }}
  {{- end }}
  {{- if $serviceObject.sessionAffinity }}
  sessionAffinity: {{ $serviceObject.sessionAffinity }}
  {{- if $serviceObject.sessionAffinityConfig }}
  sessionAffinityConfig:
    {{ toYaml $serviceObject.sessionAffinityConfig | nindent 4 }}
  {{- end -}}
  {{- end }}
  {{- with $serviceObject.externalIPs }}
  externalIPs:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if $serviceObject.publishNotReadyAddresses }}
  publishNotReadyAddresses: {{ $serviceObject.publishNotReadyAddresses }}
  {{- end }}
  {{- if $serviceObject.ipFamilyPolicy }}
  ipFamilyPolicy: {{ $serviceObject.ipFamilyPolicy }}
  {{- end }}
  {{- with $serviceObject.ipFamilies }}
  ipFamilies:
    {{ toYaml . | nindent 4 }}
  {{- end }}
  ports:
  {{- range $name, $port := $enabledPorts }}
    {{- if $port.portRange }}
      {{- range $portnum := untilStep $port.portRange.start $port.portRange.stop 1 }}
    - port: {{ $portnum }}
      targetPort: {{ $port.targetPort | default $port.port }}
        {{- if $port.protocol }}
          {{- if or ( eq $port.protocol "HTTP" ) ( eq $port.protocol "HTTPS" ) ( eq $port.protocol "TCP" ) }}
      protocol: TCP
          {{- else }}
      protocol: {{ $port.protocol }}
          {{- end }}
        {{- else }}
      protocol: TCP
        {{- end }}
      name: {{ $name }}
        {{- if (not (empty $port.nodePort)) }}
      nodePort: {{ $port.nodePort }}
        {{ end }}
        {{- if (not (empty $port.appProtocol)) }}
      appProtocol: {{ $port.appProtocol }}
        {{ end }}
      {{ - end }}
    {{- end }}
    - port: {{ $port.port }}
      targetPort: {{ $port.targetPort | default $port.port }}
        {{- if $port.protocol }}
          {{- if or ( eq $port.protocol "HTTP" ) ( eq $port.protocol "HTTPS" ) ( eq $port.protocol "TCP" ) }}
      protocol: TCP
          {{- else }}
      protocol: {{ $port.protocol }}
          {{- end }}
        {{- else }}
      protocol: TCP
        {{- end }}
      name: {{ $name }}
        {{- if (not (empty $port.nodePort)) }}
      nodePort: {{ $port.nodePort }}
        {{ end }}
        {{- if (not (empty $port.appProtocol)) }}
      appProtocol: {{ $port.appProtocol }}
        {{ end }}
      {{- end -}}
  {{- with (merge
    ($serviceObject.extraSelectorLabels | default dict)
    (dict "app.kubernetes.io/controller" $serviceObject.controller)
    (include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | fromYaml)
  ) }}
  selector: {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
