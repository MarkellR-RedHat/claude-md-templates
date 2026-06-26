# CLAUDE.md - Kubernetes Operator (Operator SDK)

<!-- Quick customize: Fill in the TODOs below, then delete this comment block -->
<!-- TODO: Replace "myproject.example.com" with your CRD API group domain -->
<!-- TODO: Replace "MyResource" with your primary CRD Kind name -->
<!-- TODO: Replace "myresource" with the lowercase plural of your Kind -->
<!-- TODO: Set your operator name (e.g., myresource-operator) -->
<!-- TODO: Set your Go module path (e.g., github.com/yourorg/myresource-operator) -->
<!-- TODO: Set your operator namespace (e.g., myresource-operator-system) -->
<!-- TODO: Set your target Kubernetes version for envtest binaries -->
<!-- TODO: Set your OLM channel name if publishing to OperatorHub -->

## Project Overview

This is a Kubernetes operator built with Operator SDK and controller-runtime. It extends the Kubernetes API with Custom Resource Definitions (CRDs) and runs a control loop that drives the cluster toward the desired state declared in those custom resources.

### When to build an operator vs. a Helm chart

Build an operator when:
- The application requires dynamic, runtime decision-making (scaling, failover, backup scheduling).
- Resources need lifecycle management beyond what Kubernetes provides natively (schema migrations, certificate rotation, cluster membership).
- Day-2 operations are complex enough to encode as software rather than runbooks.
- You need to react to changes in related resources and reconcile accordingly.

Use a Helm chart when:
- The deployment is a static set of Kubernetes resources with per-environment values.
- There is no ongoing operational logic beyond native Kubernetes controllers.

Many production systems use both: an operator for application-specific logic, distributed as an OLM bundle.

## Project Structure

```
project-root/
  api/
    v1alpha1/
      myresource_types.go         # CRD type definitions (Spec, Status, markers)
      myresource_webhook.go       # Defaulting and validating webhooks
      groupversion_info.go        # SchemeBuilder and GroupVersion
      zz_generated.deepcopy.go    # Generated DeepCopy methods (do not edit)
  cmd/
    main.go                       # Manager entrypoint, scheme registration
  internal/
    controller/
      myresource_controller.go    # Reconciler implementation
      myresource_controller_test.go
      suite_test.go               # envtest suite bootstrap
  config/
    crd/
      bases/                      # Generated CRD manifests (do not edit directly)
      patches/                    # Kustomize patches (e.g., webhook caBundle)
    default/                      # Combines all config layers
    manager/                      # Operator Deployment manifest
    rbac/                         # Generated ClusterRole, Role, bindings
    samples/                      # Example CRs for users
    webhook/                      # Webhook Service, Certificate, configuration
    prometheus/                   # ServiceMonitor for metrics scraping
    scorecard/                    # OLM scorecard test config
  bundle/
    manifests/                    # OLM bundle: CSV, CRDs
    metadata/
      annotations.yaml
  hack/                           # Development and CI scripts
  Makefile                        # Build, test, deploy, bundle targets
  Containerfile
  PROJECT                         # Kubebuilder project metadata (do not delete)
```

### Key files to understand first

- `api/v1alpha1/myresource_types.go`: CRD schema. The contract with users.
- `internal/controller/myresource_controller.go`: Reconciliation loop. Operational logic lives here.
- `cmd/main.go`: Manager setup, scheme registration, controller wiring.
- `config/rbac/role.yaml`: Generated from kubebuilder markers. Fix the markers, not this file.
- `PROJECT`: Kubebuilder metadata. Do not delete or manually edit.

## API Design

### CRD type definitions

```go
type MyResourceSpec struct {
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=10
    // +kubebuilder:default=1
    Replicas int32 `json:"replicas"`

    // +kubebuilder:validation:MinLength=1
    Image string `json:"image"`

    // +optional
    Config *MyResourceConfig `json:"config,omitempty"`
}

type MyResourceStatus struct {
    Conditions         []metav1.Condition `json:"conditions,omitempty"`
    ObservedGeneration int64              `json:"observedGeneration,omitempty"`
    ReadyReplicas      int32              `json:"readyReplicas,omitempty"`
    // +kubebuilder:validation:Enum=Pending;Running;Failed;Succeeded
    Phase string `json:"phase,omitempty"`
}
```

