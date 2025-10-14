{{- define "bjw-s.common.lib.filesFolders.parseEnvFile" -}}
  {{- $content := .content -}}
  {{- $result := dict -}}

  {{- range $line := splitList "\n" $content -}}
    {{- $line = trim $line -}}
    {{- /* Skip empty lines and comments */ -}}
    {{- if and (ne $line "") (not (hasPrefix $line "#")) -}}
      {{- $keyValue := splitList "=" $line -}}
      {{- if ge (len $keyValue) 2 -}}
        {{- $key := index $keyValue 0 | trim -}}
        {{- $value := index $keyValue 1 | replace "\"" "" | replace "'" "" | trim -}}
        {{- $_ := set $result $key $value -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- $result | toYaml -}}
{{- end -}}
