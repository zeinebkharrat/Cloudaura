#!/bin/bash
# ====================================================
# ROLE STRUCTURE VERIFICATION SCRIPT
# Validates the Ansible role structure
# ====================================================

echo "🔍 Verifying Ansible Role Structure..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check function
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 (missing)"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1/"
        return 0
    else
        echo -e "${RED}✗${NC} $1/ (missing)"
        return 1
    fi
}

total=0
passed=0

echo "📁 Main Files:"
files=(
    "inventory.ini"
    "site.yml"
    "setup-ssh.yml"
    "create-test-pods.yml"
    "ansible.cfg"
    "README.md"
)

for file in "${files[@]}"; do
    ((total++))
    check_file "$file" && ((passed++))
done

echo ""
echo "📁 Group Variables:"
files=(
    "group_vars/all.yml"
    "group_vars/k8s_masters.yml"
)

for file in "${files[@]}"; do
    ((total++))
    check_file "$file" && ((passed++))
done

echo ""
echo "📁 Common Role:"
files=(
    "roles/common/tasks/main.yml"
    "roles/common/tasks/kernel-modules.yml"
    "roles/common/tasks/sysctl.yml"
    "roles/common/tasks/install-packages.yml"
    "roles/common/tasks/setup-containerd.yml"
    "roles/common/tasks/install-k8s-components.yml"
    "roles/common/tasks/reboot.yml"
    "roles/common/handlers/main.yml"
)

for file in "${files[@]}"; do
    ((total++))
    check_file "$file" && ((passed++))
done

echo ""
echo "📁 Kubernetes Role:"
files=(
    "roles/kubernetes/tasks/main.yml"
    "roles/kubernetes/tasks/master-init.yml"
    "roles/kubernetes/tasks/worker-join.yml"
    "roles/kubernetes/templates/kubeadm-config.yaml.j2"
)

for file in "${files[@]}"; do
    ((total++))
    check_file "$file" && ((passed++))
done

echo ""
echo "📁 Monitoring Role:"
files=(
    "roles/monitoring/tasks/main.yml"
    "roles/monitoring/tasks/install-helm.yml"
    "roles/monitoring/tasks/deploy-prometheus.yml"
    "roles/monitoring/tasks/configure-alertmanager.yml"
    "roles/monitoring/tasks/deploy-alerts.yml"
    "roles/monitoring/tasks/display-info.yml"
    "roles/monitoring/files/alertmanager-values.yaml"
    "roles/monitoring/files/high-cpu-alert.yaml"
    "roles/monitoring/defaults/main.yml"
)

for file in "${files[@]}"; do
    ((total++))
    check_file "$file" && ((passed++))
done

echo ""
echo "========================================"
if [ $passed -eq $total ]; then
    echo -e "${GREEN}✓ All files present! ($passed/$total)${NC}"
    echo "✅ Role structure is complete!"
else
    echo -e "${YELLOW}⚠ Some files missing: $passed/$total${NC}"
fi
echo "========================================"

echo ""
echo "📊 Role Statistics:"
echo "   - Common role tasks: 7"
echo "   - Kubernetes role tasks: 3"
echo "   - Monitoring role tasks: 6"
echo ""

echo "🚀 To deploy:"
echo "   ansible-playbook -i inventory.ini site.yml"
