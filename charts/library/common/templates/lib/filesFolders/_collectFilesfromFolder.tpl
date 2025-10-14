{{- define "bjw-s.common.lib.filesFolders.collectFilesfromFolder" -}}
  {{- $rootContext := .rootContext -}}
  {{- $basePath := trimSuffix "/" .basePath -}}
  {{- $fromFolder := .fromFolder | default dict -}}
  {{- $overridesKey := .overridesKey -}}
  {{- $encodeBinary := .encodeBinary | default true -}}

  {{- $result := dict -}}

  {{- /* Step 1: Discover all top-level folders */ -}}
  {{- $folders := dict -}}
  {{- $filteredPaths := $rootContext.Files.Glob (printf "%s/**" $basePath) -}}

  {{- range $path, $_ := $filteredPaths -}}
    {{- $_ := set $folders (dir $path) "" -}}
  {{- end -}}
  {{- $folders = keys $folders | uniq | sortAlpha -}}

  {{- /* Step 2: Process each folder */ -}}
  {{- range $folder := $folders -}}
    {{- $folderRelativeToBasePath := replace $basePath "" $folder | trimPrefix "/" -}}
    {{- $sanitizedFolderRelativeToBasePath := regexReplaceAll "\\W+" (clean $folderRelativeToBasePath) "-" -}}
    {{- if eq $sanitizedFolderRelativeToBasePath "-" -}}
     {{- $sanitizedFolderRelativeToBasePath = base $folder -}}
    {{- end -}}

    {{- $textData := dict -}}
    {{- $binaryData := dict -}}
    {{- $allFilesContent := $rootContext.Files.Glob (printf "%s/*" $folder) -}}

    {{- /* Extract folder-level overrides */ -}}
    {{- $annotations := dig $overridesKey $sanitizedFolderRelativeToBasePath "annotations" dict $fromFolder -}}
    {{- $labels := dig $overridesKey $sanitizedFolderRelativeToBasePath "labels" dict $fromFolder -}}
    {{- $forceRename := dig $overridesKey $sanitizedFolderRelativeToBasePath "forceRename" nil $fromFolder -}}

    {{- /* Step 3: Process each file in the folder */ -}}
    {{- range $file_name, $content := $allFilesContent -}}
      {{- $file := base $file_name -}}
      {{- $fileOverride := dig $overridesKey $sanitizedFolderRelativeToBasePath "fileAttributeOverrides" $file nil $fromFolder -}}
      {{- $fileContent := ($rootContext.Files.Get $file_name) -}}

      {{- /* Skip excluded files */ -}}
      {{- if not $fileOverride.exclude -}}
        {{- /* Determine binary status: explicit override wins; else auto-detect if enabled */ -}}
        {{- $explicitBinarySet := and (ne $fileOverride nil) (hasKey $fileOverride "binary") -}}
        {{- $isBinary := false -}}
        {{- if $explicitBinarySet -}}
          {{- $isBinary = $fileOverride.binary -}}
        {{- else -}}
          {{- $isBinary = eq (include "bjw-s.common.lib.filesFolders.isBinaryFile" (dict "rootContext" $rootContext "file" $file_name)) "true" -}}
        {{- end -}}

        {{- /* Process file based on type */ -}}
        {{- if $isBinary -}}
          {{- /* Binary file: base64 encode */ -}}
          {{- $fileContent = $fileContent | b64enc -}}
          {{- $binaryData = merge $binaryData (dict $file $fileContent) -}}

        {{- else if $fileOverride.escaped -}}
          {{- /* Escaped file: escape template delimiters */ -}}
          {{- $fileContent = $fileContent | replace "{{" "{{ `{{` }}" -}}
          {{- $textData = merge $textData (dict $file $fileContent) -}}

        {{- else if $fileOverride.isEnvFile -}}
          {{- /* Environment file: parse as key-value pairs */ -}}
          {{- $parsedEnv := include "bjw-s.common.lib.filesFolders.parseEnvFile" (dict "content" $fileContent) | fromYaml -}}
          {{- $textData = merge $textData $parsedEnv -}}

        {{- else -}}
          {{- /* Regular text file */ -}}
          {{- $textData = merge $textData (dict $file $fileContent) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}

    {{- /* Step 4: Store folder result */ -}}
    {{- $folderData := dict
      "text" $textData
      "binary" $binaryData
      "annotations" $annotations
      "labels" $labels
      "forceRename" $forceRename
    -}}
    {{- $_ := set $result $sanitizedFolderRelativeToBasePath $folderData -}}
  {{- end -}}

  {{- $result | toYaml -}}
{{- end -}}
