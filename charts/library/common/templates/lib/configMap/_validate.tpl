{{/*
Validate configMap values
*/}}
{{- define "bjw-s.common.lib.configMap.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $configMapValues := .object -}}
  {{- $identifier := .id -}}

  {{- if and (empty (get $configMapValues "data")) (empty (get $configMapValues "binaryData")) -}}
    {{- fail (printf "No data or binaryData specified for configMap. (configMap: %s)" $configMapValues.identifier) }}
  {{- end -}}
{{- end -}}

{{/*
Validate configMap from folder values
*/}}
{{- define "bjw-s.common.lib.configMap.fromFolder.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $basePath := required "If you're using `configMapsFromFolder` you need to specify a `basePath` key" (trimSuffix "/" .basePath) -}}
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
