{{/*
Expand the name of the chart.
*/}}
{{- define "marketplace.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "marketplace.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use (Bulletproof Fallback)
*/}}
{{- define "marketplace.serviceAccountName" -}}
{{- if .Values.serviceAccount }}
  {{- if .Values.serviceAccount.create }}
    {{- default (include "marketplace.fullname" .) .Values.serviceAccount.name }}
  {{- else }}
    {{- default "default" .Values.serviceAccount.name }}
  {{- end }}
{{- else }}
  {{- "default" }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "marketplace.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "marketplace.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "marketplace.selectorLabels" -}}
app.kubernetes.io/name: {{ include "marketplace.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
