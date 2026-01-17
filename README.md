# 🛠️ NetOps Automation Toolkit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/ryantsou/netops-automation-toolkit/graphs/commit-activity)

Suite complète d'outils shell professionnels pour administrateurs réseau. Conçu pour simplifier les tâches quotidiennes de monitoring, sécurité, automatisation et reporting.

## 📋 Table des Matières

- [Fonctionnalités](#fonctionnalités)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Scripts Disponibles](#scripts-disponibles)
- [Configuration](#configuration)
- [Exemples](#exemples)
- [Contribution](#contribution)
- [Licence](#licence)

## ✨ Fonctionnalités

### 🔍 Monitoring
- **Bandwidth Monitor** : Surveillance temps réel de la bande passante par interface
- **Latency Tracker** : Monitoring continu de la latence et du jitter entre sites
- **Service Watcher** : Surveillance des services critiques avec auto-restart

### 🔐 Sécurité
- **Firewall Analyzer** : Analyse des règles firewall et détection des failles
- **SSL Certificate Checker** : Vérification des certificats SSL/TLS et alertes d'expiration
- **Intrusion Detector** : Détection d'anomalies et tentatives d'intrusion

### ⚙️ Automatisation
- **Config Backup** : Sauvegarde automatisée des configurations réseau avec versioning Git
- **Bulk Ping** : Test de connectivité massif sur plages IP
- **VLAN Provisioner** : Déploiement automatisé de VLANs

### 📊 Reporting
- **Network Report** : Génération de rapports réseau détaillés
- **Compliance Checker** : Audit de conformité ISO 27001 / CIS Benchmarks

## 🚀 Installation

### Prérequis

```bash
# Outils requis
sudo apt-get update
sudo apt-get install -y bash curl wget net-tools dnsutils nmap
```

### Installation rapide

```bash
git clone https://github.com/ryantsou/netops-automation-toolkit.git
cd netops-automation-toolkit
chmod +x install.sh
./install.sh
```

### Installation manuelle

```bash
git clone https://github.com/ryantsou/netops-automation-toolkit.git
cd netops-automation-toolkit
chmod +x scripts/**/*.sh

# Ajouter au PATH (optionnel)
echo 'export PATH="$PATH:$(pwd)/scripts"' >> ~/.bashrc
source ~/.bashrc
```

## 📖 Utilisation

### Monitoring de la bande passante

```bash
./scripts/monitoring/bandwidth-monitor.sh -i eth0 -t 10
```

### Vérification des certificats SSL

```bash
./scripts/security/ssl-cert-checker.sh -f config/hosts.txt -d 30
```

### Sauvegarde des configurations

```bash
./scripts/automation/config-backup.sh -c config/devices.yaml
```

### Génération de rapport réseau

```bash
./scripts/reporting/network-report.sh -o reports/
```

## 📂 Scripts Disponibles

### Monitoring

| Script | Description | Paramètres |
|--------|-------------|------------|
| `bandwidth-monitor.sh` | Surveillance bande passante temps réel | `-i` interface, `-t` interval |
| `latency-tracker.sh` | Monitoring latence multi-sites | `-f` fichier hosts, `-c` count |
| `service-watcher.sh` | Surveillance services critiques | `-s` service, `-r` auto-restart |

### Sécurité

| Script | Description | Paramètres |
|--------|-------------|------------|
| `firewall-analyzer.sh` | Analyse règles firewall | `-t` type (iptables/ufw) |
| `ssl-cert-checker.sh` | Vérification certificats SSL | `-f` hosts, `-d` days |
| `intrusion-detector.sh` | Détection d'intrusions | `-l` log file, `-a` alert |

### Automatisation

| Script | Description | Paramètres |
|--------|-------------|------------|
| `config-backup.sh` | Sauvegarde configs réseau | `-c` config file, `-e` encrypt |
| `bulk-ping.sh` | Test connectivité massif | `-r` range, `-t` timeout |
| `vlan-provisioner.sh` | Déploiement VLANs | `-v` vlan_id, `-n` name |

### Reporting

| Script | Description | Paramètres |
|--------|-------------|------------|
| `network-report.sh` | Rapport réseau complet | `-o` output dir, `-f` format |
| `compliance-checker.sh` | Audit conformité | `-s` standard (iso27001/cis) |

## ⚙️ Configuration

Les fichiers de configuration se trouvent dans le répertoire `config/`:

- `config/devices.yaml` : Liste des équipements réseau
- `config/hosts.txt` : Liste des hôtes à monitorer
- `config/alerts.conf` : Configuration des alertes
- `config/templates/` : Templates de configuration

### Exemple de configuration (devices.yaml)

```yaml
devices:
  - name: core-switch-01
    ip: 192.168.1.1
    type: cisco
    credentials:
      username: admin
      method: ssh-key
  
  - name: edge-router-01
    ip: 10.0.0.1
    type: juniper
    credentials:
      username: netadmin
      method: password
```

## 💡 Exemples

### Monitoring complet d'une infrastructure

```bash
# Terminal 1 : Monitoring bande passante
./scripts/monitoring/bandwidth-monitor.sh -i eth0 -t 5 &

# Terminal 2 : Monitoring latence
./scripts/monitoring/latency-tracker.sh -f config/hosts.txt -c 100 &

# Terminal 3 : Surveillance services
./scripts/monitoring/service-watcher.sh -s "nginx apache2 mysql" -r
```

### Audit de sécurité automatisé

```bash
# Vérification certificats SSL
./scripts/security/ssl-cert-checker.sh -f config/hosts.txt -d 30

# Analyse firewall
./scripts/security/firewall-analyzer.sh -t iptables

# Génération rapport de conformité
./scripts/reporting/compliance-checker.sh -s iso27001 -o reports/
```

### Backup automatisé quotidien (cron)

```bash
# Ajouter au crontab
crontab -e

# Backup quotidien à 2h du matin
0 2 * * * /path/to/netops-automation-toolkit/scripts/automation/config-backup.sh -c /path/to/config/devices.yaml -e
```

## 🔧 Développement

### Structure du projet

```
netops-automation-toolkit/
├── README.md
├── LICENSE
├── install.sh
├── scripts/
│   ├── monitoring/
│   ├── security/
│   ├── automation/
│   └── reporting/
├── config/
│   └── templates/
├── docs/
└── tests/
```

### Tests

```bash
# Lancer les tests
./tests/run_tests.sh
```

## 🤝 Contribution

Les contributions sont les bienvenues ! Voici comment contribuer :

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

### Guidelines

- Suivre les conventions de codage shell (ShellCheck)
- Ajouter des commentaires clairs
- Tester les scripts avant soumission
- Mettre à jour la documentation

## 📝 Roadmap

- [ ] Support SD-WAN monitoring
- [ ] Intégration Prometheus/Grafana
- [ ] Dashboard web interactif
- [ ] Support multi-vendor (Cisco, Juniper, HP, Arista)
- [ ] Module 5G network slicing
- [ ] API REST pour intégration externe
- [ ] Machine Learning pour détection d'anomalies

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👨‍💻 Auteur

**Riantsoa Rajhonson** - [@ryantsou](https://github.com/ryantsou)

Étudiant en Network & IT Engineering @ Polytech Dijon

## 🙏 Remerciements

- Communauté open-source
- Polytech Dijon
- Contributeurs du projet

## 📞 Support

Pour toute question ou suggestion :
- Ouvrir une [issue](https://github.com/ryantsou/netops-automation-toolkit/issues)
- Me contacter via [LinkedIn](https://linkedin.com)

---

⭐ Si ce projet vous aide, n'hésitez pas à lui donner une étoile !
