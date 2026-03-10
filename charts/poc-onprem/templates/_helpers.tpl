{{/*
Expand the name of the chart.
*/}}
{{- define "poc-onprem.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "poc-onprem.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "poc-onprem.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "poc-onprem.labels" -}}
helm.sh/chart: {{ include "poc-onprem.chart" . }}
{{ include "poc-onprem.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "poc-onprem.selectorLabels" -}}
app.kubernetes.io/name: {{ include "poc-onprem.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "poc-onprem.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "poc-onprem.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the namespace
*/}}
{{- define "poc-onprem.namespace" -}}
{{- default .Release.Namespace .Values.global.namespace }}
{{- end }}

{{/*
Create image pull policy
*/}}
{{- define "poc-onprem.imagePullPolicy" -}}
{{- default .Values.global.imagePullPolicy "IfNotPresent" }}
{{- end }}

{{/*
Create full image name with registry
*/}}
{{- define "poc-onprem.image" -}}
{{- $registry := .registry -}}
{{- $repository := .repository -}}
{{- $tag := .tag -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- end }}

{{/*
Component-specific labels for PostgreSQL Airflow
*/}}
{{- define "poc-onprem.postgresql.airflow.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: postgresql-airflow
{{- end }}

{{- define "poc-onprem.postgresql.airflow.selectorLabels" -}}
app: pg-airflow-db
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}

{{/*
Component-specific labels for PostgreSQL PDF
*/}}
{{- define "poc-onprem.postgresql.pdf.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: postgresql-pdf
{{- end }}

{{- define "poc-onprem.postgresql.pdf.selectorLabels" -}}
app: pg-typing-pdf-extractor-db
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}

{{/*
Component-specific labels for MinIO
*/}}
{{- define "poc-onprem.minio.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: minio
{{- end }}

{{- define "poc-onprem.minio.selectorLabels" -}}
app: minio
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}

{{/*
Component-specific labels for Qdrant
*/}}
{{- define "poc-onprem.qdrant.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: qdrant
{{- end }}

{{- define "poc-onprem.qdrant.selectorLabels" -}}
app: qdrant-vector-db
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}

{{/*
Component-specific labels for Ollama Embedding
*/}}
{{- define "poc-onprem.ollama.embedding.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: ollama-embedding
{{- end }}

{{- define "poc-onprem.ollama.embedding.selectorLabels" -}}
app: ollama-llm-embedding
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}

{{/*
Component-specific labels for Ollama Chat
*/}}
{{- define "poc-onprem.ollama.chat.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: ollama-chat
{{- end }}

{{- define "poc-onprem.ollama.chat.selectorLabels" -}}
app: ollama-llm-chat
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}

{{/*
Component-specific labels for Airflow API Server
*/}}
{{- define "poc-onprem.airflow.apiServer.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: airflow-api-server
{{- end }}

{{- define "poc-onprem.airflow.apiServer.selectorLabels" -}}
app: airflow-api-server
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}

{{/*
Component-specific labels for Airflow Scheduler
*/}}
{{- define "poc-onprem.airflow.scheduler.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: airflow-scheduler
{{- end }}

{{- define "poc-onprem.airflow.scheduler.selectorLabels" -}}
app: airflow-scheduler
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}

{{/*
Component-specific labels for Airflow DAG Processor
*/}}
{{- define "poc-onprem.airflow.dagProcessor.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: airflow-dag-processor
{{- end }}

{{- define "poc-onprem.airflow.dagProcessor.selectorLabels" -}}
app: airflow-dag-processor
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}

{{/*
Component-specific labels for Typing PDF Extractor Service
*/}}
{{- define "poc-onprem.services.typingPdfExtractor.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: typing-pdf-extractor-service
{{- end }}

{{- define "poc-onprem.services.typingPdfExtractor.selectorLabels" -}}
app: typing-pdf-extractor-service
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}

{{/*
Component-specific labels for Embedding Service
*/}}
{{- define "poc-onprem.services.embedding.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: embedding-service
{{- end }}

{{- define "poc-onprem.services.embedding.selectorLabels" -}}
app: embedding-service
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}

{{/*
Component-specific labels for Chat Docs Service
*/}}
{{- define "poc-onprem.services.chatDocs.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: chat-docs-service
{{- end }}

{{- define "poc-onprem.services.chatDocs.selectorLabels" -}}
app: chat-docs-service
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}

{{/*
Component-specific labels for Chat Docs UI
*/}}
{{- define "poc-onprem.services.chatDocsUi.labels" -}}
{{ include "poc-onprem.labels" . }}
app.kubernetes.io/component: chat-docs-ui
{{- end }}

{{- define "poc-onprem.services.chatDocsUi.selectorLabels" -}}
app: chat-docs-ui
{{ include "poc-onprem.selectorLabels" . }}
{{- end }}