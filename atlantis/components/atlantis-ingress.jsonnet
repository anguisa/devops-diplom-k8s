local p = import '../params.libsonnet';
local paramsCommon = p.components.atlantis;
local params = p.components.atlantis.ingress;
local paramsService = p.components.atlantis.service;

[
  {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      name: 'atlantis-ingress',
      annotations: {
        'nginx.ingress.kubernetes.io/rewrite-target': params.rewriteTarget,
      },
      namespace: paramsCommon.namespace,
    },
    spec: {
      // ingressClassName: nginx # в kubespray ingress_nginx_class: nginx не указывали, поэтому не используем
      rules: [
        {
          http: {
            paths: [
              {
                path: params.path,
                pathType: 'Prefix',
                backend: {
                  service: {
                    name: paramsService.name,
                    port: {
                      name: paramsService.portName,
                    },
                  },
                },
              },
            ],
          },
        },
      ],
    },
  },
]