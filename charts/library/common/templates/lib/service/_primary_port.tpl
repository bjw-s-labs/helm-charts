{{/*
Return the primary port for a given Service object.
*/}}
{{- define "bjw-s.common.lib.service.primaryPort" -}}
  {{- $rootContext := .rootContext -}}
  {{- $serviceObject := .serviceObject -}}
  {{- $result := "" -}}

  {{- /* Loop over all enabled ports that explicitly define a port */ -}}
  {{- $enabledPorts := include "bjw-s.common.lib.service.enabledPorts" (dict "rootContext" $rootContext "serviceObject" $serviceObject) | fromYaml }}
  {{- $filteredPorts := dict -}}
  {{- range $name, $port := $enabledPorts -}}
    {{- if hasKey $port "port" -}}
      {{- $_ := set $filteredPorts $name $port -}}
    {{- end -}}
  {{- end -}}

  {{- /* Determine the port that has been marked as primary */ -}}
  {{- range $name, $port := $filteredPorts -}}
    {{- if and (hasKey $port "primary") $port.primary -}}
      {{- $result = $port -}}
    {{- end -}}
  {{- end -}}

  {{- /* Return the first port (alphabetically) if none has been explicitly marked as primary */ -}}
  {{- if not $result -}}
    {{- $firstPortKey := keys $filteredPorts | sortAlpha | first -}}
    {{- if $firstPortKey -}}
      {{- $result = get $filteredPorts $firstPortKey -}}
    {{- end -}}
  {{- end -}}

  {{- $result | toYaml -}}
{{- end -}}
