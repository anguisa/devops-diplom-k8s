
// this file has the baseline default parameters
{
  components: {
    jenkins: {
      server: {
        deployment: {
          image: 'jenkins/jenkins:lts-jdk11',
          replicas: 1,
          port: 8080,
          prefix: '--prefix=/jenkins',
        },
        ingress: {
          path: '/jenkins',
        },
        service: {
          name: 'jenkins-server',
          portName: 'jenkins-server',
          port: 80,
          targetPort: 8080,
        },
      },
    },
  },
}
