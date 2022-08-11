local p = import '../params.libsonnet';
local paramsCommon = p.components.jenkins;
local params = p.components.jenkins.server.ingress;
local paramsService = p.components.jenkins.server.service;

[
  {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      name: 'jenkins-server-ingress',
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