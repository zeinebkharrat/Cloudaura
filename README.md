# Kubernetes Cluster Deployment with Ansible Roles

## 📋 Project Structure

```
k8s-ansible-roles/
├── inventory.ini                  # Inventory file with all hosts
├── group_vars/
│   ├── all.yml                   # Global variables
│   └── k8s_masters.yml           # Master-specific variables
├── site.yml                      # Main playbook
├── setup-ssh.yml                 # SSH and /etc/hosts configuration
├── create-test-pods.yml          # Test pod deployment playbook
├── roles/
│   ├── common/                   # Common preparation role
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── kernel-modules.yml
│   │   │   ├── sysctl.yml
│   │   │   ├── install-packages.yml
│   │   │   ├── setup-containerd.yml
│   │   │   ├── install-k8s-components.yml
│   │   │   └── reboot.yml
│   │   └── handlers/
│   │       └── main.yml
│   ├── kubernetes/               # Kubernetes deployment role
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── master-init.yml
│   │   │   └── worker-join.yml
│   │   └── templates/
│   │       └── kubeadm-config.yaml.j2
│   └── monitoring/               # Monitoring stack role
│       ├── tasks/
│       │   ├── main.yml
│       │   ├── install-helm.yml
│       │   ├── deploy-prometheus.yml
│       │   ├── configure-alertmanager.yml
│       │   ├── deploy-alerts.yml
│       │   └── display-info.yml
│       ├── files/
│       │   ├── alertmanager-values.yaml
│       │   └── high-cpu-alert.yaml
│       └── defaults/
│           └── main.yml
```

## 🚀 Quick Start

### Prerequisites
- 3 Ubuntu 24.04 VMs (1 master, 2 workers)
- SSH access to all nodes
- Ansible installed on control node

### Step 1: Update Inventory
Edit `inventory.ini` with your actual IP addresses:
```ini
[k8s_masters]
k8s-master ansible_host=YOUR_MASTER_IP ansible_user=ubuntu

[k8s_workers]
k8s-master ansible_host=YOUR_MASTER_IP ansible_user=ubuntu
k8s-worker1 ansible_host=YOUR_WORKER1_IP ansible_user=ubuntu
k8s-worker2 ansible_host=YOUR_WORKER2_IP ansible_user=ubuntu
```

### Step 2: Deploy Everything
```bash
# Deploy complete infrastructure (SSH setup + K8s + Monitoring)
ansible-playbook -i inventory.ini site.yml
```

### Step 3: Verify Deployment
```bash
# On master node
kubectl get nodes
kubectl get pods -A
```

## 📦 Individual Playbook Execution

### 1. SSH Setup Only
```bash
ansible-playbook -i inventory.ini setup-ssh.yml
```
This playbook:
- Generates SSH keys on master
- Distributes keys to workers
- Configures `/etc/hosts` on all nodes
- Tests SSH connectivity

### 2. Deploy Kubernetes Only
```bash
# Deploy common preparation + Kubernetes
ansible-playbook -i inventory.ini site.yml --tags kubernetes
```

### 3. Deploy Monitoring Only
```bash
# Deploy monitoring stack (requires K8s to be running)
ansible-playbook -i inventory.ini site.yml --tags monitoring
```

### 4. Create Test Pods
```bash
ansible-playbook -i inventory.ini create-test-pods.yml
```

## 🎯 Role Details

### Common Role
**Purpose**: Prepares all nodes with required dependencies

**Tasks**:
- Disable SWAP
- Configure kernel modules (overlay, br_netfilter)
- Configure sysctl parameters
- Add Docker and Kubernetes repositories
- Install containerd
- Install kubelet, kubeadm, kubectl
- Reboot nodes

### Kubernetes Role
**Purpose**: Deploys and configures Kubernetes cluster

**Master Tasks**:
- Initialize control plane with kubeadm
- Configure kubeconfig for ubuntu user
- Install Flannel CNI
- Allow pod scheduling on control plane
- Generate join command

**Worker Tasks**:
- Join workers to cluster using join command
- Verify node registration

### Monitoring Role
**Purpose**: Deploys monitoring stack with Prometheus, Grafana, and Alertmanager

**Tasks**:
- Install Helm
- Deploy kube-prometheus-stack
- Configure Alertmanager for email notifications
- Deploy custom CPU usage alerts
- Expose Grafana via NodePort

## 🔐 SSH and Hosts Configuration

The `setup-ssh.yml` playbook automatically:

1. **Generates SSH keys** on the master node
2. **Distributes public keys** to all worker nodes
3. **Updates `/etc/hosts`** on all nodes with cluster hostnames
4. **Tests SSH connectivity** from master to workers

No manual `ssh-keygen` or `ssh-copy-id` required!

## 📊 Accessing Monitoring

After deployment, access Grafana at:
```
http://<MASTER_IP>:<GRAFANA_NODEPORT>
Username: admin
Password: admin
```

The NodePort is displayed at the end of the monitoring deployment.

## 🔧 Customization

### Change Kubernetes Version
Edit `group_vars/all.yml`:
```yaml
k8s_version: "1.29"  # Change to desired version
```

### Change Pod Network CIDR
Edit `group_vars/all.yml`:
```yaml
pod_network_cidr: "10.244.0.0/16"
```

### Update Alertmanager Email
Edit `roles/monitoring/files/alertmanager-values.yaml`

### Modify Master IP
Edit `group_vars/k8s_masters.yml`:
```yaml
control_plane_endpoint: "YOUR_MASTER_IP:6443"
```

## 🧪 Testing

### Verify Cluster
```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

### Test Pod Deployment
```bash
ansible-playbook -i inventory.ini create-test-pods.yml
kubectl get pods
```

### Test Monitoring
```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### Test Alerting
Generate high CPU load to trigger alert:
```bash
# On any node
stress --cpu 4 --timeout 300s
```

## 📝 Notes

- Master node also acts as a worker in this lab setup
- Swap is automatically disabled on all nodes
- Containerd is configured with systemd cgroup driver
- Flannel CNI is used for pod networking
- Grafana password is set to "admin" by default
- High CPU alert triggers at >50% usage for 2 minutes

## 🐛 Troubleshooting

### SSH Issues
```bash
# Manually verify SSH from master
ssh ubuntu@k8s-worker1
```

### Kubernetes Not Starting
```bash
# Check kubelet logs
journalctl -u kubelet -f
```

### Monitoring Pods Not Ready
```bash
# Check pod status
kubectl get pods -n monitoring
kubectl describe pod <pod-name> -n monitoring
```

### Alertmanager Email Not Working
- Verify Gmail app password is correct
- Check Alertmanager logs: `kubectl logs -n monitoring alertmanager-xxx`

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Ansible Documentation](https://docs.ansible.com/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

## ✅ Features Implemented

✅ Automated SSH key distribution  
✅ Automatic /etc/hosts configuration  
✅ Role-based Ansible structure  
✅ Kubernetes role (master + workers)  
✅ Monitoring role (Prometheus + Grafana + Alertmanager)  
✅ Modular and reusable design  
✅ Idempotent playbooks  
✅ Email alerting configured  
✅ Custom CPU usage alerts  

---

**Created for Cloud Engineering Project - OpenStack Epoxy 2025.1 + Ubuntu 24.04**
