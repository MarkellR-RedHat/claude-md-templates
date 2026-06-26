# CLAUDE.md - Helm Chart Project

<!-- Quick customize: Fill in the TODOs below, then delete this comment block -->
<!-- TODO: Replace "my-chart" with your actual chart name -->
<!-- TODO: Set appVersion to match the application this chart deploys -->
<!-- TODO: Set your container registry URL (e.g., quay.io/your-org) -->
<!-- TODO: Set target platforms: Kubernetes, OpenShift, or both -->
<!-- TODO: Set your chart repository URL for dependency charts -->

## Project Overview

This is a Helm chart project for packaging and deploying Kubernetes applications. The chart follows Helm best practices and is designed to work on both Kubernetes and Red Hat OpenShift clusters.

## Chart Structure

```
my-chart/
  Chart.yaml                  # Chart metadata and dependencies
  Chart.lock                  # Locked dependency versions
  values.yaml                 # Default configuration values
  values.schema.json          # JSON schema for values validation
  .helmignore                 # Files to exclude from the chart package
  templates/
    _helpers.tpl              # Template helper functions
    deployment.yaml
    service.yaml
    serviceaccount.yaml
    configmap.yaml
    secret.yaml
    hpa.yaml
    ingress.yaml
    route.yaml                # OpenShift Route (if targeting OpenShift)
    NOTES.txt                 # Post-install instructions
    tests/
      test-connection.yaml    # Helm test pod
  charts/                     # Packaged dependency charts
  ci/
    ci-values.yaml            # Values used for CI testing
    openshift-values.yaml     # Values for OpenShift testing
  tests/
    deployment_test.yaml      # helm-unittest test files
    service_test.yaml
    ingress_test.yaml
```

## Chart.yaml Conventions

```yaml
apiVersion: v2
name: my-chart
description: A Helm chart for deploying the my-app application
type: application
version: 0.1.0                # Chart version (semver, bump on chart changes)
appVersion: "1.0.0"           # Application version (quoted string)
kubeVersion: ">=1.26.0-0"     # Minimum Kubernetes version
home: https://github.com/myorg/my-chart
sources:
  - https://github.com/myorg/my-chart
maintainers:
  - name: Team Name
    email: team@example.com
annotations:
  artifacthub.io/license: Apache-2.0
```

Rules:
- `version` follows semver. Bump it on every chart change, even if `appVersion` stays the same.
- `appVersion` is a quoted string. It tracks the application version, not the chart version.
- Always set `kubeVersion` to document the minimum supported Kubernetes version.
- Use `apiVersion: v2`. Helm 2 is end-of-life.

## values.yaml Design

### Structure and naming
- Use camelCase for value keys: `replicaCount`, `serviceAccount`, `podSecurityContext`.
- Group related values under a parent key:
  ```yaml
  image:
    repository: quay.io/myorg/my-app
    tag: ""                    # Defaults to appVersion if empty
    pullPolicy: IfNotPresent

  service:
    type: ClusterIP
    port: 8080

  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 256Mi
  ```
- Comment every value explaining what it does and what valid options are.
- Provide sensible defaults. The chart should deploy successfully with default values.
- Never default `image.tag` to `latest`. Use `""` and default to `.Chart.AppVersion` in the template.

### Schema validation
Create `values.schema.json` to validate user-provided values:
```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["image", "service"],
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1,
      "description": "Number of pod replicas"
    },
    "image": {
      "type": "object",
      "required": ["repository"],
      "properties": {
        "repository": {
          "type": "string",
          "description": "Container image repository"
        },
        "tag": {
          "type": "string",
          "description": "Image tag. Defaults to appVersion if empty."
        },
        "pullPolicy": {
          "type": "string",
          "enum": ["Always", "IfNotPresent", "Never"],
          "description": "Image pull policy"
        }
      }
    }
  }
}
```

## Template Patterns

