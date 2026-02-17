# 🚀 INSTRUCTIONS DE DÉPLOIEMENT

## 📦 Contenu du Projet

Ce projet contient une infrastructure Kubernetes complète déployable avec Ansible en utilisant une architecture basée sur des rôles.

### Structure:
```
k8s-ansible-roles/
├── 📄 Playbooks principaux
│   ├── site.yml                    # Playbook principal (tout déployer)
│   ├── setup-ssh.yml               # Configuration SSH automatique
│   └── create-test-pods.yml        # Pods de test
├── 📄 Configuration
│   ├── inventory.ini               # Inventaire des hosts
│   ├── ansible.cfg                 # Configuration Ansible
│   └── group_vars/                 # Variables par groupe
├── 🎭 Rôles
│   ├── common/                     # Préparation système
│   ├── kubernetes/                 # Déploiement K8s
│   └── monitoring/                 # Stack monitoring
└── 📚 Documentation
    ├── README.md
    ├── QUICKSTART.md
    ├── ARCHITECTURE.md
    └── PROJECT_SUMMARY.md
```

## 🔧 ÉTAPE 1: Installation

### Sur votre nœud master (k8s-master):

```bash
# Copier le dossier sur votre master
cd /home/ubuntu
# Placer le dossier k8s-ansible-roles ici

# OU si vous avez l'archive:
tar -xzf k8s-ansible-roles.tar.gz
cd k8s-ansible-roles

# Rendre le script de vérification exécutable
chmod +x verify-structure.sh
```

## 📝 ÉTAPE 2: Configuration

### 2.1 Modifier l'inventaire

```bash
nano inventory.ini
```

**IMPORTANT**: Remplacez les IPs par vos vraies adresses:

```ini
[k8s_masters]
k8s-master ansible_host=192.168.1.102 ansible_user=ubuntu  # ← Votre IP master

[k8s_workers]
k8s-master ansible_host=192.168.1.102 ansible_user=ubuntu  # ← Votre IP master
k8s-worker1 ansible_host=192.168.1.138 ansible_user=ubuntu # ← Votre IP worker1
k8s-worker2 ansible_host=192.168.1.174 ansible_user=ubuntu # ← Votre IP worker2
```

### 2.2 Modifier les variables master

```bash
nano group_vars/k8s_masters.yml
```

Remplacez par votre IP master:

```yaml
control_plane_endpoint: "192.168.1.102:6443"  # ← Votre IP master
api_server_advertise_address: "192.168.1.102" # ← Votre IP master
```

### 2.3 (Optionnel) Configurer l'email pour les alertes

Si vous voulez recevoir des alertes par email:

```bash
nano roles/monitoring/files/alertmanager-values.yaml
```

Modifiez les paramètres SMTP avec vos informations.

## ✅ ÉTAPE 3: Vérification

```bash
# Vérifier que tous les fichiers sont présents
./verify-structure.sh
```

Vous devriez voir: `✓ All files present! (35/35)`

## 🚀 ÉTAPE 4: DÉPLOIEMENT

### Une seule commande pour tout déployer:

```bash
ansible-playbook -i inventory.ini site.yml
```

⏱️ **Durée**: 15-20 minutes

### Ce qui sera automatiquement configuré:
1. ✅ SSH passwordless entre master et workers
2. ✅ /etc/hosts sur tous les nœuds
3. ✅ Désactivation SWAP
4. ✅ Installation containerd + Kubernetes
5. ✅ Initialisation du cluster
6. ✅ Join des workers
7. ✅ Installation Flannel CNI
8. ✅ Déploiement Prometheus + Grafana + Alertmanager

## 📊 ÉTAPE 5: Vérification

### Vérifier le cluster:

```bash
kubectl get nodes
```

**Résultat attendu:**
```
NAME          STATUS   ROLE           AGE   VERSION
k8s-master    Ready    control-plane  10m   v1.29.x
k8s-worker1   Ready    <none>         8m    v1.29.x
k8s-worker2   Ready    <none>         8m    v1.29.x
```

### Vérifier tous les pods:

```bash
kubectl get pods -A
```

Tous les pods doivent être en `Running` ou `Completed`.

### Accéder à Grafana:

