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
      {{- $serviceAccountName = ($enabledServiceAccounts | keys | first) -}}
    {{- end -}}
  {{- else -}}
    {{- if hasKey $controllerObject.serviceAccount "identifier" -}}
      {{- $subject := (include "bjw-s.common.lib.serviceAccount.getByIdentifier" (dict "rootContext" $rootContext "id" $controllerObject.serviceAccount.identifier) | fromYaml) -}}

      {{- if not $subject }}
        {{- fail (printf "No enabled ServiceAccount found with this identifier. (controller: '%s', identifier: '%s')" $controllerObject.identifier $controllerObject.serviceAccount.identifier) -}}
      {{- end -}}

      {{- $serviceAccountName = get $subject "name" -}}
    {{- else if hasKey $controllerObject.serviceAccount "name" -}}
      {{- $serviceAccountName = $controllerObject.serviceAccount.name -}}
    {{- end -}}
  {{- end -}}
  {{- $serviceAccountName -}}
{{- end -}}