### Root type markers

```go
// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:printcolumn:name="Phase",type="string",JSONPath=".status.phase"
// +kubebuilder:printcolumn:name="Ready",type="integer",JSONPath=".status.readyReplicas"
// +kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"
// +kubebuilder:resource:shortName=mr
type MyResource struct { ... }
```

### Spec vs Status rules

- **Spec** is the user's intent. Only the user writes to it.
- **Status** is the controller's report. Only the controller writes to it.
- Enable the status subresource (`+kubebuilder:subresource:status`) so Spec and Status updates do not conflict.
- Always track `ObservedGeneration` so users can detect whether the controller has processed their latest change.

### Multi-version APIs

When evolving from v1alpha1 to v1beta1:
- Define a "hub" version (latest stable) and "spoke" versions.
- Implement `ConvertTo()` and `ConvertFrom()` on spoke types.
- Never remove fields without a deprecation cycle.
- Use conversion webhooks so the API server stores one version but serves all.

### Validation markers reference

```go
// +kubebuilder:validation:Minimum=1
// +kubebuilder:validation:Maximum=100
// +kubebuilder:validation:Required
// +kubebuilder:validation:Enum=fast;balanced;thorough
// +kubebuilder:validation:Pattern=`^[a-z0-9]([-a-z0-9]*[a-z0-9])?$`
// +kubebuilder:default=3
```

Use webhooks for cross-field validation or complex defaulting that markers cannot express.

## Controller Patterns

### Reconciliation loop structure

```go
func (r *MyResourceReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    log := log.FromContext(ctx)

    // 1. Fetch the resource.
    var resource myprojectv1alpha1.MyResource
    if err := r.Get(ctx, req.NamespacedName, &resource); err != nil {
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }

    // 2. Handle deletion and finalizer.
    if !resource.DeletionTimestamp.IsZero() {
        return r.handleDeletion(ctx, &resource)
    }
    if err := r.ensureFinalizer(ctx, &resource); err != nil {
        return ctrl.Result{}, err
    }

    // 3. Reconcile owned resources (create or update).
    if err := r.reconcileDeployment(ctx, &resource); err != nil {
        return ctrl.Result{}, err
    }

    // 4. Update status.
    if err := r.updateStatus(ctx, &resource); err != nil {
        return ctrl.Result{}, err
    }
    return ctrl.Result{}, nil
}
```

### Idempotent reconciliation

Every reconciliation must be idempotent. Use `CreateOrUpdate` to converge owned resources:

```go
deploy := &appsv1.Deployment{ObjectMeta: metav1.ObjectMeta{Name: resource.Name, Namespace: resource.Namespace}}
op, err := controllerutil.CreateOrUpdate(ctx, r.Client, deploy, func() error {
    deploy.Spec.Replicas = &resource.Spec.Replicas
    deploy.Spec.Template.Spec.Containers = []corev1.Container{{Name: "app", Image: resource.Spec.Image}}
    return controllerutil.SetControllerReference(&resource, deploy, r.Scheme)
})
```

Do not use raw Create calls followed by "check if exists" logic. That pattern breaks under concurrent reconciliation.

### Controller watches and event filtering

```go
func (r *MyResourceReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&myprojectv1alpha1.MyResource{}).
        Owns(&appsv1.Deployment{}).
        Watches(&corev1.ConfigMap{},
            handler.EnqueueRequestsFromMapFunc(r.findResourcesForConfigMap),
            builder.WithPredicates(predicate.ResourceVersionChangedPredicate{}),
        ).
        WithEventFilter(predicate.GenerationChangedPredicate{}).
        Complete(r)
}
```

**Predicate reference:**

| Predicate | Behavior |
|---|---|
| `GenerationChangedPredicate` | Ignores status-only updates. Use on the primary resource. |
| `ResourceVersionChangedPredicate` | Filters out duplicate events. |
| `LabelChangedPredicate` | Only fires when labels change. |
| `AnnotationChangedPredicate` | Only fires when annotations change. |

### Enqueue strategies

