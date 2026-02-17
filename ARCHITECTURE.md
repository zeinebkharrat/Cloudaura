# Architecture du Projet Kubernetes avec Ansible

## 🏗️ Architecture d'Infrastructure

```
┌─────────────────────────────────────────────────────────────────┐
│                      OpenStack Epoxy 2025.1                      │
│                        Ubuntu 24.04 VMs                          │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
        ┌────────────────────────────────────────────┐
        │        Ansible Control Node (Master)       │
        │         192.168.1.102 (k8s-master)        │
        └────────────────────────────────────────────┘
                                 │
                 ┌───────────────┼───────────────┐
                 │               │               │
                 ▼               ▼               ▼
        ┌────────────┐  ┌────────────┐  ┌────────────┐
        │ k8s-master │  │k8s-worker1 │  │k8s-worker2 │
        │ .102       │  │   .138     │  │   .174     │
        │ (Control+  │  │  (Worker)  │  │  (Worker)  │
        │  Worker)   │  │            │  │            │
        └────────────┘  └────────────┘  └────────────┘
```

## 📦 Structure des Rôles Ansible

```
k8s-ansible-roles/
│
├── 🎯 PLAYBOOKS PRINCIPAUX
│   ├── site.yml                  # Orchestrateur principal
│   ├── setup-ssh.yml             # Configuration SSH automatique
│   └── create-test-pods.yml      # Tests et validation
│
├── 📋 CONFIGURATION
│   ├── inventory.ini             # Définition des hosts
│   ├── ansible.cfg               # Configuration Ansible
│   └── group_vars/
│       ├── all.yml               # Variables globales
│       └── k8s_masters.yml       # Variables master
│
└── 🎭 RÔLES
    │
    ├── 🔧 COMMON ROLE (Préparation des nœuds)
    │   ├── tasks/
    │   │   ├── main.yml                    # Orchestrateur
    │   │   ├── kernel-modules.yml          # Modules noyau
    │   │   ├── sysctl.yml                  # Paramètres système
    │   │   ├── install-packages.yml        # Packages requis
    │   │   ├── setup-containerd.yml        # Runtime container
    │   │   ├── install-k8s-components.yml  # K8s binaires
    │   │   └── reboot.yml                  # Redémarrage
    │   └── handlers/
    │       └── main.yml                    # Gestionnaires
    │
    ├── ☸️ KUBERNETES ROLE (Déploiement cluster)
    │   ├── tasks/
    │   │   ├── main.yml              # Orchestrateur
    │   │   ├── master-init.yml       # Init control plane
    │   │   └── worker-join.yml       # Ajout workers
    │   └── templates/
    │       └── kubeadm-config.yaml.j2 # Config kubeadm
    │
    └── 📊 MONITORING ROLE (Stack observabilité)
        ├── tasks/
        │   ├── main.yml                      # Orchestrateur
        │   ├── install-helm.yml              # Helm package manager
        │   ├── deploy-prometheus.yml         # Prometheus stack
        │   ├── configure-alertmanager.yml    # Alertes email
        │   ├── deploy-alerts.yml             # Règles custom
        │   └── display-info.yml              # Infos d'accès
        ├── files/
        │   ├── alertmanager-values.yaml      # Config SMTP
        │   └── high-cpu-alert.yaml           # Alerte CPU
        └── defaults/
            └── main.yml                      # Variables par défaut
```

## 🔄 Flux d'Exécution

```
┌─────────────────────────────────────────────────────────────────┐
│                    ansible-playbook site.yml                     │
└─────────────────────────────────────────────────────────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 │                               │
                 ▼                               ▼
        ┌─────────────────┐           ┌─────────────────┐
        │  PHASE 0: SSH   │           │ PHASE 1: DEPS   │
        │  & /etc/hosts   │           │ Python/K8s libs │
        └─────────────────┘           └─────────────────┘
                 │                               │
                 └───────────────┬───────────────┘
                                 ▼
                        ┌─────────────────┐
                        │  PHASE 2: COMMON│
                        │   Role Applied  │
                        │   to All Nodes  │
                        └─────────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 │                               │
                 ▼                               ▼
        ┌─────────────────┐           ┌─────────────────┐
        │ PHASE 3: K8S    │           │ PHASE 4: MON    │
        │ Master + Workers│    ──────>│ Prom + Grafana  │
        │   Deployment    │           │  + Alertmanager │
        └─────────────────┘           └─────────────────┘
```

## 🎯 Composants du Rôle Common

```
┌──────────────────────────────────────────────────────────┐
│                     COMMON ROLE                          │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  1. ❌ Désactivation SWAP                               │
│  2. 🔧 Configuration modules noyau (overlay, br_netfilter)│
│  3. ⚙️  Configuration sysctl (IP forward, iptables)      │
│  4. 📦 Installation packages (curl, ca-certificates)     │
│  5. 🐋 Setup Docker repo + containerd                    │
│  6. ☸️  Installation kubelet, kubeadm, kubectl          │
│  7. 🔄 Redémarrage des nœuds                            │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## ☸️ Composants du Rôle Kubernetes

```
┌─────────────────────────────────────────────────────────────┐
│                    KUBERNETES ROLE                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📋 MASTER NODE:                                            │
│    1. Création config kubeadm (template Jinja2)            │
│    2. kubeadm init --config                                │
│    3. Configuration kubeconfig pour ubuntu user            │
│    4. Installation Flannel CNI                             │
│    5. Autorisation pods sur control-plane                  │
│    6. Génération join command                              │
│                                                             │
│  👷 WORKER NODES:                                           │
│    1. Récupération join command depuis master              │
│    2. Vérification accessibilité API server                │
│    3. Exécution kubeadm join                               │
│    4. Vérification enregistrement du nœud                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Composants du Rôle Monitoring

