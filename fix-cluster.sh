#!/bin/bash
echo "⏳ Waiting for Flannel to be ready..."
kubectl wait --for=condition=Ready pods --all -n kube-flannel --timeout=300s 2>/dev/null || echo "Flannel namespace might not exist yet, continuing..."

echo "🔗 Getting join command..."
JOIN_CMD=$(sudo kubeadm token create --print-join-command)

echo "📝 Join command: $JOIN_CMD"

echo "👷 Joining workers..."
ssh ubuntu@k8s-worker1 "sudo $JOIN_CMD" &
ssh ubuntu@k8s-worker2 "sudo $JOIN_CMD" &
wait

echo "⏳ Waiting 30 seconds for nodes to join..."
sleep 30

echo "✅ Checking cluster status..."
kubectl get nodes

echo "📊 Deploying monitoring..."
# Attendre que tous les nœuds soient prêts
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Installer monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set global.imagePullPolicy=IfNotPresent \
  --set grafana.adminPassword=admin \
  --set grafana.service.type=NodePort \
  --set prometheus.prometheusSpec.storageSpec=null \
  --wait --timeout=15m

echo "🎉 Done!"
kubectl get nodes
kubectl get pods -A