- `EnqueueRequestForObject`: Default for `For()`. Enqueues the changed object itself.
- `EnqueueRequestForOwner`: Default for `Owns()`. Enqueues the owner.
- `EnqueueRequestsFromMapFunc`: For `Watches()`. Maps a changed object to reconcile requests.

For `EnqueueRequestsFromMapFunc`, register a field indexer so you can look up which CRs reference a given resource:
```go
mgr.GetFieldIndexer().IndexField(ctx, &myprojectv1alpha1.MyResource{},
    ".spec.configMapRef", func(obj client.Object) []string {
        return []string{obj.(*myprojectv1alpha1.MyResource).Spec.ConfigMapRef}
    })
```

## Finalizers

Use a finalizer when your operator creates resources that Kubernetes garbage collection cannot clean up (external infrastructure, cross-namespace resources, ordered cleanup). Do not add a finalizer if all owned resources have OwnerReferences.

```go
const finalizerName = "myproject.example.com/cleanup"

func (r *MyResourceReconciler) handleDeletion(ctx context.Context, resource *v1alpha1.MyResource) (ctrl.Result, error) {
    if !controllerutil.ContainsFinalizer(resource, finalizerName) {
        return ctrl.Result{}, nil
    }
    if err := r.cleanupExternalResources(ctx, resource); err != nil {
        return ctrl.Result{}, err // Requeue to retry cleanup.
    }
    controllerutil.RemoveFinalizer(resource, finalizerName)
    return ctrl.Result{}, r.Update(ctx, resource)
}
```

### Avoiding finalizer deadlocks

- Never add a finalizer to a resource your controller does not reconcile. If the controller goes away, the finalizer blocks deletion forever.
- Always requeue with backoff on cleanup failure rather than blocking indefinitely.
- During operator uninstall, the operator must run long enough to remove pending finalizers. OLM handles this during CSV cleanup.

## Status Conditions

### Setting conditions with meta.SetStatusCondition

```go
meta.SetStatusCondition(&latest.Status.Conditions, metav1.Condition{
    Type:               ConditionTypeReady,
    Status:             metav1.ConditionTrue,
    Reason:             "AllReplicasReady",
    Message:            "All replicas are running and healthy.",
    ObservedGeneration: latest.Generation,
})
```

### Condition rules

- Set `ObservedGeneration` on every condition so consumers know if it reflects the current spec.
- `Reason` is a single CamelCase word (machine-readable). `Message` is a human-readable sentence.
- Use only `metav1.ConditionTrue`, `metav1.ConditionFalse`, `metav1.ConditionUnknown`.
- The `Ready` condition aggregates all sub-conditions. Set it True only when everything is healthy.

## RBAC Generation

### Kubebuilder markers

```go
// +kubebuilder:rbac:groups=myproject.example.com,resources=myresources,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=myproject.example.com,resources=myresources/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=myproject.example.com,resources=myresources/finalizers,verbs=update
// +kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=core,resources=events,verbs=create;patch
```

Run `make manifests` to regenerate `config/rbac/role.yaml`. Always verify the output.

### Least privilege

- Grant only the verbs your controller uses. Read-only access means `get;list;watch`, not full CRUD.
- Separate `/status` and `/finalizers` subresource markers.
- Add markers for every resource type the controller touches, including Events.

| Scope | When to use |
|---|---|
| ClusterRole + ClusterRoleBinding | Watches all namespaces or manages cluster-scoped resources |
| ClusterRole + RoleBinding | Installed centrally, limited to specific namespaces |
| Role + RoleBinding | Single-namespace operator only |

## Error Handling in Controllers

### Requeue strategies

| Situation | Return value | Why |
|---|---|---|
| Reconciliation succeeded | `Result{}, nil` | Watch events trigger the next reconciliation. |
| Kubernetes API error | `Result{}, err` | Triggers rate-limited requeue with exponential backoff. |
| External dependency unavailable | `Result{RequeueAfter: 30s}, nil` | Avoids hammering the external system. |
| Waiting for another resource | `Result{RequeueAfter: 10s}, nil` | Short polling interval. |
| Permanent error (invalid spec) | `Result{}, nil` + set Degraded condition | Do not requeue. Let the user fix the spec. |

### Rate limiting