```
┌─────────────────────────────────────────────────────────────┐
│                    MONITORING ROLE                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🎯 DÉPLOIEMENT:                                            │
│    1. Installation Helm 3                                  │
│    2. Ajout repo prometheus-community                      │
│    3. Création namespace monitoring                        │
│    4. Déploiement kube-prometheus-stack                    │
│       - Prometheus Operator                                │
│       - Prometheus Server                                  │
│       - Alertmanager                                       │
│       - Grafana (NodePort)                                 │
│       - Node Exporter                                      │
│       - Kube State Metrics                                 │
│                                                             │
│  📧 CONFIGURATION ALERTES:                                  │
│    1. Configuration SMTP Gmail                             │
│    2. Règles d'alerting custom (CPU > 50%)                │
│    3. Routage vers email-notifications                     │
│                                                             │
│  📈 ACCÈS:                                                  │
│    - Grafana: http://MASTER_IP:NodePort                    │
│    - Prometheus: kubectl port-forward                      │
│    - Alertmanager: kubectl port-forward                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🔐 Configuration SSH Automatique

```
┌─────────────────────────────────────────────────────────────┐
│              SETUP-SSH.YML PLAYBOOK                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🔑 SUR LE MASTER:                                          │
│    1. Création répertoire .ssh                             │
│    2. ssh-keygen -t rsa -b 4096 (si nécessaire)           │
│    3. Lecture de la clé publique                           │
│    4. Configuration /etc/hosts                             │
│                                                             │
│  📤 SUR LES WORKERS:                                        │
│    1. Création répertoire .ssh                             │
│    2. Ajout clé publique master → authorized_keys          │
│    3. Configuration /etc/hosts                             │
│                                                             │
│  ✅ TESTS:                                                  │
│    - SSH depuis master vers chaque worker                  │
│    - Vérification connectivité sans mot de passe           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Commandes de Déploiement

```bash
# 🔹 Déploiement complet (recommandé)
ansible-playbook -i inventory.ini site.yml

# 🔹 SSH et /etc/hosts uniquement
ansible-playbook -i inventory.ini setup-ssh.yml

# 🔹 Vérifier la structure des rôles
./verify-structure.sh

# 🔹 Déployer des pods de test
ansible-playbook -i inventory.ini create-test-pods.yml

# 🔹 Vérifier le cluster depuis le master
ssh ubuntu@k8s-master "kubectl get nodes"
ssh ubuntu@k8s-master "kubectl get pods -A"
```

## 📊 Stack Monitoring Déployée

```
┌──────────────────────────────────────────────────────┐
│              MONITORING NAMESPACE                     │
├──────────────────────────────────────────────────────┤
│                                                      │
│  📊 Prometheus                                       │
│    - Collecte métriques cluster                     │
│    - Règles d'alerting                              │
│    - Stockage métriques                             │
│                                                      │
│  📈 Grafana (NodePort)                              │
│    - Dashboards pré-configurés                      │
│    - Visualisation métriques                        │
│    - User: admin / Pass: admin                      │
│                                                      │
│  🔔 Alertmanager                                     │
│    - Gestion notifications                          │
│    - Email via SMTP Gmail                           │
│    - Groupement et déduplication                    │
│                                                      │
│  📡 Node Exporter                                    │
│    - Métriques système (CPU, RAM, disque)          │
│    - Sur chaque nœud                                │
│                                                      │
│  🎯 Kube State Metrics                              │
│    - État des ressources K8s                        │
│    - Pods, deployments, services                    │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## ✅ Critères de Projet Satisfaits

✓ **Infrastructure OpenStack**
  - Epoxy 2025.1
  - Ubuntu 24.04
  - 3 VMs (1 master + 2 workers)

✓ **Automation Ansible basée sur les rôles**
  - ✅ Rôle Common (préparation)
  - ✅ Rôle Kubernetes (déploiement cluster)
  - ✅ Rôle Monitoring (stack observabilité)

✓ **Configuration SSH automatique**
  - ✅ ssh-keygen automatique
  - ✅ ssh-copy-id vers workers
  - ✅ /etc/hosts configuré

✓ **Stack de Monitoring**
  - ✅ Prometheus
  - ✅ Grafana (NodePort)
  - ✅ Alertmanager (email)
  - ✅ Alertes CPU custom

✓ **Organisation Modulaire**
  - Structure roles/ claire
  - Séparation des responsabilités
  - Réutilisabilité
  - Idempotence

---

**Projet Cloud Engineering - OpenStack + Kubernetes + Ansible**
