
// this file has the baseline default parameters
{
  components: {
    app: {
      deployment: {
        replicas: 1,
      },
      ingress: {
        rewriteTarget: '/',
        path: '/app',
      },
      service: {
        name: 'diplom-svc',
        portName: 'http',
        port: 8000,
        targetPort: 80
      },
    },
  },
}