The default rate limiter uses exponential backoff (5ms to 1000s). Customize it:
```go
ctrl.NewControllerManagedBy(mgr).
    WithOptions(controller.Options{
        RateLimiter: workqueue.NewItemExponentialFailureRateLimiter(1*time.Second, 5*time.Minute),
        MaxConcurrentReconciles: 3,
    }).Complete(r)
```

Set `MaxConcurrentReconciles` above 1 only if your reconciler has no shared mutable state.

## Testing

### envtest setup

Standard suite file at `internal/controller/suite_test.go`:

```go
var _ = BeforeSuite(func() {
    testEnv = &envtest.Environment{
        CRDDirectoryPaths:     []string{filepath.Join("..", "..", "config", "crd", "bases")},
        ErrorIfCRDPathMissing: true,
    }
    cfg, err = testEnv.Start()
    Expect(err).NotTo(HaveOccurred())

    err = myprojectv1alpha1.AddToScheme(scheme.Scheme)
    Expect(err).NotTo(HaveOccurred())

    k8sManager, err := ctrl.NewManager(cfg, ctrl.Options{Scheme: scheme.Scheme})
    Expect(err).NotTo(HaveOccurred())

    err = (&MyResourceReconciler{
        Client: k8sManager.GetClient(), Scheme: k8sManager.GetScheme(),
    }).SetupWithManager(k8sManager)
    Expect(err).NotTo(HaveOccurred())

    go func() { defer GinkgoRecover(); Expect(k8sManager.Start(ctx)).To(Succeed()) }()
})
```

### Testing with the fake client

For fast unit tests without envtest:

```go
fakeClient := fake.NewClientBuilder().
    WithScheme(scheme).
    WithObjects(resource).
    WithStatusSubresource(resource).  // Required for Status().Update() to work
    Build()

reconciler := &MyResourceReconciler{Client: fakeClient, Scheme: scheme}
result, err := reconciler.Reconcile(ctx, ctrl.Request{NamespacedName: nn})
```

Critical: `WithStatusSubresource()` is required. Without it, `Status().Update()` calls silently do nothing.

### E2E tests

```bash
# Makefile targets for e2e with kind:
test-e2e-kind:
    kind create cluster --name operator-test
    make docker-build IMG=myoperator:test
    kind load docker-image myoperator:test --name operator-test
    make deploy IMG=myoperator:test
    go test ./test/e2e/ -v -timeout 20m -tags=e2e
    kind delete cluster --name operator-test
```

E2E tests should use polling (not sleep), verify the full stack (CR to status), and clean up on failure.

## OLM Packaging

### Bundle format

```
bundle/
  manifests/
    myresource-operator.clusterserviceversion.yaml
    myproject.example.com_myresources.yaml
  metadata/
    annotations.yaml
```

### CSV key fields

- `alm-examples`: Valid example CRs for every CRD (shown in OperatorHub UI).
- `installModes`: OwnNamespace, SingleNamespace, MultiNamespace, AllNamespaces.
- `replaces`/`skips`/`skipRange`: Defines the upgrade graph.

### Upgrade graphs

| Field | Behavior |
|---|---|
| `replaces` | Direct replacement. Users must go through each version. |
| `skips` | Skip specific versions in the upgrade path. |
| `skipRange` | Skip a range (e.g., `>=0.1.0 <0.3.0`). Preferred for production. |

### Bundle commands

```bash
make bundle IMG=quay.io/myorg/myresource-operator:v0.1.0
make bundle-build BUNDLE_IMG=quay.io/myorg/myresource-operator-bundle:v0.1.0
operator-sdk bundle validate ./bundle
operator-sdk scorecard ./bundle
```

Build a catalog with `opm`:
```bash
opm index add --bundles quay.io/myorg/myresource-operator-bundle:v0.1.0 \
    --tag quay.io/myorg/myresource-operator-catalog:latest
```

## Webhook Patterns

### Defaulting and validating webhooks

```go
// +kubebuilder:webhook:path=/mutate-...,mutating=true,failurePolicy=fail,sideEffects=None,...
func (r *MyResource) Default() {
    if r.Spec.Replicas == 0 { r.Spec.Replicas = 1 }
}

// +kubebuilder:webhook:path=/validate-...,mutating=false,failurePolicy=fail,sideEffects=None,...
func (r *MyResource) ValidateCreate() (admission.Warnings, error) {
    if r.Spec.Replicas > 10 {
        return nil, fmt.Errorf("replicas must not exceed 10, got %d", r.Spec.Replicas)
    }
    return nil, nil
}
```

