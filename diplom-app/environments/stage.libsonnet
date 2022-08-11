
// this file has the param overrides for the default environment
local base = import './base.libsonnet';

base {
  components +: {
    app +: {
      deployment +: {
        replicas: 1,
        image: 'anguisa/diplom_app:latest',
      },
      namespace: 'stage',
    },
  }
}