### _helpers.tpl functions
Every chart should define these standard helper functions:

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "my-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "my-chart.fullname" -}}
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
Common labels.
*/}}
{{- define "my-chart.labels" -}}
helm.sh/chart: {{ include "my-chart.chart" . }}
{{ include "my-chart.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "my-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

### Template best practices
- Always quote strings in templates: `{{ .Values.image.tag | quote }}`
- Use `toYaml` with `nindent` for multi-line values:
  ```yaml
  resources:
    {{- toYaml .Values.resources | nindent 4 }}
  ```
- Use `required` for values that must be set:
  ```yaml
  image: {{ required "image.repository is required" .Values.image.repository }}
  ```
- Use `default` for optional values with fallbacks:
  ```yaml
  tag: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
  ```
- Wrap optional resources in conditionals:
  ```yaml
  {{- if .Values.ingress.enabled }}
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  ...
  {{- end }}
  ```
- Use `with` to scope values and reduce repetition:
  ```yaml
  {{- with .Values.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  ```

### NOTES.txt
Include useful post-install instructions:
```
1. Get the application URL by running these commands:
{{- if .Values.ingress.enabled }}
  http{{ if .Values.ingress.tls }}s{{ end }}://{{ (index .Values.ingress.hosts 0).host }}
{{- else if contains "NodePort" .Values.service.type }}
  export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} -o jsonpath="{.spec.ports[0].nodePort}" services {{ include "my-chart.fullname" . }})
  echo http://$NODE_IP:$NODE_PORT
{{- else if contains "ClusterIP" .Values.service.type }}
  kubectl --namespace {{ .Release.Namespace }} port-forward svc/{{ include "my-chart.fullname" . }} {{ .Values.service.port }}:{{ .Values.service.port }}
  echo "Visit http://127.0.0.1:{{ .Values.service.port }}"
{{- end }}
```

## Testing

### helm-unittest
Write tests in `tests/` directory:
```yaml
# tests/deployment_test.yaml
suite: deployment tests
templates:
  - deployment.yaml
tests:
  - it: should set the correct replica count
    set:
      replicaCount: 3
    asserts:
      - equal:
          path: spec.replicas
          value: 3

  - it: should use the correct image
    set:
      image:
        repository: quay.io/myorg/my-app
        tag: "2.0.0"
    asserts:
      - equal:
          path: spec.template.spec.containers[0].image
          value: quay.io/myorg/my-app:2.0.0

  - it: should set resource limits
    asserts:
      - isNotNull:
          path: spec.template.spec.containers[0].resources

  - it: should match snapshot
    asserts:
      - matchSnapshot: {}
```

Install and run helm-unittest:
```bash
# Install the plugin
helm plugin install https://github.com/helm-unittest/helm-unittest

# Run tests
helm unittest my-chart/

# Run tests with output
helm unittest my-chart/ -v

# Update snapshots
helm unittest my-chart/ -u
```

### chart-testing (ct)
Use chart-testing for lint and install testing in CI:
```yaml
# ct.yaml
target-branch: main
chart-dirs:
  - charts
chart-repos:
  - bitnami=https://charts.bitnami.com/bitnami
helm-extra-args: "--timeout 600s"
```

```bash
# Lint charts
ct lint --config ct.yaml

# Lint and install (requires a running cluster)
ct lint-and-install --config ct.yaml

# Test chart upgrade path
ct lint-and-install --config ct.yaml --upgrade
```

### Helm built-in tests
Define test pods in `templates/tests/`:
```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: {{ include "my-chart.fullname" . }}-test-connection
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "my-chart.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never
```

```bash
# Run Helm tests against a release
helm test my-release
```

## OpenShift Compatibility

When targeting both Kubernetes and OpenShift:

### Routes vs Ingress
```yaml
# values.yaml
route:
  enabled: false              # Set to true for OpenShift
  host: ""
  tls:
    termination: edge

ingress:
  enabled: true               # Set to false on OpenShift if using Routes
  className: ""
  hosts:
    - host: my-app.example.com
      paths:
        - path: /
          pathType: Prefix
```

### Security Context Constraints
OpenShift enforces Security Context Constraints (SCCs). Make security contexts configurable:
```yaml
# values.yaml
podSecurityContext:
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
```

Do not hardcode `runAsUser` or `fsGroup` values. OpenShift assigns these from the namespace range.

### Image streams
For OpenShift deployments, support image stream references:
```yaml
{{- if .Values.openshift.imageStream.enabled }}
image: {{ .Values.openshift.imageStream.name }}:{{ .Values.openshift.imageStream.tag }}
{{- else }}
image: {{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}
```

## Environment-Specific Values

Maintain separate values files for each environment:
```
ci/
  ci-values.yaml              # Minimal values for CI testing
  dev-values.yaml             # Development environment
  staging-values.yaml         # Staging environment
  prod-values.yaml            # Production environment
  openshift-values.yaml       # OpenShift-specific overrides
```

```bash
# Deploy to development
helm upgrade --install my-release ./my-chart \
  -f ci/dev-values.yaml \
  --namespace dev

# Deploy to production
helm upgrade --install my-release ./my-chart \
  -f ci/prod-values.yaml \
  --namespace production
```

## Dependency Management

### Adding dependencies
```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
  - name: redis
    version: "17.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

```bash
# Download dependencies
helm dependency update my-chart/

# Verify Chart.lock is up to date
helm dependency build my-chart/
```

Always commit `Chart.lock` to ensure reproducible builds.

## Publishing

### OCI registry (recommended)
```bash
# Package the chart
helm package my-chart/

# Log in to the registry
helm registry login quay.io

# Push to an OCI registry
helm push my-chart-0.1.0.tgz oci://quay.io/myorg/charts
```

### Chart repository
```bash
# Package the chart
helm package my-chart/

# Generate or update the index
helm repo index . --url https://myorg.github.io/charts

# Push to the repository (e.g., GitHub Pages)
git add . && git commit -m "Release my-chart 0.1.0" && git push
```

## Signing and Provenance

Sign charts for supply chain security:
```bash
# Package and sign
helm package --sign --key "my-key" --keyring ~/.gnupg/secring.gpg my-chart/

# Verify a signed chart
helm verify my-chart-0.1.0.tgz
```

## Common Commands

```bash
# Lint the chart
helm lint my-chart/

# Lint with strict mode
helm lint my-chart/ --strict

# Render templates locally (no cluster needed)
helm template my-release my-chart/ --values ci/ci-values.yaml

# Render a single template
helm template my-release my-chart/ --show-only templates/deployment.yaml

# Dry-run install against a cluster
helm install my-release my-chart/ --dry-run --debug

# Install the chart
helm upgrade --install my-release my-chart/ --namespace my-namespace --create-namespace

# Run helm-unittest tests
helm unittest my-chart/

# Run chart-testing lint
ct lint --config ct.yaml

# Check for deprecated APIs
helm template my-release my-chart/ | kubeval --strict

# Package the chart
helm package my-chart/

# Update dependencies
helm dependency update my-chart/
```

## .helmignore

```
# Patterns to ignore when packaging the chart
.git
.gitignore
.DS_Store
*.swp
*.swo
ci/
tests/
README.md
LICENSE
Makefile
```

## Common Mistakes to Avoid

- Do not hardcode image tags in templates. Always pull from `values.yaml`.
- Do not use `latest` as a default image tag. Default to `.Chart.AppVersion`.
- Do not forget to bump `Chart.yaml` `version` when making chart changes.
- Do not put secrets directly in `values.yaml`. Use external secret management (Vault, Sealed Secrets, External Secrets Operator).
- Do not use `lookup` in templates without guarding it. `lookup` fails during `helm template` because there is no cluster connection.
- Do not hardcode namespaces in templates. Use `{{ .Release.Namespace }}`.
- Do not forget to add new templates to helm-unittest test files.
- Do not use em dashes in NOTES.txt or template comments. Use commas, periods, or "and" instead.

## Review Checklist

Before merging:

- [ ] `helm lint --strict` passes
- [ ] `helm template` renders without errors
- [ ] `helm unittest` tests pass
- [ ] `values.schema.json` validates all required values
- [ ] `Chart.yaml` version has been bumped
- [ ] `Chart.lock` is up to date (if using dependencies)
- [ ] Default values produce a working deployment
- [ ] Security contexts are set (non-root, read-only root filesystem, drop all capabilities)
- [ ] Resource requests and limits are defined
- [ ] NOTES.txt provides accurate post-install instructions
- [ ] OpenShift compatibility is maintained (if targeting OpenShift)
- [ ] No hardcoded namespaces, image tags, or cluster-specific values
- [ ] New values are documented with comments in `values.yaml`
