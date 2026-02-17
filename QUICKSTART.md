# 🚀 Guide de Démarrage Rapide

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir :

- ✅ 3 VMs Ubuntu 24.04 configurées dans OpenStack
- ✅ Accès SSH à toutes les VMs
- ✅ Ansible installé sur le nœud de contrôle
- ✅ Connexion Internet sur toutes les VMs

## 🔧 Configuration Initiale

### 1. Cloner ou copier le projet

```bash
# Sur votre nœud de contrôle (k8s-master)
cd ~
# Copier le dossier k8s-ansible-roles ici
```

### 2. Modifier l'inventaire

Éditez `inventory.ini` avec VOS adresses IP :

```ini
[k8s_masters]
k8s-master ansible_host=192.168.1.102 ansible_user=ubuntu

[k8s_workers]
k8s-master ansible_host=192.168.1.102 ansible_user=ubuntu
k8s-worker1 ansible_host=192.168.1.138 ansible_user=ubuntu
k8s-worker2 ansible_host=192.168.1.174 ansible_user=ubuntu
```

⚠️ **Important** : Remplacez les IPs par vos vraies adresses !

### 3. Modifier les variables de groupe

Éditez `group_vars/k8s_masters.yml` :

```yaml
control_plane_endpoint: "VOTRE_MASTER_IP:6443"
api_server_advertise_address: "VOTRE_MASTER_IP"
```

### 4. (Optionnel) Modifier la configuration email

Si vous voulez utiliser vos propres alertes email, éditez :
`roles/monitoring/files/alertmanager-values.yaml`

## 🚀 Déploiement en Une Commande

```bash
cd k8s-ansible-roles
ansible-playbook -i inventory.ini site.yml
```

Cette commande va :
1. ✅ Configurer SSH automatiquement
2. ✅ Configurer /etc/hosts
3. ✅ Préparer tous les nœuds (Common role)
4. ✅ Déployer Kubernetes (master + workers)
5. ✅ Déployer la stack monitoring

⏱️ **Durée** : 15-20 minutes

## 📊 Vérification du Déploiement

### Vérifier le cluster Kubernetes

```bash
kubectl get nodes
# Devrait afficher 3 nœuds en Ready

kubectl get pods -A
# Devrait afficher tous les pods système en Running
```

### Accéder à Grafana

À la fin du déploiement, notez le NodePort affiché :

```
Grafana URL: http://192.168.1.102:XXXXX
Username: admin
Password: admin
```

Ouvrez cette URL dans votre navigateur.

### Vérifier les alertes

```bash
kubectl get prometheusrule -n monitoring
# Devrait afficher high-cpu-alert
```

## 🧪 Tester avec des Pods

```bash
ansible-playbook -i inventory.ini create-test-pods.yml
kubectl get pods
# Devrait afficher mynginx-pod et busybox-pod en Running
```

## 🔧 Commandes Utiles

### Kubernetes

```bash
# Voir tous les nœuds
kubectl get nodes -o wide

# Voir tous les pods
kubectl get pods -A

# Voir les services
kubectl get svc -A

# Décrire un pod
kubectl describe pod <pod-name> -n <namespace>

# Logs d'un pod
kubectl logs <pod-name> -n <namespace>
```

### Monitoring

```bash
# Pods de monitoring
kubectl get pods -n monitoring

# Services de monitoring
kubectl get svc -n monitoring

# Port-forward Prometheus
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090

# Port-forward Alertmanager
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093
```

### Ansible

```bash
# Tester la connectivité
ansible all -i inventory.ini -m ping

# Vérifier la configuration SSH
ansible-playbook -i inventory.ini setup-ssh.yml --check

# Rejouer uniquement le rôle monitoring
ansible-playbook -i inventory.ini site.yml --tags monitoring
```

## 🐛 Dépannage Rapide

### Problème : Nœud worker ne rejoint pas

```bash
# Sur le worker
sudo kubeadm reset
sudo rm -rf /etc/kubernetes/

# Rejouer le playbook
ansible-playbook -i inventory.ini site.yml
```

### Problème : Pods en Pending

```bash
# Vérifier les événements
kubectl get events -A --sort-by='.lastTimestamp'

# Vérifier les logs CNI (Flannel)
kubectl logs -n kube-flannel -l app=flannel
```

### Problème : SSH ne fonctionne pas

```bash
# Rejouer la configuration SSH
ansible-playbook -i inventory.ini setup-ssh.yml

# Test manuel
ssh ubuntu@k8s-worker1
```

### Problème : Grafana inaccessible

```bash
# Vérifier le service
kubectl get svc -n monitoring monitoring-grafana

# Récupérer le NodePort
kubectl get svc -n monitoring monitoring-grafana -o jsonpath="{.spec.ports[0].nodePort}"

# Vérifier les pods
kubectl get pods -n monitoring | grep grafana
```

## 📚 Documentation Complète

- 📖 **README.md** : Documentation détaillée
- 🏗️ **ARCHITECTURE.md** : Diagrammes et architecture
- ✅ **verify-structure.sh** : Vérification de la structure

## 💡 Conseils

1. **Toujours sauvegarder** : Faites une snapshot de vos VMs avant de commencer
2. **Vérifiez les ressources** : Assurez-vous que vos VMs ont au moins 2 CPU et 2GB RAM
3. **Logs Ansible** : Utilisez `-v` ou `-vv` pour plus de détails lors de l'exécution
4. **Idempotence** : Vous pouvez rejouer les playbooks sans problème

## 🎯 Étapes Suivantes

Après le déploiement réussi :

1. ✅ Explorez les dashboards Grafana
2. ✅ Déployez vos propres applications
3. ✅ Configurez des alertes personnalisées
4. ✅ Testez la haute disponibilité
5. ✅ Documentez votre infrastructure

## 🆘 Support

En cas de problème :

1. Consultez les logs : `kubectl logs <pod> -n <namespace>`
2. Vérifiez les événements : `kubectl get events -A`
3. Vérifiez l'état des services : `systemctl status kubelet`
4. Examinez les logs système : `journalctl -u kubelet -f`

---

**Bonne chance avec votre projet ! 🚀**
