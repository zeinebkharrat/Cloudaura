#!/bin/bash
set -e

echo "🔧 Applying permanent fixes to playbook..."

# Fix 1: Worker Join Command
echo "📝 Fixing worker-join.yml..."
cat > roles/kubernetes/tasks/worker-join.yml << 'WORKER'
---
# Join worker nodes to the Kubernetes cluster

- name: Check if node is already part of cluster
  stat:
    path: /etc/kubernetes/kubelet.conf
  register: kubelet_conf

- name: Wait for API server to be accessible
  wait_for:
    host: "{{ hostvars[groups['k8s_masters'][0]].ansible_host }}"
    port: 6443
    timeout: 60
  when: not kubelet_conf.stat.exists

- name: Copy join command from control node
  copy:
    src: /tmp/k8s_join_command.sh
    dest: /tmp/k8s_join_command.sh
    mode: '0755'
  when: not kubelet_conf.stat.exists

- name: Join node to Kubernetes cluster
  shell: "bash /tmp/k8s_join_command.sh"
  args:
    executable: /bin/bash
  when: not kubelet_conf.stat.exists
  register: join_result

- name: Display join result
  debug:
    var: join_result.stdout_lines
  when: join_result.changed

- name: Wait for node to be registered
  wait_for:
    timeout: 30
  when: join_result.changed
WORKER

# Fix 2: Flannel Wait
echo "📝 Fixing flannel wait in master-init.yml..."
cat > /tmp/flannel-wait.yml << 'FLANNEL'

- name: Wait for Flannel namespace to exist
  become_user: ubuntu
  shell: |
    for i in {1..60}; do
      if kubectl get namespace kube-flannel &>/dev/null; then
        exit 0
      fi
      sleep 2
    done
    exit 1
  environment:
    KUBECONFIG: /home/ubuntu/.kube/config
  changed_when: false

- name: Wait for Flannel pods to be ready
  become_user: ubuntu
  shell: kubectl wait --for=condition=Ready pods --all -n kube-flannel --timeout=300s
  environment:
    KUBECONFIG: /home/ubuntu/.kube/config
  changed_when: false
  ignore_errors: yes
FLANNEL

# Backup original
cp roles/kubernetes/tasks/master-init.yml roles/kubernetes/tasks/master-init.yml.bak

# Remove old wait task and add new one
sed -i '/^- name: Wait for Flannel pods to be ready$/,/^  ignore_errors: yes$/d' roles/kubernetes/tasks/master-init.yml
sed -i '/^- name: Mark Flannel as installed$/r /tmp/flannel-wait.yml' roles/kubernetes/tasks/master-init.yml

# Fix 3: Monitoring Timeout
echo "📝 Fixing monitoring timeout..."
sed -i 's/--timeout=10m/--timeout=20m/g' roles/monitoring/tasks/deploy-prometheus.yml

# Fix 4: Add retries to monitoring
if ! grep -q "retries:" roles/monitoring/tasks/deploy-prometheus.yml; then
  sed -i '/when: not monitoring_installed/a\  retries: 2\n  delay: 60' roles/monitoring/tasks/deploy-prometheus.yml
fi

echo ""
echo "✅ All fixes applied!"
echo ""
echo "📋 Summary of changes:"
echo "  1. Fixed worker join command execution (bash shell)"
echo "  2. Fixed Flannel wait to check namespace first"
echo "  3. Increased monitoring timeout to 20 minutes"
echo "  4. Added retries to monitoring deployment"
echo ""
echo "🧪 To test, run:"
echo "  ansible-playbook -i inventory.ini site.yml"
echo ""
echo "💾 Backup created: roles/kubernetes/tasks/master-init.yml.bak"
