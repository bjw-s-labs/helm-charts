{{/*
Validate Deployment values
*/}}
{{- define "bjw-s.common.lib.deployment.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $deploymentValues := .object -}}

  {{- if and (ne $deploymentValues.strategy "Recreate") (ne $deploymentValues.strategy "RollingUpdate") -}}
    {{- fail (printf "Deployment '%s': Invalid strategy type '%s'. Valid options are 'Recreate' or 'RollingUpdate'. Specify a valid strategy under 'controllers.%s.strategy'." $deploymentValues.identifier $deploymentValues.strategy $deploymentValues.identifier) }}
  {{- end -}}
{{- end -}}
