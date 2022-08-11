local p = import '../params.libsonnet';
local paramsCommon = p.components.atlantis;
local params = p.components.atlantis.deployment;

[
  {
    apiVersion: 'apps/v1',
    kind: 'StatefulSet',
    metadata: {
      name: 'atlantis',
      namespace: paramsCommon.namespace,
    },
    spec: {
      serviceName: 'atlantis',
      replicas: params.replicas,
      updateStrategy: {
        type: 'RollingUpdate',
        rollingUpdate: {
          partition: 0,
        },
      },
      selector: {
        matchLabels: {
          app: 'atlantis',
        },
      },
      template: {
        metadata: {
          labels: {
            app: 'atlantis',
          },
        },
        spec: {
          securityContext: {
            fsGroup: 1000, // Atlantis group (1000) read/write access to volumes.
          },
          containers: [
            {
              name: 'atlantis',
              image: params.image,
              env: [
                {
                  name: 'ATLANTIS_REPO_ALLOWLIST',
                  value: params.git.repo,
                },
                {
                  name: 'ATLANTIS_GH_USER',
                  value: params.git.user,
                },
                {
                  name: 'ATLANTIS_GH_TOKEN',
                  valueFrom: {
                    secretKeyRef: {
                      name: 'atlantis-vcs',
                      key: 'token',
                    },
                  },
                },
                {
                  name: 'ATLANTIS_GH_WEBHOOK_SECRET',
                  valueFrom: {
                    secretKeyRef: {
                      name: 'atlantis-vcs',
                      key: 'webhook-secret',
                    },
                  },
                },
                {
                  name: 'ATLANTIS_DATA_DIR',
                  value: '/atlantis',
                },
                {
                  name: 'ATLANTIS_PORT',
                  value: '4141', // Kubernetes sets an ATLANTIS_PORT variable so we need to override.
                },
                {
                  name: 'ATLANTIS_REPO_CONFIG_JSON',
                  value: '{"repos":[{"id":"/.*/","allowed_overrides":["apply_requirements","workflow","delete_source_branch_on_merge"],"allow_custom_workflows":true,"delete_source_branch_on_merge":true}]}',
                },
                // provider credentials (для backend-config)
                {
                  name: 'YC_TOKEN',
                  valueFrom: {
                    secretKeyRef: {
                      name: 'atlantis-yc',
                      key: 'token',
                    },
                  },
                },
                {
                  name: 'YC_ACCESS_KEY_ID',
                  valueFrom: {
                    secretKeyRef: {
                      name: 'atlantis-yc',
                      key: 'access_key_id',
                    },
                  },
                },
                {
                  name: 'YC_SECRET_ACCESS_KEY',
                  valueFrom: {
                    secretKeyRef: {
                      name: 'atlantis-yc',
                      key: 'secret_access_key',
                    },
                  },
                },
              ],
              volumeMounts: [
                {
                  name: 'atlantis-data',
                  mountPath: '/atlantis',
                },
                {
                  name: 'atlantis-ssh-vol',
                  mountPath: '/home/atlantis/.ssh/id_rsa_ya.pub',
                  subPath: 'id_rsa_ya.pub',
                },
              ],
              ports: [
                {
                  name: 'atlantis',
                  containerPort: 4141,
                },
              ],
              resources: {
                requests: {
                  memory: '256Mi',
                  cpu: '100m',
                },
                limits: {
                  memory: '256Mi',
                  cpu: '100m',
                },
              },
              livenessProbe: {
                // We only need to check every 60s since Atlantis is not a high-throughput service.
                periodSeconds: 60,
                httpGet: {
                  path: '/healthz',
                  port: 4141,
                  scheme: 'HTTP', // If using https, change this to HTTPS
                },
              },
              readinessProbe: {
                periodSeconds: 60,
                httpGet: {
                  path: '/healthz',
                  port: 4141,
                  scheme: 'HTTP', // If using https, change this to HTTPS
                },
              },
              lifecycle: {
                postStart: {
                  exec: {
                    command: [
                      '/bin/sh',
                      '-c',
                      'echo "provider_installation {\n network_mirror {\n  url = \\"https://terraform-mirror.yandexcloud.net/\\"\n  include = [\\"registry.terraform.io/*/*\\"]\n }\n direct {\n  exclude = [\\"registry.terraform.io/*/*\\"]\n }\n}" > /home/atlantis/.terraformrc',
                    ],
                  },
                },
              },
            },
          ],
          volumes: [
            {
              name: 'atlantis-ssh-vol',
              configMap: {
                name: 'atlantis-ssh',
              },
            }
          ],
        },
      },
      volumeClaimTemplates: [
        {
          metadata: {
            name: 'atlantis-data',
          },
          spec: {
            storageClassName: 'nfs', // добавлено
            accessModes: [
              'ReadWriteOnce', // Volume should not be shared by multiple nodes.
            ],
            resources: {
              requests: {
                // The biggest thing Atlantis stores is the Git repo when it checks it out.
                // It deletes the repo after the pull request is merged.
                storage: '5Gi',
              },
            },
          },
        },
      ],
    },
  },
]