{{/*
This template serves as a blueprint for all Route objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.route" -}}
  {{- $rootContext := .rootContext -}}
  {{- $routeObject := .object -}}

  {{- $routeKind := $routeObject.kind | default "HTTPRoute" -}}
  {{- $apiVersion := "gateway.networking.k8s.io/v1alpha2" -}}
  {{- if $rootContext.Capabilities.APIVersions.Has (printf "gateway.networking.k8s.io/v1beta1/%s" $routeKind) }}
    {{- $apiVersion = "gateway.networking.k8s.io/v1beta1" -}}
  {{- end -}}
  {{- if $rootContext.Capabilities.APIVersions.Has (printf "gateway.networking.k8s.io/v1/%s" $routeKind) }}
    {{- $apiVersion = "gateway.networking.k8s.io/v1" -}}
  {{- end -}}
  {{- $labels := merge
    ($routeObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($routeObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
---
apiVersion: {{ $apiVersion }}
kind: {{ $routeKind }}
metadata:
  name: {{ $routeObject.name }}
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
  parentRefs:
  {{- range $routeObject.parentRefs }}
    - group: {{ .group | default "gateway.networking.k8s.io" }}
      kind: {{ .kind | default "Gateway" }}
      name: {{ required (printf "parentRef name is required for %v %v" $routeKind $routeObject.name) .name }}
      namespace: {{ required (printf "parentRef namespace is required for %v %v" $routeKind $routeObject.name) .namespace }}
      {{- if .sectionName }}
      sectionName: {{ .sectionName | quote }}
      {{- end }}
      {{- if .port }}
      port: {{ .port }}
      {{- end }}
  {{- end }}
  {{- if and (ne $routeKind "TCPRoute") (ne $routeKind "UDPRoute") $routeObject.hostnames }}
  hostnames:
    {{- range $routeObject.hostnames }}
    - {{ tpl . $rootContext | quote }}
    {{- end }}
  {{- end }}
  rules:
  {{- range $routeObject.rules }}
    - {{- if .name }}
      name: {{ tpl .name $rootContext }}
      {{- end }}
      backendRefs:
      {{- if empty .backendRefs }}
        {{- printf " []" }}
      {{- else }}
        {{- range .backendRefs }}
          {{- $service := dict }}
          {{- $serviceName := "" }}
          {{- $servicePort := 0 }}
          {{- if .name }}
            {{- $serviceName = tpl .name $rootContext }}
          {{- else if .identifier }}
            {{- $service = (include "bjw-s.common.lib.service.getByIdentifier" (dict "rootContext" $rootContext "id" .identifier) | fromYaml ) }}
            {{- if not $service }}
              {{- fail (printf "No enabled Service found with this identifier. (route: '%s', identifier: '%s')" $routeObject.identifier .identifier) }}
            {{- end }}
            {{- $serviceName = $service.name }}
          {{- end }}
          {{- if empty .port }}
            {{/*- Default to the Service primary port if no port has been specified */}}
            {{- if $service }}
              {{- $defaultServicePort := include "bjw-s.common.lib.service.primaryPort" (dict "rootContext" $rootContext "serviceObject" $service) | fromYaml }}
              {{- if $defaultServicePort }}
                {{- $servicePort = $defaultServicePort.port }}
              {{- end }}
            {{- end }}
          {{- else }}
            {{/*- If a port number is given, use that */}}
            {{- if kindIs "float64" .port }}
              {{- $servicePort = .port }}
            {{- else if kindIs "string" .port }}
              {{/*- If a port name is given, try to resolve to a number */}}
              {{- $servicePort = include "bjw-s.common.lib.service.getPortNumberByName" (dict "rootContext" $rootContext "serviceID" $service.identifier "portName" .port) }}
            {{- end }}
          {{- end }}
      - group: {{ .group | default "" | quote}}
        kind: {{ .kind | default "Service" }}
        name: {{ $serviceName }}
        namespace: {{ .namespace | default $rootContext.Release.Namespace }}
        port: {{ $servicePort }}
        weight: {{ include "bjw-s.common.lib.defaultKeepNonNullValue" (dict "value" .weight "default" 1) }}
        {{- end }}
      {{- end }}
      {{- if or (eq $routeKind "HTTPRoute") (eq $routeKind "GRPCRoute") }}
        {{- with .matches }}
      matches: {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with .filters }}
      filters: {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with .sessionPersistence }}
      sessionPersistence: {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- end }}
      {{- if (eq $routeKind "HTTPRoute") }}
        {{- with .timeouts }}
      timeouts: {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- end }}
  {{- end }}
{{- end }}
