{{/*
Validate controller values
*/}}
{{- define "bjw-s.common.lib.controller.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $controllerValues := .object -}}

  {{- $allowedControllerTypes := list "deployment" "daemonset" "statefulset" "cronjob" "job" -}}
  {{- if not (has $controllerValues.type $allowedControllerTypes) -}}
    {{- fail (printf "Not a valid controller.type (%s)" $controllerValues.type) -}}
  {{- end -}}

  {{- $enabledContainers := include "bjw-s.common.lib.controller.enabledContainers" (dict "rootContext" $rootContext "controllerObject" $controllerValues) | fromYaml }}
  {{- /* Validate at least one container is enabled */ -}}
  {{- if not $enabledContainers -}}
    {{- fail (printf "Controller '%s': No containers are enabled. At least one container must be enabled. Check the 'enabled' field in your container definitions under 'controllers.%s.containers'." $controllerValues.identifier $controllerValues.identifier) -}}
  {{- end -}}

  {{- $enabledServiceAccounts := (include "bjw-s.common.lib.serviceAccount.enabledServiceAccounts" (dict "rootContext" $rootContext) | fromYaml ) }}
  {{- if not (has "serviceAccount" (keys $controllerValues)) -}}
    {{- if (gt (len $enabledServiceAccounts) 1) -}}
      {{- $availableSAs := list -}}
      {{- range $sa := $enabledServiceAccounts -}}
        {{- $availableSAs = append $availableSAs $sa.identifier -}}
      {{- end -}}
      {{- fail (printf "Controller '%s': serviceAccount field is required because automatic Service Account detection is not possible (found %d service accounts: %s). Specify which service account to use under 'controllers.%s.serviceAccount'." $controllerValues.identifier (len $enabledServiceAccounts) (join ", " $availableSAs) $controllerValues.identifier) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
