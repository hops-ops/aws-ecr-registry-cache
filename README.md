# aws-ecr-registry-cache

ECR pull-through cache rules for platform image registries.

`ECRRegistryCache` manages Amazon ECR pull-through cache rules in one AWS
account and region. It can also create repository creation templates for the
repositories ECR creates on first pull, and it can optionally own registry-wide
enhanced scanning through Amazon Inspector.

This XR does not rewrite image references by itself. Consumers still pull from
the private ECR registry URI, for example:

```text
123456789012.dkr.ecr.us-east-2.amazonaws.com/ghcr/hops-ops/aws-auto-eks-cluster:v0.11.0
```

## Getting Started

Create no-auth cache rules for public upstreams:

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: ECRRegistryCache
metadata:
  name: platform
  namespace: default
spec:
  accountId: "123456789012"
  region: us-east-2
  rules:
    - name: ecr-public
      ecrRepositoryPrefix: ecr-public
      upstreamRegistryUrl: public.ecr.aws
      repositoryCreationTemplate:
        enabled: true
    - name: kubernetes
      ecrRepositoryPrefix: kubernetes
      upstreamRegistryUrl: registry.k8s.io
      repositoryCreationTemplate:
        enabled: true
```

The first pull creates the cached repository:

```bash
docker pull 123456789012.dkr.ecr.us-east-2.amazonaws.com/ecr-public/docker/library/busybox:latest
```

## Growing

Authenticated upstreams such as Docker Hub and GHCR require existing AWS
Secrets Manager secrets. AWS requires those secret names to start with
`ecr-pullthroughcache/`, and the secret must live in the same account and
region as the rule.

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: ECRRegistryCache
metadata:
  name: platform
  namespace: default
spec:
  accountId: "123456789012"
  region: us-east-2
  rules:
    - name: docker-hub
      ecrRepositoryPrefix: docker-hub
      upstreamRegistryUrl: registry-1.docker.io
      credentialArn: arn:aws:secretsmanager:us-east-2:123456789012:secret:ecr-pullthroughcache/docker-hub-AbCdEf
      repositoryCreationTemplate:
        enabled: true
        imageTagMutability: MUTABLE
    - name: ghcr
      ecrRepositoryPrefix: ghcr
      upstreamRegistryUrl: ghcr.io
      credentialArn: arn:aws:secretsmanager:us-east-2:123456789012:secret:ecr-pullthroughcache/ghcr-AbCdEf
      repositoryCreationTemplate:
        enabled: true
        imageTagMutability: MUTABLE
```

Do not make pull-through cache repositories immutable by default. AWS refreshes
cached tags over time, and immutable tags can prevent ECR from updating a
repository when the upstream reuses a tag.

Repository creation template `resourceTags` are not inherited from top-level
`spec.tags`. Set them explicitly only after verifying first-pull repository
creation can tag repositories in the target account; otherwise ECR can fail to
auto-create the cache repository.

## Enterprise Scale

Enhanced scanning is registry-wide and disabled by default because it makes
this XR the owner of ECR scanning configuration for the account and region and
can create Amazon Inspector cost.

```yaml
spec:
  enhancedScanning:
    enabled: true
    scanFrequency: CONTINUOUS_SCAN
  rules:
    - name: ghcr
      ecrRepositoryPrefix: ghcr
      upstreamRegistryUrl: ghcr.io
      credentialArn: arn:aws:secretsmanager:us-east-2:123456789012:secret:ecr-pullthroughcache/ghcr-AbCdEf
```

When `repositoryFilters` is omitted, the composition creates one `WILDCARD`
filter per rule prefix, such as `ghcr/*`. Operators can set explicit filters
when another owner already manages part of registry scanning.

## Crossplane ImageConfig

Crossplane package pulls need `ImageConfig` objects in the control plane that
consumes packages:

```yaml
apiVersion: pkg.crossplane.io/v1beta1
kind: ImageConfig
metadata:
  name: ecr-ghcr-rewrite
spec:
  matchImages:
    - type: Prefix
      prefix: ghcr.io
  rewriteImage:
    prefix: 123456789012.dkr.ecr.us-east-2.amazonaws.com/ghcr
  registry:
    authentication:
      pullSecretRef:
        name: ecr-registry-credentials
```

