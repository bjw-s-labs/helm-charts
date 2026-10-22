{{/*
volumeMounts used by the container.
*/}}
{{- define "bjw-s.common.lib.container.field.volumeMounts" -}}
  {{- include "bjw-s.common.lib.container.persistenceMounts" (dict "ctx" .ctx "block" false) -}}
{{- end -}}

{{/*
volumeDevices used by the container.
*/}}
{{- define "bjw-s.common.lib.container.field.volumeDevices" -}}
  {{- include "bjw-s.common.lib.container.persistenceMounts" (dict "ctx" .ctx "block" true) -}}
{{- end -}}

{{/*
Persistence items attached to the container: volumeMounts when block is false,
volumeDevices for volumeMode Block items when block is true.
*/}}
{{- define "bjw-s.common.lib.container.persistenceMounts" -}}
  {{- $ctx := .ctx -}}
  {{- $block := .block -}}
  {{- $rootContext := $ctx.rootContext -}}
  {{- $controllerObject := $ctx.controllerObject -}}
  {{- $containerObject := $ctx.containerObject -}}

  {{- /* Default to empty dict */ -}}
  {{- $persistenceItemsToProcess := dict -}}
  {{- $persistenceItemSources := dict -}}
  {{- $enabledVolumeMounts := list -}}

  {{- /* Collect regular persistence items */ -}}
  {{- range $identifier, $persistenceValues := $rootContext.Values.persistence -}}
    {{- /* Enable persistence item by default, but allow override */ -}}
    {{- $persistenceEnabled := true -}}
    {{- if hasKey $persistenceValues "enabled" -}}
      {{- $persistenceEnabled = $persistenceValues.enabled -}}
    {{- end -}}

    {{- if $persistenceEnabled -}}
      {{- $_ := set $persistenceItemsToProcess $identifier $persistenceValues -}}
      {{- $_ := set $persistenceItemSources $identifier (dict "kind" "Persistence" "path" (printf "persistence.%s" $identifier)) -}}
    {{- end -}}
  {{- end -}}

  {{- /* Collect volumeClaimTemplates */ -}}
  {{- if not (empty (dig "statefulset" "volumeClaimTemplates" nil $controllerObject)) -}}
    {{- range $persistenceValues := $controllerObject.statefulset.volumeClaimTemplates -}}
      {{- /* Enable persistence item by default, but allow override */ -}}
      {{- $persistenceEnabled := true -}}
      {{- if hasKey $persistenceValues "enabled" -}}
        {{- $persistenceEnabled = $persistenceValues.enabled -}}
      {{- end -}}

      {{- if $persistenceEnabled -}}
        {{- $mountValues := dict -}}
        {{- if not (empty (dig "globalMounts" nil $persistenceValues)) -}}
          {{- $_ := set $mountValues "globalMounts" $persistenceValues.globalMounts -}}
        {{- end -}}
        {{- if not (empty (dig "advancedMounts" nil $persistenceValues)) -}}
          {{- $_ := set $mountValues "advancedMounts" (dict $controllerObject.identifier $persistenceValues.advancedMounts) -}}
        {{- end -}}
        {{- with $persistenceValues.volumeMode -}}
          {{- $_ := set $mountValues "volumeMode" . -}}
        {{- end -}}
        {{- $_ := set $persistenceItemsToProcess $persistenceValues.name $mountValues -}}
        {{- $_ := set $persistenceItemSources $persistenceValues.name (dict "kind" "VolumeClaimTemplate" "path" (printf "controllers.%s.statefulset.volumeClaimTemplates.%s" $controllerObject.identifier $persistenceValues.name)) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- range $identifier, $persistenceValues := $persistenceItemsToProcess -}}
    {{- $isBlock := eq "Block" ($persistenceValues.volumeMode | default "") -}}
    {{- if eq $isBlock $block -}}
    {{- $source := get $persistenceItemSources $identifier -}}
    {{- /* Set some default values */ -}}

    {{- /* Set the default mountPath to /<name_of_the_peristence_item>, or /dev/<name> for a block device */ -}}
    {{- $mountPath := (printf "/%v" $identifier) -}}
    {{- if $isBlock -}}
      {{- $mountPath = (printf "/dev/%v" $identifier) -}}
    {{- else if eq "hostPath" (default "persistentVolumeClaim" $persistenceValues.type) -}}
      {{- $mountPath = $persistenceValues.hostPath -}}
    {{- end -}}

    {{- /* Process configured mounts */ -}}
    {{- if or .globalMounts .advancedMounts -}}
      {{- $mounts := list -}}
      {{- if hasKey . "globalMounts" -}}
        {{- $mounts = .globalMounts -}}
      {{- end -}}

      {{- if hasKey . "advancedMounts" -}}
        {{- $advancedMounts := dig $controllerObject.identifier $containerObject.identifier list .advancedMounts -}}
        {{- range $advancedMounts -}}
          {{- $mounts = append $mounts . -}}
        {{- end -}}
      {{- end -}}

      {{- /* volumeDevices names must be unique within a container */ -}}
      {{- if and $isBlock (gt (len $mounts) 1) -}}
        {{- fail (printf "%s '%s': A volumeMode Block item can only be attached once per container, but container '%s' of controller '%s' has %d mounts. Keep a single mount for it under '%s'." $source.kind $identifier $containerObject.identifier $controllerObject.identifier (len $mounts) $source.path) -}}
      {{- end -}}

      {{- range $mounts -}}
        {{- $volumeMount := dict -}}
        {{- $_ := set $volumeMount "name" $identifier -}}

        {{- /* Use the specified mountPath if provided */ -}}
        {{- with .path -}}
          {{- $mountPath = (include "bjw-s.common.lib.common.renderString" (dict "value" . "rootContext" $rootContext)) -}}
        {{- end -}}

        {{- if $isBlock -}}
          {{- if or .subPath .subPathExpr .readOnly .mountPropagation -}}
            {{- fail (printf "%s '%s': subPath, subPathExpr, readOnly and mountPropagation are not supported for a volumeMode Block item. Remove them from its mounts under '%s', or set its volumeMode to Filesystem." $source.kind $identifier $source.path) -}}
          {{- end -}}
          {{- $_ := set $volumeMount "devicePath" $mountPath -}}
          {{- $enabledVolumeMounts = append $enabledVolumeMounts $volumeMount -}}
          {{- continue -}}
        {{- end -}}
        {{- $_ := set $volumeMount "mountPath" $mountPath -}}

        {{- /* Use the specified subPath if provided */ -}}
        {{- with .subPath -}}
          {{- $_ := set $volumeMount "subPath" (include "bjw-s.common.lib.common.renderString" (dict "value" . "rootContext" $rootContext)) -}}
        {{- end -}}

        {{- /* Use the specified subPathExpr if provided */ -}}
        {{- with .subPathExpr -}}
          {{- $_ := set $volumeMount "subPathExpr" . -}}
        {{- end -}}

        {{- /* Use the specified readOnly setting if provided */ -}}
        {{- with .readOnly -}}
          {{- $_ := set $volumeMount "readOnly" . -}}
        {{- end -}}

        {{- /* Use the specified mountPropagation setting if provided */ -}}
        {{- with .mountPropagation -}}
          {{- $_ := set $volumeMount "mountPropagation" . -}}
        {{- end -}}

        {{- $enabledVolumeMounts = append $enabledVolumeMounts $volumeMount -}}
      {{- end -}}

    {{- /* Mount to default path if no mounts are configured */ -}}
    {{- else -}}
      {{- $volumeMount := dict -}}
      {{- $_ := set $volumeMount "name" $identifier -}}
      {{- $_ := set $volumeMount (ternary "devicePath" "mountPath" $isBlock) $mountPath -}}
      {{- $enabledVolumeMounts = append $enabledVolumeMounts $volumeMount -}}
    {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- with $enabledVolumeMounts -}}
    {{- . | toYaml -}}
  {{- end -}}
{{- end -}}
