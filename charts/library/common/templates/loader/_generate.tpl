{{/*
Secondary entrypoint and primary loader for the common chart
*/}}
{{- define "bjw-s.common.loader.generate" -}}
  {{- $rootContext := $ -}}

  {{- /* Run global chart validations */ -}}
  {{- include "bjw-s.common.lib.chart.validate" $rootContext -}}

  {{- /* Build the templates */ -}}
  {{- include "bjw-s.common.render.pvcs" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.serviceAccount" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.configMaps.fromFolder" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.configMaps" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.secrets.fromFolder" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.controllers" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.services" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.ingresses" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.serviceMonitors" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.routes" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.secrets" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.networkpolicies" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.rawResources" $rootContext | nindent 0 -}}
  {{- include "bjw-s.common.render.rbac" $rootContext | nindent 0 -}}
{{- end -}}
