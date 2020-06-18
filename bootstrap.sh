#!/bin/bash -eu

DIR="$(dirname "$0")"
cd "$DIR"

. .env

# Same version as for the EKS
export KUBERNETES_VERSION=v1.16.10
export HELM_VERSION=v3.2.4

export KUBECTL="${DIR}/bin/kubectl"
export MINIKUBE="${DIR}/bin/minikube"
export HELM="${DIR}/bin/helm"

mkdir -p bin

if [ ! -f "${HELM}" ]; then
    curl -LO https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && \
        tar -xzvf helm-${HELM_VERSION}-linux-amd64.tar.gz && \
        mv linux-amd64/helm "${HELM}" \
        && rm -r linux-amd64/ helm-${HELM_VERSION}-linux-amd64.tar.gz
fi

if [ ! -f "${KUBECTL}" ]; then
    curl -Lo "${KUBECTL}" https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl && chmod +x "${KUBECTL}"
fi

if [ ! -f "${MINIKUBE}" ]; then
    curl -Lo "${MINIKUBE}" https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
        chmod +x "${MINIKUBE}"
fi

"${MINIKUBE}" start --kubernetes-version=${KUBERNETES_VERSION} --extra-config=controller-manager.horizontal-pod-autoscaler-downscale-stabilization=1m

"${KUBECTL}" create configmap logstash-env --from-env-file=logstash.properties -o yaml --dry-run | kubectl apply -f -
"${KUBECTL}" create configmap logstash-pipeline --from-file=pipeline/logstash-default.conf -o yaml --dry-run | kubectl apply -f -

"${KUBECTL}" create --save-config=true secret generic es-credentials --from-literal=es_username=${ES_USERNAME} --from-literal=es_password=${ES_PASSWORD} --dry-run -o yaml | kubectl apply -f -

for file in manifests/logstash/*.yaml; do
    "${KUBECTL}" apply -f "$file";
done

"${HELM}" repo update

"${HELM}" upgrade -i prometheus stable/prometheus --version 11.4.0 --values helm/prometheus.yaml
"${HELM}" upgrade -i prometheus-adapter stable/prometheus-adapter --version 2.3.1 --values helm/prometheus-adapter.yaml
"${HELM}" upgrade -i filebeat stable/filebeat --version 4.0.0 --values helm/filebeat.yaml #--post-renderer ./helm/kustomize.sh

