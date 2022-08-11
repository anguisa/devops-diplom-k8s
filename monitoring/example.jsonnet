local ingress(name, namespace, rules) = {
  apiVersion: 'networking.k8s.io/v1',
  kind: 'Ingress',
  metadata: {
    name: name,
    namespace: namespace,
    annotations: {
      'nginx.ingress.kubernetes.io/auth-type': 'basic',
      'nginx.ingress.kubernetes.io/auth-secret': 'basic-auth',
      'nginx.ingress.kubernetes.io/auth-realm': 'Authentication Required',
    },
  },
  spec: { rules: rules },
};

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  // (import 'kube-prometheus/addons/managed-cluster.libsonnet') +
  // (import 'kube-prometheus/addons/node-ports.libsonnet') +
  // (import 'kube-prometheus/addons/static-etcd.libsonnet') +
  // (import 'kube-prometheus/addons/custom-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/external-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/pyrra.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'monitoring',
      },
    },
    alertmanager+:: {
      networkPolicy+: {
        spec+: {
          ingress+: [{
            from: [{
              podSelector: {
                matchLabels: {
                  'app.kubernetes.io/name': 'ingress-nginx',
                },
              },
              namespaceSelector: {
                matchLabels: {
                  'kubernetes.io/metadata.name': 'ingress-nginx',
                },
              },
            }],
            ports: [{
              port: 'web',
              protocol: 'TCP',
            }],
          }],
        },
      },
    },

    prometheus+:: {
      networkPolicy+: {
        spec+: {
          ingress+: [{
            from: [{
              podSelector: {
                matchLabels: {
                  'app.kubernetes.io/name': 'ingress-nginx',
                },
              },
              namespaceSelector: {
                matchLabels: {
                  'kubernetes.io/metadata.name': 'ingress-nginx',
                },
              },
            }],
            ports: [{
              port: 'web',
              protocol: 'TCP',
            }],
          }],
        },
      },
    },

    grafana+:: {
      _config+: {
        config+: {
          sections+: {
            server: { serve_from_sub_path: true, root_url: 'http://localhost:3000/grafana' },
          },
        },
      },
      networkPolicy+: {
        spec+: {
          ingress+: [{
            from: [{
              podSelector: {
                matchLabels: {
                  'app.kubernetes.io/name': 'ingress-nginx',
                },
              },
              namespaceSelector: {
                matchLabels: {
                  'kubernetes.io/metadata.name': 'ingress-nginx',
                },
              },
            }],
            ports: [{
              port: 'http',
              protocol: 'TCP',
            }],
          }],
        },
      },
    },

    ingress+:: {
      grafana: {
        apiVersion: 'networking.k8s.io/v1',
        kind: 'Ingress',
        metadata: {
          name: 'grafana',
          namespace: $.values.common.namespace,
          // rewrite-target не нужно, т.к. в настройках графаны указан root_url
        },
        spec: {
          // ingressClassName: nginx # в kubespray ingress_nginx_class: nginx не указывали, поэтому не используем
          rules: [
            {
              http: {
                paths: [
                  {
                    path: '/grafana',
                    pathType: 'Prefix',
                    backend: {
                      service: {
                        name: 'grafana',
                        port: {
                          name: 'http',
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
    },
  };

{ [name + '-ingress']: kp.ingress[name] for name in std.objectFields(kp.ingress) }

{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// { 'setup/pyrra-slo-CustomResourceDefinition': kp.pyrra.crd } +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
// { ['pyrra-' + name]: kp.pyrra[name] for name in std.objectFields(kp.pyrra) if name != 'crd' } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) }