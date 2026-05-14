{{- /*
Returns the value for serviceAccountName
*/ -}}
{{- define "bjw-s.common.lib.pod.field.serviceAccountName" -}}
  {{- $rootContext := .ctx.rootContext -}}
  {{- $controllerObject := .ctx.controllerObject -}}

  {{- $enabledServiceAccounts := (include "bjw-s.common.lib.serviceAccount.enabledServiceAccounts" (dict "rootContext" $rootContext) | fromYaml ) }}
  {{- $serviceAccountName := "default" -}}

  {{- if not (has "serviceAccount" (keys $controllerObject)) -}}
    {{- if (eq (len $enabledServiceAccounts) 1) -}}
      {{- $saIdentifier := ($enabledServiceAccounts | keys | first) -}}
      {{- $subject := (include "bjw-s.common.lib.serviceAccount.getByIdentifier" (dict "rootContext" $rootContext "id" $saIdentifier) | fromYaml) -}}
      {{- $serviceAccountName = get $subject "name" -}}
    {{- end -}}
  {{- else -}}
    {{- if hasKey $controllerObject.serviceAccount "identifier" -}}
      {{- $subject := (include "bjw-s.common.lib.serviceAccount.getByIdentifier" (dict "rootContext" $rootContext "id" $controllerObject.serviceAccount.identifier) | fromYaml) -}}

      {{- if not $subject }}
        {{- fail (printf "Controller '%s': No enabled ServiceAccount found with identifier '%s'. Ensure a ServiceAccount with this identifier exists and is enabled under 'serviceAccounts.%s'." $controllerObject.identifier $controllerObject.serviceAccount.identifier $controllerObject.serviceAccount.identifier) -}}
      {{- end -}}

      {{- $serviceAccountName = get $subject "name" -}}
    {{- else if hasKey $controllerObject.serviceAccount "name" -}}
      {{- $serviceAccountName = $controllerObject.serviceAccount.name -}}
    {{- end -}}
  {{- end -}}
  {{- $serviceAccountName -}}
{{- end -}}
