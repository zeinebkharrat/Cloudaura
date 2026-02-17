#!/bin/bash
echo "========================================="
echo "🔍 DIAGNOSTIC COMPLET KUBERNETES"
echo "========================================="
echo ""

echo "1️⃣ NODES"
kubectl get nodes -o wide
echo ""

echo "2️⃣ ALL PODS"
kubectl get pods -A -o wide | grep -v Running | grep -v Completed || echo "✅ All pods Running"
kubectl get pods -A | grep -E "NAME|monitoring|coredns"
echo ""

echo "3️⃣ SERVICES MONITORING"
kubectl get svc -n monitoring
echo ""

echo "4️⃣ PROMETHEUS STATUS"
PROM_POD=$(kubectl get pod -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$PROM_POD" ]; then
  echo "Prometheus Pod: $PROM_POD"
  kubectl get pod -n monitoring $PROM_POD
  echo "Testing Prometheus API..."
  kubectl exec -n monitoring $PROM_POD -c prometheus -- wget -qO- http://localhost:9090/api/v1/query?query=up 2>/dev/null | head -100
else
  echo "❌ Prometheus pod not found"
fi
echo ""

echo "5️⃣ GRAFANA STATUS"
GRAFANA_POD=$(kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$GRAFANA_POD" ]; then
  echo "Grafana Pod: $GRAFANA_POD"
  kubectl get pod -n monitoring $GRAFANA_POD
  
  echo ""
  echo "Grafana Pod IP:"
  kubectl get pod -n monitoring $GRAFANA_POD -o jsonpath='{.status.podIP}'
  echo ""
  
  echo ""
  echo "Testing Grafana health..."
  kubectl exec -n monitoring $GRAFANA_POD -c grafana -- wget -qO- http://localhost:3000/api/health 2>/dev/null || echo "❌ Grafana health check failed"
  
  echo ""
  echo "Testing Prometheus from Grafana..."
  PROM_IP=$(kubectl get svc -n monitoring monitoring-kube-prometheus-prometheus -o jsonpath='{.spec.clusterIP}')
  echo "Prometheus Service IP: $PROM_IP"
  kubectl exec -n monitoring $GRAFANA_POD -c grafana -- wget -qO- http://$PROM_IP:9090/api/v1/query?query=up 2>/dev/null | head -100 || echo "❌ Cannot reach Prometheus from Grafana"
else
  echo "❌ Grafana pod not found"
fi
echo ""

echo "6️⃣ COREDNS STATUS"
kubectl get pods -n kube-system -l k8s-app=kube-dns
echo ""
echo "Testing DNS from Grafana pod..."
if [ -n "$GRAFANA_POD" ]; then
  kubectl exec -n monitoring $GRAFANA_POD -c grafana -- nslookup monitoring-kube-prometheus-prometheus.monitoring.svc.cluster.local 2>/dev/null || echo "❌ DNS resolution failed"
fi
echo ""

echo "7️⃣ DATASOURCES CONFIG"
kubectl get configmap -n monitoring -l grafana_datasource=1
echo ""

echo "8️⃣ NETWORK TEST"
echo "NodePort for Grafana: $(kubectl get svc -n monitoring monitoring-grafana -o jsonpath='{.spec.ports[0].nodePort}')"
echo ""
for node_ip in $(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'); do
  echo "Testing $node_ip:31170..."
  timeout 3 curl -s -o /dev/null -w "HTTP %{http_code}\n" http://$node_ip:31170 2>/dev/null || echo "❌ Failed"
done
echo ""

echo "========================================="
echo "📊 SUMMARY"
echo "========================================="
kubectl get pods -n monitoring -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName,IP:.status.podIP
echo ""
echo "========================================="
