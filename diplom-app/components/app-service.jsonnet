local p = import '../params.libsonnet';
local paramsCommon = p.components.app;
local params = p.components.app.service;

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
      clusterIP: 'None',
      ports: [
        {
          port: params.port,
          protocol: 'TCP',
          targetPort: params.targetPort,
          name: params.portName,
        },
      ],
      selector: {
        app: 'diplom',
      },
    },
  },
]