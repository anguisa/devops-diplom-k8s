local p = import '../params.libsonnet';
local paramsCommon = p.components.atlantis;
local params = p.components.atlantis.service;

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
          name: 'atlantis',
          port: params.port,
          targetPort: params.targetPort,
        },
      ],
      selector: {
        app: 'atlantis',
      },
    },
  },
]