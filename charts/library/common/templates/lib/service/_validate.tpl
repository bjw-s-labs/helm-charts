{{/*
Validate Service values
*/}}
{{- define "bjw-s.common.lib.service.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $serviceObject := .object -}}

  {{- $enabledControllers := (include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml ) -}}
  {{- $enabledPorts := include "bjw-s.common.lib.service.enabledPorts" (dict "rootContext" $rootContext "serviceObject" $serviceObject) | fromYaml }}

  {{/* Verify automatic controller detection */}}
  {{- if not (eq 1 (len $enabledControllers)) -}}
    {{- if or (not (has "controller" (keys $serviceObject))) (empty (get $serviceObject "controller")) -}}
      {{- fail (printf "Service '%s': controller field is required because automatic controller detection is not possible (found %d enabled controllers). Please specify which controller this service should use." $serviceObject.identifier (len $enabledControllers)) -}}
    {{- end -}}
  {{- end -}}

  {{- if empty (get $serviceObject "controller") -}}
    {{- fail (printf "controller field is required for Service. (service: %s)" $serviceObject.identifier) -}}
  {{- end -}}

  {{- $serviceController := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $serviceObject.controller) -}}
  {{- if empty $serviceController -}}
    {{- $availableControllers := list -}}
    {{- range $key, $ctrl := $enabledControllers -}}
      {{- $availableControllers = append $availableControllers $key -}}
    {{- end -}}
    {{- fail (printf "Service '%s': No enabled controller found with identifier '%s'. Available controllers: [%s]" $serviceObject.identifier $serviceObject.controller (join ", " $availableControllers)) -}}
  {{- end -}}

  {{- /* Validate Service type */ -}}
  {{- $validServiceTypes := (list "ClusterIP" "LoadBalancer" "NodePort" "ExternalName" "ExternalIP") -}}
  {{- if and $serviceObject.type (not (mustHas $serviceObject.type $validServiceTypes)) -}}
    {{- fail (
      printf "invalid service type \"%s\" for Service with key \"%s\". Allowed values are [%s]"
      $serviceObject.type
      $serviceObject.identifier
      (join ", " $validServiceTypes)
    ) -}}
  {{- end -}}

  {{- if ne $serviceObject.type "ExternalName" -}}
    {{- $enabledPorts := include "bjw-s.common.lib.service.enabledPorts" (dict "rootContext" $rootContext "serviceObject" $serviceObject) | fromYaml }}
    {{- /* Validate at least one port is enabled */ -}}
    {{- if not $enabledPorts -}}
      {{- $serviceType := $serviceObject.type | default "ClusterIP" -}}
      {{- fail (printf "Service '%s': No ports are enabled. At least one port must be enabled for service type '%s'. Add ports under 'services.%s.ports' in your values." $serviceObject.identifier $serviceType $serviceObject.identifier) -}}
    {{- end -}}

    {{- /* Validate no duplicate port number+protocol combinations */ -}}
    {{- $seenPorts := dict -}}
    {{- range $name, $port := $enabledPorts -}}
      {{- if $port.port -}}
        {{- $portProtocol := $port.protocol | default "TCP" -}}
        {{- if has $portProtocol (list "HTTP" "HTTPS") -}}
          {{- $portProtocol = "TCP" -}}
        {{- end -}}
        {{- $portKey := printf "%v/%s" $port.port $portProtocol -}}
        {{- if hasKey $seenPorts $portKey -}}
          {{- fail (printf "Duplicate port %v/%s found in Service. (service: '%s', ports: '%s' and '%s')" $port.port $portProtocol $serviceObject.identifier (get $seenPorts $portKey) $name) -}}
        {{- end -}}
        {{- $_ := set $seenPorts $portKey $name -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
