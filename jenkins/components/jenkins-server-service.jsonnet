local p = import '../params.libsonnet';
local paramsCommon = p.components.jenkins;
local params = p.components.jenkins.server.service;

[
  {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: params.name,
      namespace: paramsCommon.namespace,
    },
    spec: {
      type: 'ClusterIP',
      ports: [
        {
          name: 'jenkins-server',
          port: params.port,
          targetPort: params.targetPort,
        },
      ],
      selector: {
        app: 'jenkins-server',
      },
    },
  },
]