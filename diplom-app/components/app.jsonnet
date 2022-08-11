local p = import '../params.libsonnet';
local paramsCommon = p.components.app;
local params = p.components.app.deployment;

[
  {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      labels: {
        app: 'diplom',
      },
      name: 'diplom',
      namespace: paramsCommon.namespace,
    },
    spec: {
      replicas: params.replicas,
      selector: {
        matchLabels: {
          app: 'diplom',
        },
      },
      template: {
        metadata: {
          labels: {
            app: 'diplom',
          },
        },
        spec: {
          containers: [
            {
              image: params.image,
              imagePullPolicy: 'IfNotPresent',
              name: 'diplom-app',
            },
          ],
          terminationGracePeriodSeconds: 30,
        },
      },
    },
  },
]