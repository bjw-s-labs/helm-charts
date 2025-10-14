{{/*
Renders the Secret objects required by the chart.
*/}}
{{- define "bjw-s.common.render.secrets" -}}
  {{- $rootContext := $ -}}

  {{- /* Generate named Secrets as required */ -}}
  {{- $enabledSecrets := (include "bjw-s.common.lib.secret.enabledSecrets" (dict "rootContext" $rootContext) | fromYaml ) -}}

  {{- range $identifier := keys $enabledSecrets -}}
    {{- /* Generate object from the raw secret values */ -}}
    {{- $secretObject := (include "bjw-s.common.lib.secret.getByIdentifier" (dict "rootContext" $rootContext "id" $identifier) | fromYaml) -}}

    {{- /* Include the Secret class */ -}}
    {{- include "bjw-s.common.class.secret" (dict "rootContext" $rootContext "object" $secretObject) | nindent 0 -}}
  {{- end -}}
{{- end -}}

{{/*
Renders Secret objects required by the chart from a folder in the repo's path.
*/}}
{{- define "bjw-s.common.render.secrets.fromFolder" -}}
  {{- $rootContext := $ -}}

  {{- $valuesCopy := $rootContext.Values -}}
  {{- $secretsFromFolder := $rootContext.Values.secretsFromFolder | default dict -}}
  {{- $secretsFromFolderEnabled := dig "enabled" false $secretsFromFolder -}}

  {{- if $secretsFromFolderEnabled -}}
    {{- /* Perform validations before rendering */ -}}
    {{- include "bjw-s.common.lib.secret.fromFolder.validate" (dict "rootContext" $ "basePath" ($secretsFromFolder.basePath | default "" )) -}}

    {{- /* Collect folder contents */ -}}
    {{- $collected := include "bjw-s.common.lib.filesFolders.collectFilesfromFolder" (
        dict
        "rootContext" $rootContext
        "basePath" $secretsFromFolder.basePath
        "fromFolder" $secretsFromFolder
        "overridesKey" "overrides"
      ) | fromYaml
    -}}

    {{- /* Iterate collected folders */ -}}
    {{- range $folder, $entry := $collected -}}
      {{- $secretValues := dict
        "enabled" true
        "forceRename" $entry.forceRename
        "labels" $entry.labels
        "annotations" $entry.annotations
        "stringData" $entry.text | default "dict"
      -}}

      {{- if empty $secretValues.stringData }}
        {{- $_ := set $secretValues "enabled" false -}}
      {{- end -}}
      {{- $secretObject := (include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $folder "values" $secretValues) | fromYaml) -}}

      {{- $existingsecrets := (get $valuesCopy "secrets" | default dict) -}}
      {{- $mergedsecrets := deepCopy $existingsecrets | merge (dict $folder $secretObject) -}}
      {{- $valuesCopy := merge $valuesCopy (dict "secrets" $mergedsecrets) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
