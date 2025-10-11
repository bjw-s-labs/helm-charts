{{/*
Renders the configMap objects required by the chart.
*/}}
{{- define "bjw-s.common.render.configMaps" -}}
  {{- $rootContext := $ -}}

  {{- /* Generate configMaps as required */ -}}
  {{- $enabledConfigMaps := (include "bjw-s.common.lib.configMap.enabledConfigmaps" (dict "rootContext" $rootContext) | fromYaml ) -}}

  {{- range $identifier := keys $enabledConfigMaps -}}
    {{- /* Generate object from the raw configMap values */ -}}
    {{- $configMapObject := (include "bjw-s.common.lib.configMap.getByIdentifier" (dict "rootContext" $rootContext "id" $identifier) | fromYaml) -}}

    {{- /* Perform validations on the configMap before rendering */ -}}
    {{- include "bjw-s.common.lib.configMap.validate" (dict "rootContext" $rootContext "object" $configMapObject "id" $identifier) -}}

      {{/* Include the configMap class */}}
      {{- include "bjw-s.common.class.configMap" (dict "rootContext" $rootContext "object" $configMapObject) | nindent 0 -}}
  {{- end -}}
{{- end -}}

{{/*
Renders configMap objects required by the chart from a folder in the repo's path.
*/}}
{{- define "bjw-s.common.render.configMaps.fromFolder" -}}
  {{- $rootContext := $ -}}

  {{- $valuesCopy := $rootContext.Values -}}
  {{- $configMapsFromFolder := $rootContext.Values.configMapsFromFolder | default dict -}}
  {{- $configMapsFromFolderEnabled := dig "enabled" false $configMapsFromFolder -}}

  {{- if $configMapsFromFolderEnabled -}}
    {{- /* Perform validations before rendering */ -}}
    {{- include "bjw-s.common.lib.configMap.fromFolder.validate" (dict "rootContext" $ "basePath" $configMapsFromFolder.basePath) -}}

    {{/* Generate a list of unique top level folders */}}
    {{- $basePath := $configMapsFromFolder.basePath -}}
    {{- $topLevelFolders := dict -}}
    {{- range $path, $_ := .Files.Glob (printf "%s/*/*" $basePath) -}}
        {{- $_ := set $topLevelFolders (dir $path) "" -}}
    {{- end -}}
    {{- $top_level_folder_list := keys $topLevelFolders | sortAlpha -}}

    {{- /* Iterate over the top level folders */ -}}
    {{- range $path := $top_level_folder_list -}}
      {{- $folder := base $path -}}
      {{- $configMapData := dict -}}
      {{- $configMapBinaryData := dict -}}
      {{- $allFilesContent := ($.Files.Glob (printf "%s/*" $path)) -}}

      {{- $configMapAnnotations := dig "configMapsOverrides" $folder "annotations" dict $configMapsFromFolder -}}
      {{- $configMapLabels := dig "configMapsOverrides" $folder "labels" dict $configMapsFromFolder -}}
      {{- $configMapForceRename := dig "configMapsOverrides" $folder "forceRename" nil $configMapsFromFolder -}}
      {{- range $file_name, $content := $allFilesContent -}}
        {{- $file := base $file_name -}}
        {{- $fileOverride := dig "configMapsOverrides" $folder "fileAttributeOverrides" $file nil $configMapsFromFolder -}}
        {{- $fileContent := $.Files.Get $file_name -}}
        {{- if not $fileOverride.exclude -}}
          {{- if $fileOverride.binary -}}
            {{- $fileContent = $fileContent | b64enc -}}
            {{- $configMapBinaryData = merge $configMapBinaryData (dict $file $fileContent) -}}
          {{- else if $fileOverride.escaped -}}
            {{- $fileContent = $fileContent | replace "{{" "{{ `{{` }}" -}}
            {{- $configMapData = merge $configMapData (dict $file $fileContent) -}}
          {{- else if $fileOverride.isEnvFile -}}
            {{- range $line := splitList "\n" $fileContent -}}
                {{- $line = trim $line -}}
                {{- if and (ne $line "") (not (hasPrefix $line "#")) -}}
                    {{- $keyValue := splitList "=" $line -}}
                    {{- $key := index $keyValue 0 | trim -}}
                    {{- $value := index $keyValue 1 | replace "\"" "" | replace "'" "" | trim -}}
                    {{- $configMapData = merge $configMapData (dict $key $value) -}}
                {{- end -}}
            {{- end -}}
          {{- else -}}
            {{- $configMapData = merge $configMapData (dict $file $fileContent) -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}

      {{- $configMapValues := dict "enabled" true "forceRename" $configMapForceRename "labels" $configMapLabels "annotations" $configMapAnnotations "data" $configMapData "binaryData" $configMapBinaryData -}}
      {{- $configMapObject := (include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $folder "values" $configMapValues) | fromYaml) -}}

      {{- /* Append it to .Values.configMaps so it can be created by "bjw-s.common.render.configMaps" and fetched by identifier */ -}}
      {{- $existingConfigMaps := (get $valuesCopy "configMaps" | default dict) -}}
      {{- $mergedConfigMaps := deepCopy $existingConfigMaps | merge (dict $folder $configMapObject) -}}

      {{- $valuesCopy := merge $valuesCopy (dict "configMaps" $mergedConfigMaps) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
