_ready_conditions = [
    {type = "Ready", status = "True"},
    {type = "Synced", status = "True"}
]

_items = [
    # One PullThroughCacheRule is rendered per rule, including providerConfigRef.kind.
    {
        apiVersion = "meta.dev.upbound.io/v1alpha1"
        kind = "CompositionTest"
        metadata.name = "pull-through-rules-render"
        spec = {
            compositionPath = "apis/ecrregistrycaches/composition.yaml"
            xrdPath = "apis/ecrregistrycaches/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "ECRRegistryCache"
                metadata.name = "platform"
                metadata.namespace = "default"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                    providerConfigRef = {
                        name = "aws-prod"
                        kind = "ProviderConfig"
                    }
                    rules = [
                        {
                            name = "ghcr"
                            ecrRepositoryPrefix = "ghcr"
                            upstreamRegistryUrl = "ghcr.io"
                            credentialArn = "arn:aws:secretsmanager:us-east-2:123456789012:secret:ecr-pullthroughcache/ghcr-AbCdEf"
                        },
                        {
                            name = "docker-hub"
                            ecrRepositoryPrefix = "docker-hub"
                            upstreamRegistryUrl = "registry-1.docker.io"
                            credentialArn = "arn:aws:secretsmanager:us-east-2:123456789012:secret:ecr-pullthroughcache/docker-hub-AbCdEf"
                        }
                    ]
                }
            }
            assertResources = [
                {
                    apiVersion = "ecr.aws.m.upbound.io/v1beta1"
                    kind = "PullThroughCacheRule"
                    metadata.name = "platform-ghcr"
                    spec.providerConfigRef = {
                        name = "aws-prod"
                        kind = "ProviderConfig"
                    }
                    spec.forProvider = {
                        region = "us-east-2"
                        ecrRepositoryPrefix = "ghcr"
                        upstreamRegistryUrl = "ghcr.io"
                        credentialArn = "arn:aws:secretsmanager:us-east-2:123456789012:secret:ecr-pullthroughcache/ghcr-AbCdEf"
                    }
                },
                {
                    apiVersion = "ecr.aws.m.upbound.io/v1beta1"
                    kind = "PullThroughCacheRule"
                    metadata.name = "platform-docker-hub"
                    spec.forProvider.ecrRepositoryPrefix = "docker-hub"
                    spec.forProvider.upstreamRegistryUrl = "registry-1.docker.io"
                    spec.forProvider.credentialArn = "arn:aws:secretsmanager:us-east-2:123456789012:secret:ecr-pullthroughcache/docker-hub-AbCdEf"
                }
            ]
        }
    },

    # No-auth upstreams render without credentialArn.
    {
        apiVersion = "meta.dev.upbound.io/v1alpha1"
        kind = "CompositionTest"
        metadata.name = "no-auth-upstreams-render"
        spec = {
            compositionPath = "apis/ecrregistrycaches/composition.yaml"
            xrdPath = "apis/ecrregistrycaches/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "ECRRegistryCache"
                metadata.name = "platform"
                metadata.namespace = "default"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                    rules = [
                        {
                            name = "ecr-public"
                            ecrRepositoryPrefix = "ecr-public"
                            upstreamRegistryUrl = "public.ecr.aws"
                        },
                        {
                            name = "kubernetes"
                            ecrRepositoryPrefix = "kubernetes"
                            upstreamRegistryUrl = "registry.k8s.io"
                        },
                        {
                            name = "quay"
                            ecrRepositoryPrefix = "quay"
                            upstreamRegistryUrl = "quay.io"
                        }
                    ]
                }
            }
            assertResources = [
                {
                    apiVersion = "ecr.aws.m.upbound.io/v1beta1"
                    kind = "PullThroughCacheRule"
                    metadata.name = "platform-ecr-public"
                    spec.forProvider.ecrRepositoryPrefix = "ecr-public"
                    spec.forProvider.upstreamRegistryUrl = "public.ecr.aws"
                },
                {
                    apiVersion = "ecr.aws.m.upbound.io/v1beta1"
                    kind = "PullThroughCacheRule"
                    metadata.name = "platform-kubernetes"
                    spec.forProvider.ecrRepositoryPrefix = "kubernetes"
                    spec.forProvider.upstreamRegistryUrl = "registry.k8s.io"
                },
                {
                    apiVersion = "ecr.aws.m.upbound.io/v1beta1"
                    kind = "PullThroughCacheRule"
                    metadata.name = "platform-quay"
                    spec.forProvider.ecrRepositoryPrefix = "quay"
                    spec.forProvider.upstreamRegistryUrl = "quay.io"
                }
            ]
        }
    },

    # Repository creation templates default to PULL_THROUGH_CACHE and the rule prefix.
    {
        apiVersion = "meta.dev.upbound.io/v1alpha1"
        kind = "CompositionTest"
        metadata.name = "repository-creation-template-defaults"
        spec = {
            compositionPath = "apis/ecrregistrycaches/composition.yaml"
            xrdPath = "apis/ecrregistrycaches/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "ECRRegistryCache"
                metadata.name = "platform"
                metadata.namespace = "default"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                    tags = {
                        team = "platform"
                    }
                    rules = [
                        {
                            name = "ghcr"
                            ecrRepositoryPrefix = "ghcr"
                            upstreamRegistryUrl = "ghcr.io"
                            credentialArn = "arn:aws:secretsmanager:us-east-2:123456789012:secret:ecr-pullthroughcache/ghcr-AbCdEf"
                            repositoryCreationTemplate = {
                                enabled = True
                                imageTagMutability = "MUTABLE"
                                resourceTags = {
                                    Upstream = "ghcr"
                                }
                            }
                        }
                    ]
                }
            }
            assertResources = [
                {
                    apiVersion = "ecr.aws.m.upbound.io/v1beta1"
                    kind = "RepositoryCreationTemplate"
                    metadata.name = "platform-ghcr"
                    spec.forProvider = {
                        region = "us-east-2"
                        prefix = "ghcr"
                        appliedFor = ["PULL_THROUGH_CACHE"]
                        imageTagMutability = "MUTABLE"
                        resourceTags = {
                            Upstream = "ghcr"
                        }
                    }
                }
            ]
        }
    },

    # Scanning disabled renders no RegistryScanningConfiguration.
    {
        apiVersion = "meta.dev.upbound.io/v1alpha1"
        kind = "CompositionTest"
        metadata.name = "scanning-disabled"
        spec = {
            compositionPath = "apis/ecrregistrycaches/composition.yaml"
            xrdPath = "apis/ecrregistrycaches/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "ECRRegistryCache"
                metadata.name = "platform"
                metadata.namespace = "default"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                    rules = [
                        {
                            name = "kubernetes"
                            ecrRepositoryPrefix = "kubernetes"
                            upstreamRegistryUrl = "registry.k8s.io"
                        }
                    ]
                }
            }
            assertResources = [
                {
                    apiVersion = "ecr.aws.m.upbound.io/v1beta1"
                    kind = "PullThroughCacheRule"
                    metadata.name = "platform-kubernetes"
                }
            ]
        }
    },

    # Enabling scanning renders ENHANCED scanning with default filters from rule prefixes.
    {
        apiVersion = "meta.dev.upbound.io/v1alpha1"
        kind = "CompositionTest"
        metadata.name = "enhanced-scanning-default-filters"
        spec = {
            compositionPath = "apis/ecrregistrycaches/composition.yaml"
            xrdPath = "apis/ecrregistrycaches/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "ECRRegistryCache"
                metadata.name = "platform"
                metadata.namespace = "default"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                    enhancedScanning = {
                        enabled = True
                        scanFrequency = "SCAN_ON_PUSH"
                    }
                    rules = [
                        {
                            name = "ghcr"
                            ecrRepositoryPrefix = "ghcr"
                            upstreamRegistryUrl = "ghcr.io"
                            credentialArn = "arn:aws:secretsmanager:us-east-2:123456789012:secret:ecr-pullthroughcache/ghcr-AbCdEf"
                        },
                        {
                            name = "docker-hub"
                            ecrRepositoryPrefix = "docker-hub"
                            upstreamRegistryUrl = "registry-1.docker.io"
                            credentialArn = "arn:aws:secretsmanager:us-east-2:123456789012:secret:ecr-pullthroughcache/docker-hub-AbCdEf"
                        }
                    ]
                }
            }
            assertResources = [
                {
                    apiVersion = "ecr.aws.m.upbound.io/v1beta1"
                    kind = "RegistryScanningConfiguration"
                    metadata.name = "platform"
                    spec.forProvider = {
                        region = "us-east-2"
                        scanType = "ENHANCED"
                        rule = [
                            {
                                scanFrequency = "SCAN_ON_PUSH"
                                repositoryFilter = [
                                    {
                                        "filter" = "ghcr/*"
                                        filterType = "WILDCARD"
                                    },
                                    {
                                        "filter" = "docker-hub/*"
                                        filterType = "WILDCARD"
                                    }
                                ]
                            }
                        ]
                    }
                }
            ]
        }
    },

    # Observed rule state produces rewrite-friendly status output.
    {
        apiVersion = "meta.dev.upbound.io/v1alpha1"
        kind = "CompositionTest"
        metadata.name = "observed-rules-status"
        spec = {
            compositionPath = "apis/ecrregistrycaches/composition.yaml"
            xrdPath = "apis/ecrregistrycaches/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "ECRRegistryCache"
                metadata.name = "platform"
                metadata.namespace = "default"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                    rules = [
                        {
                            name = "ghcr"
                            ecrRepositoryPrefix = "ghcr"
                            upstreamRegistryUrl = "ghcr.io"
                            credentialArn = "arn:aws:secretsmanager:us-east-2:123456789012:secret:ecr-pullthroughcache/ghcr-AbCdEf"
                        }
                    ]
                }
            }
            observedResources = [
                {
                    apiVersion = "ecr.aws.m.upbound.io/v1beta1"
                    kind = "PullThroughCacheRule"
                    metadata.name = "platform-ghcr"
                    metadata.annotations = {
                        "crossplane.io/composition-resource-name" = "rule-ghcr"
                        "gotemplating.fn.crossplane.io/composition-resource-name" = "rule-ghcr"
                    }
                    status.conditions = _ready_conditions
                    status.atProvider = {
                        registryId = "123456789012"
                        ecrRepositoryPrefix = "ghcr"
                        upstreamRegistryUrl = "ghcr.io"
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "ECRRegistryCache"
                    metadata.name = "platform"
                    metadata.namespace = "default"
                    status.registry = {
                        id = "123456789012"
                        host = "123456789012.dkr.ecr.us-east-2.amazonaws.com"
                    }
                    status.rules = [
                        {
                            name = "ghcr"
                            ready = True
                            ecrRepositoryPrefix = "ghcr"
                            upstreamRegistryUrl = "ghcr.io"
                            pullPrefix = "123456789012.dkr.ecr.us-east-2.amazonaws.com/ghcr"
                            createdAt = ""
                        }
                    ]
                }
            ]
        }
    }
]
items = _items
