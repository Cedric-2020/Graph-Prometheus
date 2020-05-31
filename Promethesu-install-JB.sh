#!/bin/bash
#Dimanche 31/05/2020
#https://github.com/coreos/kube-prometheus#installing
GO111MODULE="on" go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
export PATH=$PATH:~/go/bin/
mkdir my-kube-prometheus; cd my-kube-prometheus
jb init
jb install github.com/coreos/kube-prometheus/jsonnet/kube-prometheus@release-0.4 # Creates `vendor/` & `jsonnetfile.lock.json`, and fills in `jsonnetfile.json`
jb update
go get github.com/brancz/gojsontoyaml
go get github.com/google/go-jsonnet/cmd/jsonnet
cat <<EOF >toto.jsonnet
local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/kube-prometheus-anti-affinity.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-managed-cluster.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-node-ports.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-static-etcd.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-thanos-sidecar.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-custom-metrics.libsonnet') +
  {
    _config+:: {
      namespace: 'monitoring',
    },
  };

{ ['setup/0namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor is separated so that it can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
EOF
echo <<EOF >tooto.sh
#!/usr/bin/env bash

# This script uses arg $1 (name of *.jsonnet file to use) to generate the manifests/*.yaml files.

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# Make sure to use project tooling
PATH="$(pwd)/tmp/bin:${PATH}"

# Make sure to start with a clean 'manifests' dir
rm -rf manifests
mkdir -p manifests/setup

# Calling gojsontoyaml is optional, but we would like to generate yaml, not json
jsonnet -J vendor -m manifests "${1-example.jsonnet}" | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Make sure to remove json files
find manifests -type f ! -name '*.yaml' -delete
rm -f kustomization
EOF

