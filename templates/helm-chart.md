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
    hpa.yaml
    ingress.yaml
    networkpolicy.yaml        # Network policy templates
    poddisruptionbudget.yaml  # PDB for HA workloads
    route.yaml                # OpenShift Route (if targeting OpenShift)
    NOTES.txt                 # Post-install instructions
    tests/
      test-connection.yaml    # Helm test pod
  crds/                       # CRDs installed on helm install only
  charts/                     # Packaged dependency charts
  ci/
    ci-values.yaml            # Values used for CI testing
    openshift-values.yaml     # Values for OpenShift testing
  tests/
    deployment_test.yaml      # helm-unittest test files
    service_test.yaml
```

## Chart.yaml Conventions

```yaml
apiVersion: v2
name: my-chart
description: A Helm chart for deploying the my-app application
type: application                # or "library" for shared template charts
version: 0.1.0                   # Chart version (semver, bump on chart changes)
appVersion: "1.0.0"              # Application version (quoted string)
kubeVersion: ">=1.26.0-0"        # Minimum Kubernetes version
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
      "minimum": 1
    },
    "image": {
      "type": "object",
      "required": ["repository"],
      "properties": {
        "repository": { "type": "string" },
        "tag": { "type": "string" },
        "pullPolicy": { "type": "string", "enum": ["Always", "IfNotPresent", "Never"] }
      }
    }
  }
}
```

## Template Patterns

### _helpers.tpl standard functions
Every chart should define these helper functions:

```yaml
{{- define "my-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

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

{{- define "my-chart.labels" -}}
helm.sh/chart: {{ include "my-chart.chart" . }}
{{ include "my-chart.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "my-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

### Named templates for reuse

Define reusable blocks in `_helpers.tpl` to eliminate duplication across Deployments, StatefulSets, and Jobs:

```yaml
{{- define "my-chart.podSecurityContext" -}}
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
{{- with .Values.podSecurityContext }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{- define "my-chart.containerSecurityContext" -}}
allowPrivilegeEscalation: false
capabilities:
  drop: ["ALL"]
readOnlyRootFilesystem: true
runAsNonRoot: true
{{- with .Values.securityContext }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{- define "my-chart.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
  {{- range .Values.imagePullSecrets }}
  - name: {{ . }}
  {{- end }}
{{- end }}
{{- end }}
```

### Template composition rules

Use `include` (not `template`) so output can be piped through functions:
```yaml
# Good: include returns a string you can pipe
labels:
  {{- include "my-chart.labels" . | nindent 4 }}

# Bad: template writes directly to output, cannot be piped
labels:
  {{ template "my-chart.labels" . }}
```

### Conditional resource generation

Gate entire resource files on values. Put the conditional at the very top:
```yaml
{{- if .Values.networkPolicy.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "my-chart.fullname" . }}
spec:
  podSelector:
    matchLabels:
      {{- include "my-chart.selectorLabels" . | nindent 6 }}
  ingress:
    {{- toYaml .Values.networkPolicy.ingress | nindent 4 }}
{{- end }}
```

### Template best practices
- Always quote strings: `{{ .Values.image.tag | quote }}`
- Use `toYaml` with `nindent`: `{{- toYaml .Values.resources | nindent 4 }}`
- Use `required` for mandatory values: `{{ required "image.repository is required" .Values.image.repository }}`
- Use `default` for fallbacks: `{{ .Values.image.tag | default .Chart.AppVersion | quote }}`
- Use `with` to scope and reduce repetition:
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
{{- else if contains "ClusterIP" .Values.service.type }}
  kubectl --namespace {{ .Release.Namespace }} port-forward svc/{{ include "my-chart.fullname" . }} {{ .Values.service.port }}:{{ .Values.service.port }}
{{- end }}
```

## Security

### Secrets management

Never store secrets in `values.yaml` or templates. Use one of these patterns:

**External Secrets Operator (recommended)**
```yaml
{{- if .Values.externalSecrets.enabled }}
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "my-chart.fullname" . }}
spec:
  refreshInterval: {{ .Values.externalSecrets.refreshInterval | default "1h" }}
  secretStoreRef:
    name: {{ .Values.externalSecrets.secretStoreRef.name }}
    kind: {{ .Values.externalSecrets.secretStoreRef.kind | default "ClusterSecretStore" }}
  target:
    name: {{ include "my-chart.fullname" . }}
  data:
    {{- range .Values.externalSecrets.data }}
    - secretKey: {{ .secretKey }}
      remoteRef:
        key: {{ .remoteRef.key }}
        property: {{ .remoteRef.property }}
    {{- end }}
{{- end }}
```

**Sealed Secrets**: Store encrypted data in values; the SealedSecret controller decrypts it cluster-side.

**HashiCorp Vault via CSI**: Use a `SecretProviderClass` resource with `provider: vault`. Mount secrets as volumes or sync them to Kubernetes Secrets.

### Pod Security Standards

These settings should be the default, not opt-in:
```yaml
podSecurityContext:
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
  readOnlyRootFilesystem: true
  runAsNonRoot: true
```

Do not hardcode `runAsUser` or `fsGroup`. OpenShift assigns these from the namespace range.

### RBAC templates
```yaml
{{- if .Values.serviceAccount.create }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "my-chart.serviceAccountName" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
automountServiceAccountToken: {{ .Values.serviceAccount.automount | default false }}
{{- end }}
```

Default `automountServiceAccountToken` to `false`. Only mount the token when the pod needs API server access.

### Network policies

Include a network policy template that locks down traffic by default:
```yaml
networkPolicy:
  enabled: false
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: my-frontend
      ports:
        - port: 8080
          protocol: TCP
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - port: 53
          protocol: UDP
```

### Image pull secrets

For OpenShift, link the pull secret to the service account (`oc secrets link <sa> <secret> --for=pull`) instead of setting `imagePullSecrets` on the pod spec.

## Helm Hooks

### Hook types and ordering

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "my-chart.fullname" . }}-db-migrate
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: {{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
          command: ["./migrate", "--up"]
  backoffLimit: 3
```

**Weight ordering**: Weights sort as integers. `-10` runs before `-5` runs before `0`. Use negative weights for setup (migrations), positive for validation.

**Deletion policies**:
- `before-hook-creation`: Delete previous hook resource before running a new one. Use this for most cases.
- `hook-succeeded`: Delete after success. Good for cleanup jobs.
- `hook-failed`: Delete after failure. Rarely useful since you want to inspect failures.

**Common patterns**:
- `pre-install,pre-upgrade` weight `-5`: Database migrations
- `post-install,post-upgrade` weight `0`: Smoke tests, cache warming
- `pre-delete` weight `0`: Graceful shutdown, data backup

**Gotchas**: Hook resources are not part of the release. They do not appear in `helm get manifest`. If a hook Job fails, the release is marked failed and the pod stays around for log inspection.

## Testing

### helm-unittest
```yaml
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
  - it: should match snapshot
    asserts:
      - matchSnapshot: {}
```

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest
helm unittest my-chart/
helm unittest my-chart/ -u   # Update snapshots
```

### chart-testing (ct)
```yaml
# ct.yaml
target-branch: main
chart-dirs:
  - charts
chart-repos:
  - bitnami=https://charts.bitnami.com/bitnami
helm-extra-args: "--timeout 600s"
validate-maintainers: false
```

```bash
ct lint --config ct.yaml
ct lint-and-install --config ct.yaml
ct lint-and-install --config ct.yaml --upgrade   # Test upgrade path
```

### Helm built-in tests
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: {{ include "my-chart.fullname" . }}-test-connection
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

## Debugging

### Template rendering
```bash
helm template my-release my-chart/ --debug                              # Full debug output
helm template my-release my-chart/ --show-only templates/deployment.yaml  # Single template
helm install my-release my-chart/ --dry-run --debug                      # Validate against cluster API
```

`helm template` does not contact a cluster. It will not catch issues with `lookup`, capabilities checks, or CRD validation. Use `--dry-run` for those.

### Inspecting deployed releases
```bash
helm get manifest my-release -n my-namespace      # What Helm actually deployed
helm get values my-release -n my-namespace --all   # Computed values (defaults + overrides)
helm history my-release -n my-namespace            # Release history
```

### The helm-diff plugin

Install it. It is not optional for production workflows.
```bash
helm plugin install https://github.com/databus23/helm-diff
helm diff upgrade my-release my-chart/ -f values-override.yaml
helm diff upgrade my-release my-chart/ --suppress-secrets
```

Always run `helm diff` before `helm upgrade` in production. Blind upgrades cause outages.

### Common debug scenarios

**Template renders but pod fails to start**: Check `helm get manifest` and compare against `kubectl get <resource> -o yaml`. Look for defaulted fields that conflict.

**Nil pointer panic**: You accessed a nested value without guarding it. See Common Pitfalls.

**Values not taking effect**: Run `helm get values my-release --all`. Helm silently ignores unknown keys, so check for typos.

## OpenShift Compatibility

### Routes vs Ingress
```yaml
route:
  enabled: false         # Set to true for OpenShift
  host: ""
  tls:
    termination: edge
ingress:
  enabled: true          # Set to false on OpenShift if using Routes
```

### Security Context Constraints
OpenShift enforces SCCs. Default to the restricted-v2 profile (see Security section). Do not hardcode `runAsUser` or `fsGroup`.

### Image streams
```yaml
{{- if .Values.openshift.imageStream.enabled }}
image: {{ .Values.openshift.imageStream.name }}:{{ .Values.openshift.imageStream.tag }}
{{- else }}
image: {{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}
```

## Multi-Environment Strategies

### Values file hierarchy

Layer values files at deploy time. Files listed later override earlier ones:
```
values/
  base.yaml             # Shared defaults across all envs
  dev.yaml              # Development overrides
  staging.yaml          # Staging overrides
  prod.yaml             # Production overrides
  openshift.yaml        # Platform-specific overrides
  clusters/
    us-east-1.yaml      # Per-cluster overrides (ingress hosts, replicas, etc.)
    eu-central-1.yaml
```

```bash
helm upgrade --install my-release ./my-chart \
  -f values/base.yaml -f values/prod.yaml -f values/openshift.yaml \
  --namespace production
```

### Helmfile for multi-chart deployments

```yaml
# helmfile.yaml
environments:
  dev:
    values: [env/dev.yaml]
  prod:
    values: [env/prod.yaml]
releases:
  - name: my-app
    chart: ./charts/my-app
    values:
      - values/base.yaml
      - values/{{ .Environment.Name }}.yaml
  - name: my-app-worker
    chart: ./charts/my-app-worker
    needs: [my-app]
    values:
      - values/base.yaml
      - values/{{ .Environment.Name }}.yaml
```

```bash
helmfile -e dev apply
helmfile -e prod diff        # Always diff before applying to prod
```

### ArgoCD ApplicationSet patterns

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-app
spec:
  generators:
    - clusters:
        selector:
          matchLabels:
            env: production
  template:
    spec:
      source:
        repoURL: https://github.com/myorg/my-chart
        targetRevision: HEAD
        helm:
          valueFiles:
            - values/base.yaml
            - values/clusters/{{name}}.yaml
      destination:
        server: '{{server}}'
        namespace: my-app
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

## Dependency Management

### Adding dependencies
```yaml
dependencies:
  - name: postgresql
    version: "12.5.3"                              # Pin exact versions for production
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
```

```bash
helm dependency update my-chart/    # Pull dependencies, update Chart.lock
helm dependency build my-chart/     # Build from existing Chart.lock (use in CI)
```

Always commit `Chart.lock`. In CI, use `helm dependency build` (not `update`) to get reproducible builds.

### Subchart override patterns

Override subchart values by nesting under the dependency name:
```yaml
postgresql:
  enabled: true
  auth:
    database: myapp
```

Use `global` for values shared across parent and subcharts. Keep the global scope minimal; `global` values merge recursively across all subcharts and can cause unexpected overrides.

### Dependency version ranges

Pin dependencies tightly. Loose ranges cause surprises:
```yaml
# Bad: ">=12.0.0" pulled 12.1.0 last week and 12.5.0 today
# Better: "~12.5.0" pins to patch releases within 12.5.x
# Best: "12.5.3" pins exact version, update deliberately
```

## Library Charts

### Creating a library chart

Library charts contain only named templates, no deployable resources:
```yaml
# Chart.yaml
apiVersion: v2
name: my-library
type: library
version: 1.0.0
```

Define shared templates in `templates/_helpers.tpl`. Consuming charts add the library as a dependency and use `include` to call its templates.

### Versioning strategies
- Use semver strictly. Breaking template signature changes require a major bump.
- Consuming charts should use `~1.x.0` ranges for automatic patch fixes.
- Test library changes against all consuming charts before release. A broken library breaks every dependent chart.

## CRD and Operator Integration

### CRDs in the crds/ directory

Helm installs CRDs from `crds/` only on `helm install`, never on `helm upgrade`. This prevents accidental CRD changes from breaking existing CRs.

### CRD lifecycle management with hooks

For CRDs that need updates across upgrades, manage them as hook templates:
```yaml
{{- if .Values.crds.install }}
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: myresources.example.com
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-10"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  group: example.com
  names:
    plural: myresources
    singular: myresource
    kind: MyResource
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
{{- end }}
```

Key rules:
- Use hook weight `-10` so CRDs install before any CR instances.
- Gate with a values flag (`crds.install: true`) so cluster admins can manage CRDs separately.
- Never put CRDs in a `pre-delete` hook. Deleting a CRD deletes all its CRs.

## Performance

### Chart rendering
- Avoid deeply nested `range` loops over large value lists. Flatten the data structure instead.
- Minimize `include` calls inside loops. Capture the result in a variable before the loop:
  ```yaml
  {{- $ctx := . }}
  {{- range .Values.endpoints }}
    labels:
      {{- include "my-chart.selectorLabels" $ctx | nindent 4 }}
  {{- end }}
  ```
- Do not use `tpl` to dynamically load values files. It is fragile and hard to debug.

### Avoiding template bloat
- One template file per Kubernetes resource kind.
- Extract repeated blocks into named templates.
- Do not generate resources in a loop from values unless you have a genuine multi-instance use case.

## CI/CD Integration

### GitHub Actions for chart releases
```yaml
name: Release Charts
on:
  push:
    branches: [main]
    paths: ['charts/**']
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: azure/setup-helm@v4
      - uses: helm/chart-testing-action@v2
      - run: ct lint --config ct.yaml
      - run: |
          helm plugin install https://github.com/helm-unittest/helm-unittest
          helm unittest charts/my-chart/
      - run: |
          helm package charts/my-chart/
          helm registry login quay.io -u ${{ secrets.REGISTRY_USER }} -p ${{ secrets.REGISTRY_TOKEN }}
          helm push my-chart-*.tgz oci://quay.io/myorg/charts
```

### OCI registry integration

OCI registries are the recommended distribution method. They work with Quay, GHCR, ACR, ECR, and Harbor.
```bash
helm push my-chart-1.0.0.tgz oci://quay.io/myorg/charts
helm install my-release oci://quay.io/myorg/charts/my-chart --version 1.0.0
helm pull oci://quay.io/myorg/charts/my-chart --version 1.0.0 --untar
```

### Automated version bumping

Use a CI step to bump the patch version in `Chart.yaml` on merge. Parse the current version, increment the patch, and `sed` it back in.

## Migration Patterns

### Blue-green deployments with Helm

Use separate release names for blue and green. Deploy the new version, validate it, switch the service selector, then uninstall the old release.

### Chart version migration (breaking values changes)

1. Add the new values structure alongside the old.
2. In templates, check for the new structure first, fall back to old.
3. Emit a deprecation warning in NOTES.txt.
4. Remove the old structure in the next major chart version.

### Handling immutable field changes

Some Kubernetes fields cannot change after creation: `Deployment.spec.selector.matchLabels`, `StatefulSet.spec.volumeClaimTemplates`, `Job.spec.template`, `Service.spec.clusterIP`. Changing these in an upgrade will fail. Solutions: delete and recreate via a pre-upgrade hook, use unique Job names per release, or document manual deletion for StatefulSet VCT changes.

## Signing and Provenance

Sign charts for supply chain security with `helm package --sign`. Verify with `helm verify`.

## Common Pitfalls

### Whitespace control
The `-` in `{{-` and `-}}` trims whitespace. Use `{{-` to trim leading whitespace. Avoid `-}}` unless you specifically need to eat trailing whitespace; over-trimming collapses lines that should be separate.

### Nil pointer errors in nested values
Accessing `.Values.foo.bar.baz` panics if `foo` or `bar` is nil:
```yaml
# Bad: panics if monitoring is undefined
{{- if .Values.monitoring.enabled }}
# Good: guard each level
{{- if and .Values.monitoring .Values.monitoring.enabled }}
# Also good: use dig (Helm 3.8+)
{{- if (dig "monitoring" "enabled" false .Values) }}
```

### Release name length limits
Kubernetes names cap at 63 characters. The fullname helper truncates to 63, but appending suffixes can exceed it. If you add `-configmap` or `-migration`, truncate fullname to 52 characters first.

### helm upgrade vs install
`helm install` fails if the release exists. `helm upgrade` fails if it does not. Use `helm upgrade --install` for CI/CD. One subtlety: `--install` on upgrade does not run `pre-install`/`post-install` hooks if a previous release failed. Use `helm uninstall` first for a clean slate.

### Immutable field changes
`Deployment.spec.selector.matchLabels`, `StatefulSet.spec.volumeClaimTemplates`, `Job.spec.template`, and `Service.spec.clusterIP` are immutable. Changing them in an upgrade fails. Delete and recreate via a pre-upgrade hook, or use unique Job names per release.

### Dependency version drift
Loose ranges in `Chart.yaml` (`>=12.0.0`) cause non-reproducible builds. Commit `Chart.lock`. Use `helm dependency build` in CI (not `update`) to use locked versions. Only run `update` deliberately.

## Common Commands

```bash
# Lint
helm lint my-chart/ --strict

# Render templates locally
helm template my-release my-chart/ --values ci/ci-values.yaml
helm template my-release my-chart/ --show-only templates/deployment.yaml

# Dry-run against cluster
helm install my-release my-chart/ --dry-run --debug

# Install or upgrade
helm upgrade --install my-release my-chart/ --namespace my-ns --create-namespace

# Diff before upgrade (requires helm-diff plugin)
helm diff upgrade my-release my-chart/ -f values-override.yaml

# Inspect deployed release
helm get manifest my-release -n my-ns
helm get values my-release -n my-ns --all
helm history my-release -n my-ns

# Rollback
helm rollback my-release 3 -n my-ns

# Test
helm unittest my-chart/
ct lint --config ct.yaml
helm test my-release

# Package and publish
helm package my-chart/
helm push my-chart-0.1.0.tgz oci://quay.io/myorg/charts

# Dependencies
helm dependency update my-chart/
helm dependency build my-chart/
```

## .helmignore

```
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
.github/
.gitlab-ci.yml
```

## Common Mistakes to Avoid

- Do not hardcode image tags in templates. Always pull from `values.yaml`.
- Do not use `latest` as a default image tag. Default to `.Chart.AppVersion`.
- Do not forget to bump `Chart.yaml` `version` when making chart changes.
- Do not put secrets in `values.yaml`. Use External Secrets Operator, Sealed Secrets, or Vault.
- Do not use `lookup` without guarding it. It fails during `helm template` (no cluster connection).
- Do not hardcode namespaces. Use `{{ .Release.Namespace }}`.
- Do not use `helm install` in CI/CD. Use `helm upgrade --install`.
- Do not ignore `Chart.lock`. Commit it. Use `helm dependency build` in CI.
- Do not set `automountServiceAccountToken: true` unless the pod needs API server access.
- Do not skip `helm diff` before production upgrades.
- Do not put multiple resource kinds in a single template file unless they are tightly coupled.
- Do not use em dashes in NOTES.txt or template comments.

## Common Mistakes Claude Makes

**Accessing nested values without nil guards.** Claude writes `{{ .Values.monitoring.enabled }}` without checking if `monitoring` is defined. If the parent key is nil, the template panics. Use `{{ if and .Values.monitoring .Values.monitoring.enabled }}` or `{{ dig "monitoring" "enabled" false .Values }}`.

**Using `template` instead of `include`.** Claude uses `{{ template "name" . }}` which writes directly to output and cannot be piped through functions. Use `{{ include "name" . | nindent 4 }}` so the output can be indented and manipulated.

**Hardcoding namespaces in templates.** Claude writes `namespace: my-namespace` in template resources instead of using `{{ .Release.Namespace }}`.

**Defaulting image tag to `latest`.** Claude sets `image.tag` to `latest` in values.yaml. Default to `""` and use `.Chart.AppVersion` in the template: `{{ .Values.image.tag | default .Chart.AppVersion }}`.

**Not quoting string values in templates.** Claude renders values without quoting: `{{ .Values.image.tag }}` instead of `{{ .Values.image.tag | quote }}`. Unquoted values can cause YAML parsing errors when they look like numbers or booleans.

**Forgetting `automountServiceAccountToken: false`.** Claude creates ServiceAccount resources with the token auto-mounted. Default to `false` unless the pod needs API server access.

**Putting multiple resource kinds in one template file.** Claude combines Deployment, Service, and ConfigMap in a single template file. Use one file per resource kind unless they are tightly coupled (like a Job and its ConfigMap).

**Not bumping Chart.yaml version.** Claude modifies chart templates without incrementing the `version` field in Chart.yaml. Every chart change needs a version bump.

## Review Checklist

Before merging:

- [ ] `helm lint --strict` passes
- [ ] `helm template` renders without errors
- [ ] `helm unittest` tests pass
- [ ] `helm diff` reviewed against running environment
- [ ] `values.schema.json` validates all required values
- [ ] `Chart.yaml` version has been bumped
- [ ] `Chart.lock` is up to date (if using dependencies)
- [ ] Default values produce a working deployment
- [ ] Security contexts set (non-root, read-only fs, drop all caps)
- [ ] `automountServiceAccountToken` is false unless needed
- [ ] Network policy template present (even if disabled by default)
- [ ] Resource requests and limits defined
- [ ] NOTES.txt provides accurate post-install instructions
- [ ] OpenShift compatibility maintained (if applicable)
- [ ] No hardcoded namespaces, image tags, or cluster-specific values
- [ ] New values documented with comments in `values.yaml`
- [ ] Hooks have deletion policies and weight ordering
- [ ] Named templates used for repeated patterns
- [ ] No nil pointer risks in nested value access