### Certificate management

- **cert-manager (recommended)**: Uncomment cert-manager patches in `config/default/kustomization.yaml`.
- **OLM-managed**: Set `webhookdefinitions` in the CSV; OLM handles certificates.
- **Local development**: Disable webhooks with `ENABLE_WEBHOOKS=false make run`.

## Multi-tenancy

| Approach | Pros | Cons |
|---|---|---|
| Cluster-scoped (AllNamespaces) | Single instance, simpler operations | Blast radius is the entire cluster |
| Namespace-scoped (OwnNamespace) | Strong isolation per tenant | More instances to manage |

For multi-tenant clusters, configure the manager to watch specific namespaces:
```go
mgr, err := ctrl.NewManager(cfg, ctrl.Options{
    Cache: cache.Options{
        DefaultNamespaces: map[string]cache.Config{"tenant-a": {}, "tenant-b": {}},
    },
})
```

### Leader election

Always enable for production. Run 2 replicas; only the leader processes reconciliations.
```go
mgr, err := ctrl.NewManager(cfg, ctrl.Options{
    LeaderElection: true, LeaderElectionID: "myresource-operator-leader-election",
})
```

## Metrics and Observability

### Key controller-runtime metrics

| Metric | What it tells you |
|---|---|
| `controller_runtime_reconcile_total` | Reconciliations by controller and result |
| `controller_runtime_reconcile_errors_total` | Error rate. Alert if growing steadily. |
| `controller_runtime_reconcile_time_seconds` | Latency. Slow reconciliation indicates problems. |
| `workqueue_depth` | Queue backlog. Growing means the controller is falling behind. |

### Custom metrics

```go
var resourcesReconciled = prometheus.NewCounterVec(prometheus.CounterOpts{
    Name: "myresource_reconciled_total",
    Help: "Total MyResource reconciliations by result.",
}, []string{"namespace", "result"})

func init() { metrics.Registry.MustRegister(resourcesReconciled) }
```

### Alerting rules

Alert on: reconcile error rate > 0.1/s for 10m, p99 latency > 30s for 10m, workqueue depth > 100 for 5m.

## Security

- Never grant `cluster-admin`. Enumerate exact resources and verbs.
- Use separate ServiceAccounts for the operator and any jobs it creates.
- Use Red Hat UBI as base image. Run as non-root (`USER 65532:65532`).
- Set `readOnlyRootFilesystem: true`, drop all capabilities.
- Pin image digests in production, not just tags.
- Restrict network access with NetworkPolicies: allow ingress on 8443 (metrics) and 9443 (webhooks), egress on 443/6443 (API server).

## Debugging

### Running locally against a remote cluster

```bash
export KUBECONFIG=~/.kube/config
make install                           # Install CRDs
ENABLE_WEBHOOKS=false make run         # Run operator locally
kubectl apply -f config/samples/       # Create test CR in another terminal
```

This is the fastest development loop. No image build or push required.

### Log verbosity

Set `--zap-log-level=debug --zap-encoder=console` on the manager args.

### Common debug commands

```bash
kubectl logs -f deploy/myresource-operator-controller-manager -n myresource-operator-system -c manager
kubectl get events --sort-by=.metadata.creationTimestamp -w
kubectl auth can-i list pods --as=system:serviceaccount:myresource-operator-system:controller-manager
curl -s localhost:8080/metrics | grep workqueue
kubectl get validatingwebhookconfigurations -o yaml | grep caBundle  # Webhook TLS issues
```

## Common Pitfalls

### Status update conflicts

The most common controller bug. Re-fetch before updating status, or use retry:
```go
func (r *MyResourceReconciler) updateStatus(ctx context.Context, nn types.NamespacedName, phase string) error {
    return retry.RetryOnConflict(retry.DefaultRetry, func() error {
        latest := &v1alpha1.MyResource{}
        if err := r.Get(ctx, nn, latest); err != nil { return err }
        latest.Status.Phase = phase
        return r.Status().Update(ctx, latest)
    })
}
```

