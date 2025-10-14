{{- define "bjw-s.common.lib.filesFolders.isBinaryFile" -}}
  {{- $rootContext := .rootContext -}}
  {{- $filePath := .file -}}
  {{- $looksBinary := false -}}
  {{- $binaryExtensions := list
      "png" "jpg" "jpeg" "gif" "bmp" "tiff" "ico" "svg"
      "mp4" "mp3" "wav" "flac" "avi" "mov" "mkv"
      "pdf" "doc" "docx" "xls" "xlsx" "ppt" "pptx"
      "zip" "tar" "gz" "bz2" "7z"
  -}}
  {{- $extension := lower (trimPrefix "." (base (ext $filePath))) -}}
  {{- if has $extension $binaryExtensions -}}
    {{- $looksBinary = true -}}
  {{- end -}}

  {{- if not $looksBinary -}}
    {{- $fileContent := ($rootContext.Files.Get $filePath) -}}

    {{- $nul := printf "%c" 0 -}}
    {{- $hasNull := contains $fileContent $nul -}}
    {{- $hasCtl := regexMatch "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]" $fileContent -}}
    {{- $cannotStringify := empty (toYaml $fileContent) -}}
    {{- $looksBinary := or $hasNull $hasCtl $cannotStringify -}}
  {{- end -}}

  {{- $looksBinary -}}
{{- end -}}
