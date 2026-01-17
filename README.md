# 🛠️ NetOps Automation Toolkit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/ryantsou/netops-automation-toolkit/graphs/commit-activity)

Complete suite of professional shell tools for network administrators. Designed to simplify daily monitoring, security, automation and reporting tasks.

## 📋 Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Available Scripts](#available-scripts)
- [Configuration](#configuration)
- [Examples](#examples)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

### 🔍 Monitoring
- **Bandwidth Monitor**: Real-time bandwidth monitoring per interface
- **Latency Tracker**: Continuous latency and jitter monitoring between sites
- **Service Watcher**: Critical service monitoring with auto-restart

### 🔐 Security
- **Firewall Analyzer**: Firewall rule analysis and vulnerability detection
- **SSL Certificate Checker**: SSL/TLS certificate verification and expiration alerts
- **Intrusion Detector**: Anomaly detection and intrusion attempts

### ⚙️ Automation
- **Config Backup**: Automated network configuration backup with Git versioning
- **Bulk Ping**: Mass connectivity testing across IP ranges
- **VLAN Provisioner**: Automated VLAN deployment

### 📊 Reporting
- **Network Report**: Detailed network report generation
- **Compliance Checker**: ISO 27001 / CIS Benchmarks compliance audit

## 🚀 Installation

### Prerequisites

```bash
# Required tools
sudo apt-get update
sudo apt-get install -y bash curl wget net-tools dnsutils nmap
```

### Quick installation

```bash
git clone https://github.com/ryantsou/netops-automation-toolkit.git
cd netops-automation-toolkit
chmod +x install.sh
./install.sh
```

### Manual installation

```bash
git clone https://github.com/ryantsou/netops-automation-toolkit.git
cd netops-automation-toolkit
chmod +x scripts/**/*.sh

# Add to PATH (optional)
echo 'export PATH="$PATH:$(pwd)/scripts"' >> ~/.bashrc
source ~/.bashrc
```

## 📖 Usage

### Bandwidth monitoring

```bash
./scripts/monitoring/bandwidth-monitor.sh -i eth0 -t 10
```

### SSL certificate verification

```bash
./scripts/security/ssl-cert-checker.sh -f config/hosts.txt -d 30
```

### Configuration backup

```bash
./scripts/automation/config-backup.sh -c config/devices.yaml
```

### Network report generation

```bash
./scripts/reporting/network-report.sh -o reports/
```

## 📂 Available Scripts

### Monitoring

| Script | Description | Parameters |
|--------|-------------|------------|
| `bandwidth-monitor.sh` | Real-time bandwidth monitoring | `-i` interface, `-t` interval |
| `latency-tracker.sh` | Multi-site latency monitoring | `-f` hosts file, `-c` count |
| `service-watcher.sh` | Critical service monitoring | `-s` service, `-r` auto-restart |

### Security

| Script | Description | Parameters |
|--------|-------------|------------|
| `firewall-analyzer.sh` | Firewall rule analysis | `-t` type (iptables/ufw) |
| `ssl-cert-checker.sh` | SSL certificate verification | `-f` hosts, `-d` days |
| `intrusion-detector.sh` | Intrusion detection | `-l` log file, `-a` alert |

### Automation

| Script | Description | Parameters |
|--------|-------------|------------|
| `config-backup.sh` | Network config backup | `-c` config file, `-e` encrypt |
| `bulk-ping.sh` | Mass connectivity testing | `-r` range, `-t` timeout |
| `vlan-provisioner.sh` | VLAN deployment | `-v` vlan_id, `-n` name |

### Reporting

| Script | Description | Parameters |
|--------|-------------|------------|
| `network-report.sh` | Complete network report | `-o` output dir, `-f` format |
| `compliance-checker.sh` | Compliance audit | `-s` standard (iso27001/cis) |

## ⚙️ Configuration

Configuration files are located in the `config/` directory:

- `config/devices.yaml`: Network equipment list
- `config/hosts.txt`: Hosts to monitor
- `config/alerts.conf`: Alert configuration
- `config/templates/`: Configuration templates

### Configuration example (devices.yaml)

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

## 💡 Examples

### Complete infrastructure monitoring

```bash
# Terminal 1: Bandwidth monitoring
./scripts/monitoring/bandwidth-monitor.sh -i eth0 -t 5 &

# Terminal 2: Latency monitoring
./scripts/monitoring/latency-tracker.sh -f config/hosts.txt -c 100 &

# Terminal 3: Service monitoring
./scripts/monitoring/service-watcher.sh -s "nginx apache2 mysql" -r
```

### Automated security audit

```bash
# SSL certificate verification
./scripts/security/ssl-cert-checker.sh -f config/hosts.txt -d 30

# Firewall analysis
./scripts/security/firewall-analyzer.sh -t iptables

# Compliance report generation
./scripts/reporting/compliance-checker.sh -s iso27001 -o reports/
```

### Daily automated backup (cron)

```bash
# Add to crontab
crontab -e

# Daily backup at 2 AM
0 2 * * * /path/to/netops-automation-toolkit/scripts/automation/config-backup.sh -c /path/to/config/devices.yaml -e
```

## 🔧 Development

### Project structure

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
# Run tests
./tests/run_tests.sh
```

## 🤝 Contributing

Contributions are welcome! Here's how to contribute:

1. Fork the project
2. Create a branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Guidelines

- Follow shell coding conventions (ShellCheck)
- Add clear comments
- Test scripts before submission
- Update documentation

## 📝 Roadmap

- [ ] SD-WAN monitoring support
- [ ] Prometheus/Grafana integration
- [ ] Interactive web dashboard
- [ ] Multi-vendor support (Cisco, Juniper, HP, Arista)
- [ ] 5G network slicing module
- [ ] REST API for external integration
- [ ] Machine Learning for anomaly detection

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Riantsoa Rajhonson** - [@ryantsou](https://github.com/ryantsou)

Network & IT Engineering Student @ Polytech Dijon

## 🙏 Acknowledgments

- Open-source community
- Polytech Dijon
- Project contributors

## 📞 Support

For questions or suggestions:
- Open an [issue](https://github.com/ryantsou/netops-automation-toolkit/issues)
- Contact me via [LinkedIn](https://linkedin.com)

---

⭐ If this project helps you, don't hesitate to give it a star!