À la fin du déploiement, notez l'URL affichée:
```
Grafana URL: http://192.168.1.102:XXXXX
Username: admin
Password: admin
```

Ouvrez cette URL dans votre navigateur.

## 🧪 ÉTAPE 6: Tests

### Déployer des pods de test:

```bash
ansible-playbook -i inventory.ini create-test-pods.yml
kubectl get pods
```

### Tester une alerte CPU:

```bash
# Installer stress (si pas installé)
sudo apt install stress -y

# Générer de la charge CPU
stress --cpu 4 --timeout 300s
```

Après 2 minutes, vous devriez voir l'alerte dans Grafana.

## 📚 Commandes Utiles

### Kubernetes:
```bash
# Info cluster
kubectl cluster-info

# Tous les services
kubectl get svc -A

# Logs d'un pod
kubectl logs <pod-name> -n <namespace>

# Décrire un pod
kubectl describe pod <pod-name> -n <namespace>
```

### Monitoring:
```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090

# Port-forward Alertmanager
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093

# Vérifier les alertes configurées
kubectl get prometheusrule -n monitoring
```

### Ansible:
```bash
# Tester la connectivité
ansible all -i inventory.ini -m ping

# Rejouer uniquement le rôle monitoring
ansible-playbook -i inventory.ini site.yml --tags monitoring

# Mode dry-run (vérifier sans appliquer)
ansible-playbook -i inventory.ini site.yml --check
```

## 🐛 Dépannage

### Problème: Worker ne rejoint pas

```bash
# Sur le worker
sudo kubeadm reset
sudo rm -rf /etc/kubernetes/

# Rejouer le playbook
ansible-playbook -i inventory.ini site.yml
```

### Problème: Pods en Pending

```bash
# Vérifier les événements
kubectl get events -A --sort-by='.lastTimestamp'

# Vérifier Flannel
kubectl logs -n kube-flannel -l app=flannel
```

### Problème: SSH ne fonctionne pas

```bash
# Rejouer la configuration SSH
ansible-playbook -i inventory.ini setup-ssh.yml
```

### Problème: Grafana inaccessible

```bash
# Vérifier le service
kubectl get svc -n monitoring monitoring-grafana

# Récupérer le NodePort
kubectl get svc -n monitoring monitoring-grafana -o jsonpath="{.spec.ports[0].nodePort}"

# Vérifier le pod
kubectl get pods -n monitoring | grep grafana
```

## 📖 Documentation Complète

Pour plus de détails, consultez:

- **README.md** - Documentation complète
- **QUICKSTART.md** - Guide de démarrage rapide
- **ARCHITECTURE.md** - Diagrammes et architecture
- **PROJECT_SUMMARY.md** - Résumé du projet
- **FEATURES.md** - Liste des fonctionnalités

## ✅ Checklist de Déploiement

- [ ] Dossier copié sur k8s-master
- [ ] inventory.ini configuré avec vraies IPs
- [ ] group_vars/k8s_masters.yml configuré
- [ ] Structure vérifiée (./verify-structure.sh)
- [ ] Playbook site.yml exécuté
- [ ] Cluster vérifié (kubectl get nodes)
- [ ] Grafana accessible
- [ ] Tests effectués

## 🎓 Points Clés du Projet

### ✅ Architecture en Rôles (5 points)

1. **Rôle Common** (`roles/common/`)
   - 8 fichiers de tâches
   - Préparation système complète

2. **Rôle Kubernetes** (`roles/kubernetes/`)
   - Initialisation master
   - Join workers
   - Configuration CNI

3. **Rôle Monitoring** (`roles/monitoring/`)
   - Prometheus + Grafana + Alertmanager
   - Alertes email
   - Dashboards

### ✅ Automatisations Bonus

- Configuration SSH automatique (ssh-keygen + ssh-copy-id)
- Configuration /etc/hosts automatique
- Tests intégrés
- Documentation complète

## 🏆 Résultat Final

Après un déploiement réussi, vous aurez:

✅ Cluster Kubernetes 3 nœuds opérationnel
✅ Stack monitoring complète (Prometheus + Grafana)
✅ Alertes email configurées
✅ SSH configuré automatiquement
✅ Architecture modulaire en rôles Ansible

---

**🚀 Bon déploiement !**

**Questions?** Consultez la documentation dans les fichiers .md