`xpkg.crossplane.io` is not a supported ECR pull-through cache upstream in this
XR. Crossplane dependency packages from `xpkg.crossplane.io` need to stay
outside this cache path, be republished to a supported upstream such as GHCR,
or be mirrored into ECR by a separate mechanism.

## Current Hops Registry Audit

The local and `pat-local` clusters currently pull from these registry families:

| Registry family | Examples observed | ECR pull-through support |
|---|---|---|
| Docker Hub | `docker.io/istio/*`, `docker.io/grafana/*`, `postgres`, `redis`, `busybox`, `nats`, `listmonk/listmonk` | Supported through `registry-1.docker.io`; requires Secrets Manager credentials. |
| GHCR | `ghcr.io/hops-ops/*`, `ghcr.io/fluxcd/*`, `ghcr.io/external-secrets/*`, `ghcr.io/cloudnative-pg/*` | Supported through `ghcr.io`; requires Secrets Manager credentials. |
| ECR Public | `public.ecr.aws/eks/aws-load-balancer-controller`, `public.ecr.aws/docker/library/node` | Supported through `public.ecr.aws`; no auth required. |
| Kubernetes registry | `registry.k8s.io/nginx-slim`, `registry.k8s.io/external-dns/*`, `registry.k8s.io/metrics-server/*` | Supported through `registry.k8s.io`; no auth required. |
| Quay | `quay.io/argoproj/argocd`, `quay.io/jetstack/*`, `quay.io/prometheus/*`, `quay.io/kubescape/*` | Supported through `quay.io`; no auth required. |
| Crossplane package registries | `xpkg.crossplane.io/crossplane-contrib/*`, `xpkg.upbound.io/wildbitca/*` | Not supported by ECR pull-through cache. Needs republish, mirror, or direct pull. |
| Google registries | `gcr.io/knative-releases/*`, `mirror.gcr.io/*`, `us-docker.pkg.dev/fairwinds-ops/*` | Not supported by ECR pull-through cache. Needs mirror or direct pull. |
| Other registries | `reg.kyverno.io/kyverno/*` | Not supported by ECR pull-through cache. Needs mirror or direct pull. |

## Import Existing

For existing pull-through cache rules, set `managementPolicies` to observe and
update without delete until the adoption is verified:

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: ECRRegistryCache
metadata:
  name: existing-platform
  namespace: default
spec:
  accountId: "123456789012"
  region: us-east-2
  managementPolicies:
    - Create
    - Observe
    - Update
    - LateInitialize
  rules:
    - name: ghcr
      ecrRepositoryPrefix: ghcr
      upstreamRegistryUrl: ghcr.io
      credentialArn: arn:aws:secretsmanager:us-east-2:123456789012:secret:ecr-pullthroughcache/ghcr-AbCdEf
```

## Status

```yaml
status:
  ready: true
  registry:
    id: "123456789012"
    host: 123456789012.dkr.ecr.us-east-2.amazonaws.com
  scanning:
    enabled: false
    scanType: ""
  rules:
    - name: ghcr
      ready: true
      ecrRepositoryPrefix: ghcr
      upstreamRegistryUrl: ghcr.io
      pullPrefix: 123456789012.dkr.ecr.us-east-2.amazonaws.com/ghcr
```

## Development

```bash
make render         # Render all examples
make validate       # Validate rendered output against schemas
make test           # Run KCL composition tests
make e2e            # Run E2E tests (requires AWS credentials)
```

For local control plane iteration:

```bash
hops config install --path xrs/aws/ecr-registry-cache --context colima
kubectl --context colima apply -f local/ecrregistrycache.yaml
```

## References

- AWS ECR pull-through cache: https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache.html
- AWS ECR repository creation templates: https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-creation-templates.html
- Crossplane ImageConfig: https://docs.crossplane.io/latest/packages/image-configs/

## License

Apache-2.0
