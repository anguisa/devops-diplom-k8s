
// this file has the param overrides for the default environment
local base = import './base.libsonnet';

base {
  components +: {
    app +: {
      deployment +: {
        replicas: 3,
        image: 'anguisa/diplom_app:1.0.0',
      },
      namespace: 'prod',
    },
  }
}
