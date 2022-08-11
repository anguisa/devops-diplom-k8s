
// this file has the baseline default parameters
{
  components: {
    atlantis: {
      deployment: {
        image: 'ghcr.io/runatlantis/atlantis:v0.19.7',
        replicas: 1,
        git: {
          repo: 'github.com/anguisa/devops-diplom-terraform',
          user: 'anguisa'
        },
      },
      ingress: {
        rewriteTarget: '/events',
        path: '/atlantis',
      },
      service: {
        name: 'atlantis',
        portName: 'atlantis',
        port: 80,
        targetPort: 4141
      },
    },
  },
}
