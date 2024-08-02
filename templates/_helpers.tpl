{{/*
-------------------------------------------------------------------------------
Expand the name of the chart
-------------------------------------------------------------------------------
*/}}
{{- define "cognigy-marketplace.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
-------------------------------------------------------------------------------
Create a default fully qualified app name.
Truncate at 63 characters because some Kubernetes name fields are limited to
this by the DNS naming specification.
If release name contains chart name, it will be used as a full name.
-------------------------------------------------------------------------------
*/}}
{{- define "cognigy-marketplace.fullname" -}}
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
-------------------------------------------------------------------------------
Create chart name and version as used by the chart label.
Example format: cognigy-marketplace-1.22.0
-------------------------------------------------------------------------------
*/}}
{{- define "cognigy-marketplace.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
-------------------------------------------------------------------------------
Common labels for resources
-------------------------------------------------------------------------------
*/}}
{{- define "cognigy-marketplace.labels" -}}
helm.sh/chart: {{ include "cognigy-marketplace.chart" . }}
{{ include "cognigy-marketplace.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
-------------------------------------------------------------------------------
Selector labels for resources
-------------------------------------------------------------------------------
*/}}
{{- define "cognigy-marketplace.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cognigy-marketplace.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
-------------------------------------------------------------------------------
Return the proper TLS certificate 'secret' name
-------------------------------------------------------------------------------
*/}}
{{- define "tlsCertificate.secretName.render" -}}
{{- $tlsCertificateSecretName := "" -}}
{{- if (.Values.ingress.tls.enabled) -}}
  {{- if .Values.ingress.tls.existingSecret -}}
    {{- $tlsCertificateSecretName = .Values.ingress.tls.existingSecret -}}
  {{- else if and (.Values.ingress.tls.crt) (.Values.ingress.tls.key) -}}
    {{- $tlsCertificateSecretName = "cognigy-traefik" -}}
  {{- else -}}
    {{ required "A valid value for .Values.ingress.tls is required!" .Values.ingress.tls.crt }}
    {{ required "A valid value for .Values.ingress.tls is required!" .Values.ingress.tls.key }}
    {{ required "A valid value for .Values.ingress.tls is required!" .Values.ingress.tls.existingSecret }}
  {{- end -}}
{{- end -}}
{{- if (not (empty $tlsCertificateSecretName)) -}}
tls:
  - secretName: {{- printf "%s" (tpl $tlsCertificateSecretName $) | indent 1 -}}
{{- end -}}
{{- end -}}