### Reconciliation storms

Symptoms: CPU spikes, unbounded queue growth. Causes:
- Updating resource metadata inside Reconcile creates an infinite loop. Use `GenerationChangedPredicate`.
- Updating status without the status subresource increments `metadata.generation`, triggering another reconciliation.
- Watching high-churn resources (Pods, Events) without narrow predicates.

### Other common mistakes

- **Watch cache staleness**: Informer cache is eventually consistent. Do not rely on reading back a resource immediately after writing it.
- **Missing RBAC markers**: "Forbidden" errors at runtime mean you forgot a marker. Check every resource type, including subresources.
- **CRD schema too permissive**: Always set validation markers. Unvalidated CRDs accept any JSON and produce confusing runtime errors. Use CEL validation (`+kubebuilder:validation:XValidation`) for cross-field rules.
- **Not checking DeletionTimestamp**: Check early in the reconcile loop. Do not create owned resources for a deleting parent.

## Release and Distribution

### Makefile targets

```bash
make generate         # DeepCopy methods
make manifests        # CRD and RBAC manifests
make build            # Operator binary
make docker-build IMG=quay.io/myorg/myresource-operator:v0.1.0
make docker-push  IMG=quay.io/myorg/myresource-operator:v0.1.0
make install          # CRDs into cluster
make deploy   IMG=quay.io/myorg/myresource-operator:v0.1.0
make test             # Unit and integration tests (envtest)
make bundle IMG=quay.io/myorg/myresource-operator:v0.1.0
```

### Multi-arch builds

```bash
PLATFORMS=linux/arm64,linux/amd64,linux/s390x,linux/ppc64le
docker buildx build --push --platform=$PLATFORMS --tag $IMG -f Containerfile .
```

### OperatorHub submission checklist

1. CSV has complete `description`, `icon`, `maintainers`, and `links`.
2. `alm-examples` contains valid CRs for every CRD.
3. All images use digest references, not tags.
4. `operator-sdk bundle validate` passes.
5. Scorecard tests pass.
6. Upgrade from the previous version works (test the `replaces` chain).

## Common Commands

```bash
# Scaffold
operator-sdk init --domain example.com --repo github.com/myorg/myresource-operator
operator-sdk create api --group myproject --version v1alpha1 --kind MyResource --resource --controller
operator-sdk create webhook --group myproject --version v1alpha1 --kind MyResource --defaulting --validation

# Generate and build
make generate && make manifests
make build
make docker-build docker-push IMG=quay.io/myorg/myresource-operator:v0.1.0

# Develop
make install && make run
kubectl apply -f config/samples/v1alpha1_myresource.yaml
kubectl get myresource -w

# Test
make test
make lint

# Deploy
make deploy IMG=quay.io/myorg/myresource-operator:v0.1.0
kubectl logs -f deploy/myresource-operator-controller-manager -n myresource-operator-system -c manager

# OLM
make bundle IMG=quay.io/myorg/myresource-operator:v0.1.0
operator-sdk bundle validate ./bundle
operator-sdk scorecard ./bundle

# Teardown
make undeploy && make uninstall
```

## Review Checklist

Before merging:

- [ ] `make generate` and `make manifests` run; generated files are up to date
- [ ] CRD types have validation markers on all fields
- [ ] Status subresource is enabled (`+kubebuilder:subresource:status`)
- [ ] Status conditions use `metav1.Condition` with `ObservedGeneration`
- [ ] Controller is idempotent
- [ ] Finalizer is added only when external cleanup is needed, removed on success
- [ ] RBAC markers are present for every resource the controller touches
- [ ] `config/rbac/role.yaml` has no wildcard verbs
- [ ] Owned resources have OwnerReferences via `SetControllerReference`
- [ ] Error handling uses appropriate requeue strategy
- [ ] Status update conflicts are handled (re-fetch or retry)
- [ ] `make test` passes
- [ ] `make lint` passes
- [ ] Container runs as non-root with read-only root filesystem
- [ ] `operator-sdk bundle validate` passes
- [ ] Example CRs in `config/samples/` are valid and current
- [ ] No em dashes in code comments, CRD descriptions, or documentation
