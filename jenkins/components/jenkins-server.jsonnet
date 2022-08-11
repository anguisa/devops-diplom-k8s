local p = import '../params.libsonnet';
local paramsCommon = p.components.jenkins;
local params = p.components.jenkins.server.deployment;

[
  {
    apiVersion: 'v1',
    kind: 'PersistentVolumeClaim',
    metadata: {
      name: 'jenkins-server-disk',
      namespace: paramsCommon.namespace,
    },
    spec: {
      accessModes: [
        'ReadWriteOnce',
      ],
      storageClassName: 'nfs',
      resources: {
        requests: {
          storage: '2Gi',
        },
      },
    },
  },
  // jenkins-admin - сервисный аккаунт, чтобы jenkins мог использовать поды в качестве агентов
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRole',
    metadata: {
      name: 'jenkins-admin',
    },
    rules: [
      {
        apiGroups: [
          '',
        ],
        resources: [
          '*',
        ],
        verbs: [
          '*',
        ],
      },
    ],
  },
  {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: {
      name: 'jenkins-admin',
      namespace: paramsCommon.namespace,
    },
  },
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRoleBinding',
    metadata: {
      name: 'jenkins-admin',
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'jenkins-admin',
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        name: 'jenkins-admin',
        namespace: paramsCommon.namespace,
      },
    ],
  },
  // jenkins-agent - сервисный аккаунт, чтобы агенты могли деплоить во все неймспейсы
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRole',
    metadata: {
      name: 'jenkins-agent',
    },
    rules: [
      {
        apiGroups: [
          'apps',
        ],
        resources: [
          'deployments',
          'pods',
          'daemonsets',
        ],
        verbs: [
          'get',
          'list',
          'watch',
          'patch',
        ],
      },
      {
        apiGroups: [
          '*',
        ],
        resources: [
          'namespaces',
        ],
        verbs: [
          'get',
          'list',
          'watch',
        ],
      },
    ],
  },
  {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: {
      name: 'jenkins-agent',
        namespace: paramsCommon.namespace,
    },
  },
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRoleBinding',
    metadata: {
      name: 'jenkins-agent',
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'jenkins-agent',
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        name: 'jenkins-agent',
        namespace: paramsCommon.namespace,
      },
    ],
  },
  // deployment jenkins сервера
  {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: 'jenkins-server',
      namespace: paramsCommon.namespace,
    },
    spec: {
      selector: {
        matchLabels: {
          app: 'jenkins-server',
        },
      },
      template: {
        metadata: {
          labels: {
            app: 'jenkins-server',
          },
        },
        spec: {
          securityContext: {
            fsGroup: 1000,
            runAsUser: 1000,
          },
          serviceAccountName: 'jenkins-admin',
          containers: [
            {
              name: 'jenkins-server',
              image: params.image,
              imagePullPolicy: 'IfNotPresent',
              replicas: params.replicas,
              env: [
                {
                  name: 'JENKINS_OPTS',
                  value: params.prefix, // префикс, который будет в url (для ингресса)
                },
              ],
              ports: [
                {
                  containerPort: params.port,
                },
              ],
              volumeMounts: [
                {
                  name: 'jenkins-server-home',
                  mountPath: '/var/jenkins_home',
                },
              ],
            },
          ],
          volumes: [
            {
              name: 'jenkins-server-home',
              persistentVolumeClaim: {
                claimName: 'jenkins-server-disk',
              },
            },
          ],
        },
      },
    },
  },
]