# e2etest-ecrregistrycache - AWS ECR Registry Cache E2E Test
# ==========================================================
# Creates one no-auth pull-through cache rule and a repository creation
# template. The actual first image pull is verified outside the KCL harness.

import file
import base64

_awsCredsRaw = file.read("secrets/aws-creds")
_awsCreds = base64.encode(_awsCredsRaw)

_testAccountId = file.read("env/AWS_ACCOUNT_ID").strip()
_testRegion = file.read("env/AWS_REGION").strip()

_test_name = "e2e-ecr-registry-cache"

_items = [
    {
        apiVersion = "meta.dev.upbound.io/v1alpha1"
        kind = "E2ETest"
        metadata.name = "ecrregistrycache-e2e"
        spec = {
            crossplane = {
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions = ["Ready"]
            skipDelete = False
            timeoutSeconds = 4500
            extraResources = [
                {
                    apiVersion = "v1"
                    kind = "Secret"
                    metadata = {
                        name = "aws-creds"
                        namespace = "default"
                    }
                    type = "Opaque"
                    data.creds = _awsCreds
                },
                {
                    apiVersion = "aws.m.upbound.io/v1beta1"
                    kind = "ProviderConfig"
                    metadata = {
                        name = "default"
                        namespace = "default"
                    }
                    spec = {
                        credentials = {
                            source = "Secret"
                            secretRef = {
                                name = "aws-creds"
                                namespace = "default"
                                key = "creds"
                            }
                        }
                    }
                }
            ]
            manifests = [
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "ECRRegistryCache"
                    metadata = {
                        name = _test_name
                        namespace = "default"
                    }
                    spec = {
                        accountId = _testAccountId
                        region = _testRegion
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        rules = [
                            {
                                name = "ecr-public"
                                ecrRepositoryPrefix = "e2e-ecr-public"
                                upstreamRegistryUrl = "public.ecr.aws"
                                repositoryCreationTemplate = {
                                    enabled = True
                                }
                            }
                        ]
                    }
                }
            ]
        }
    }
]
items = _items
