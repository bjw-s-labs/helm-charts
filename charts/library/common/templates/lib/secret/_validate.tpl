{{/*
Validate secret from folder values
*/}}
{{- define "bjw-s.common.lib.secret.fromFolder.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $basePath := required "If you're using `secretsFromFolder` you need to specify a `basePath` key" (trimSuffix "/" .basePath) -}}
  {{- $filteredPaths := $rootContext.Files.Glob (printf "%s/**" $basePath) -}}
  {{- $folders := dict -}}

  {{- range $path, $_ := $filteredPaths -}}
    {{- $_ := set $folders (dir $path) "" -}}
  {{- end -}}
  {{- $folders = keys $folders | uniq | sortAlpha -}}

  {{- if empty $folders -}}
    {{- fail (printf "No usable files found in the folder %s" $basePath) }}
  {{- end -}}
{{- end -}}
