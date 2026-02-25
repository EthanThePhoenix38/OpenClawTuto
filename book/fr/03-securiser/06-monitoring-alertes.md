# 🎯 3.6 - Monitoring et Alertes

## 📋 Ce que tu vas apprendre

- Comment surveiller Phoenix en temps réel
- Configurer des alertes automatiques
- Analyser les logs de sécurité
- Détecter les comportements anormaux

## 🛠️ Prérequis

- [Chapitre 3.5](./05-audit-securite.md) complété
- k3s opérationnel
- Phoenix déployé

---

## 📝 Étapes détaillées

### Étape 1 : Comprendre le monitoring Kubernetes

**Pourquoi ?** Kubernetes collecte automatiquement des métriques sur tous les pods. On va les exploiter pour surveiller Phoenix.

**Les 3 niveaux de monitoring :**

```
┌─────────────────────────────────────────────────────────────────┐
│                    PYRAMIDE DU MONITORING                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                    ┌─────────────┐                              │
│                    │   ALERTES   │  ← Notifications critiques   │
│                    └─────────────┘                              │
│                                                                 │
│               ┌───────────────────────┐                         │
│               │      DASHBOARDS       │  ← Visualisation        │
│               └───────────────────────┘                         │
│                                                                 │
│          ┌─────────────────────────────────┐                    │
│          │          MÉTRIQUES             │  ← Données brutes   │
│          └─────────────────────────────────┘                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Étape 2 : Installer le monitoring avec Prometheus

**Pourquoi ?** Prometheus est le standard Kubernetes pour collecter des métriques.

**Comment ?**

1. Ajouter le repo Helm Prometheus :

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && helm repo update
```

2. Créer le fichier de configuration :

```bash
cat << 'EOF' > /tmp/prometheus-values.yaml
prometheus:
  prometheusSpec:
    retention: 7d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
    serviceMonitorSelector:
      matchLabels:
        release: prometheus
alertmanager:
  enabled: true
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 2Gi
grafana:
  enabled: true
  adminPassword: "changeme-secure-password"
  persistence:
    enabled: true
    size: 5Gi
EOF
```

3. Installer Prometheus Stack :

```bash
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --values /tmp/prometheus-values.yaml --wait
```

**Vérification :**

```bash
kubectl get pods -n monitoring
```

**Résultat attendu :**
```
NAME                                                     READY   STATUS    RESTARTS   AGE
prometheus-kube-prometheus-operator-xxxx                 1/1     Running   0          2m
prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   0          2m
prometheus-grafana-xxxx                                  3/3     Running   0          2m
alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running   0          2m
```

### Étape 3 : Créer un ServiceMonitor pour Phoenix

**Pourquoi ?** Pour que Prometheus collecte les métriques d'Phoenix, il faut lui dire où les trouver.

**Comment ?**

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: phoenix-monitor
  namespace: phoenix
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: phoenix
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
    scrapeTimeout: 10s
  namespaceSelector:
    matchNames:
    - phoenix
EOF
```

**Vérification :**

```bash
kubectl get servicemonitor -n phoenix
```

### Étape 4 : Configurer les alertes critiques

**Pourquoi ?** Tu veux être prévenu AVANT que quelque chose de grave arrive.

**Alertes à configurer :**

| Alerte | Seuil | Criticité |
|--------|-------|-----------|
| Pod down | 0 pods running | 🔴 Critique |
| CPU élevé | > 80% pendant 5min | 🟠 Warning |
| Mémoire élevée | > 90% pendant 5min | 🟠 Warning |
| Erreurs API | > 10/min | 🟠 Warning |
| Tentatives auth | > 5 échecs/min | 🔴 Critique |

**Comment ?**

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: phoenix-alerts
  namespace: phoenix
  labels:
    release: prometheus
spec:
  groups:
  - name: phoenix.rules
    rules:
    # Alerte si Phoenix est down
    - alert: PhoenixDown
      expr: up{job="phoenix"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Phoenix est DOWN"
        description: "Le pod Phoenix ne répond plus depuis 1 minute."

    # Alerte CPU élevé
    - alert: PhoenixHighCPU
      expr: rate(container_cpu_usage_seconds_total{pod=~"phoenix.*"}[5m]) > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Phoenix CPU élevé"
        description: "CPU > 80% depuis 5 minutes."

    # Alerte mémoire élevée
    - alert: PhoenixHighMemory
      expr: container_memory_usage_bytes{pod=~"phoenix.*"} / container_spec_memory_limit_bytes{pod=~"phoenix.*"} > 0.9
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Phoenix mémoire élevée"
        description: "Mémoire > 90% depuis 5 minutes."

    # Alerte tentatives d'authentification échouées
    - alert: PhoenixAuthFailures
      expr: rate(phoenix_auth_failures_total[1m]) > 5
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Tentatives d'authentification suspectes"
        description: "Plus de 5 échecs d'authentification par minute."
EOF
```

**Vérification :**

```bash
kubectl get prometheusrules -n phoenix
```

### Étape 5 : Configurer les notifications

**Pourquoi ?** Une alerte qui s'affiche juste dans un dashboard ne sert à rien si tu ne la vois pas.

**Options de notification :**

| Canal | Difficulté | Recommandé |
|-------|------------|------------|
| Email | ⭐⭐ | Oui |
| Slack | ⭐⭐ | Oui |
| Discord | ⭐⭐ | Oui |
| Telegram | ⭐⭐⭐ | Oui |
| PagerDuty | ⭐⭐⭐⭐ | Pro |
| ntfy.sh | ⭐ | Excellent |

**Configuration ntfy.sh (le plus simple) :**

ntfy.sh est un service de notifications push gratuit et open source.

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-config
  namespace: monitoring
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
    route:
      group_by: ['alertname', 'severity']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
      receiver: 'ntfy'
      routes:
      - match:
          severity: critical
        receiver: 'ntfy-critical'
    receivers:
    - name: 'ntfy'
      webhook_configs:
      - url: 'https://ntfy.sh/phoenix-alerts'
        send_resolved: true
    - name: 'ntfy-critical'
      webhook_configs:
      - url: 'https://ntfy.sh/phoenix-critical'
        send_resolved: true
EOF
```

**Pour recevoir les alertes :**

1. Télécharge l'app ntfy sur ton téléphone (iOS/Android)
2. Abonne-toi au topic `phoenix-alerts`
3. Tu recevras les alertes en push !

### Étape 6 : Accéder à Grafana

**Pourquoi ?** Grafana offre des dashboards visuels pour explorer les métriques.

**Comment ?**

1. Récupérer le mot de passe admin :

```bash
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d && echo
```

2. Exposer Grafana localement :

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

3. Ouvrir dans ton navigateur : http://localhost:3000

4. Se connecter :
   - Username: `admin`
   - Password: (celui récupéré à l'étape 1)

### Étape 7 : Créer un dashboard Phoenix

**Pourquoi ?** Un dashboard personnalisé te donne une vue d'ensemble en un coup d'œil.

**Comment ?**

Dans Grafana :
1. Clique sur "+" → "Import"
2. Colle ce JSON :

```json
{
  "annotations": {
    "list": []
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": null,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "red", "value": 80}
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
      "id": 1,
      "options": {
        "orientation": "auto",
        "reduceOptions": {
          "calcs": ["lastNotNull"],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "10.0.0",
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "expr": "up{job=\"phoenix\"}",
          "refId": "A"
        }
      ],
      "title": "Phoenix Status",
      "type": "gauge"
    },
    {
      "datasource": {"type": "prometheus", "uid": "prometheus"},
      "fieldConfig": {
        "defaults": {
          "color": {"mode": "palette-classic"},
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {"legend": false, "tooltip": false, "viz": false},
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {"type": "linear"},
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {"group": "A", "mode": "none"},
            "thresholdsStyle": {"mode": "off"}
          },
          "mappings": [],
          "thresholds": {"mode": "absolute", "steps": [{"color": "green", "value": null}]},
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
      "id": 2,
      "options": {"legend": {"calcs": [], "displayMode": "list", "placement": "bottom", "showLegend": true}, "tooltip": {"mode": "single", "sort": "none"}},
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "expr": "rate(container_cpu_usage_seconds_total{pod=~\"phoenix.*\"}[5m]) * 100",
          "legendFormat": "CPU %",
          "refId": "A"
        }
      ],
      "title": "CPU Usage",
      "type": "timeseries"
    }
  ],
  "refresh": "5s",
  "schemaVersion": 38,
  "style": "dark",
  "tags": ["phoenix"],
  "templating": {"list": []},
  "time": {"from": "now-1h", "to": "now"},
  "timepicker": {},
  "timezone": "",
  "title": "Phoenix Dashboard",
  "uid": "phoenix-main",
  "version": 1,
  "weekStart": ""
}
```

### Étape 8 : Configurer les logs centralisés

**Pourquoi ?** Les logs sont essentiels pour debugger et auditer.

**Comment ?**

1. Voir les logs en direct :

```bash
kubectl logs -f deployment/phoenix -n phoenix
```

2. Filtrer les erreurs :

```bash
kubectl logs deployment/phoenix -n phoenix | grep -i error
```

3. Exporter les logs des dernières 24h :

```bash
kubectl logs deployment/phoenix -n phoenix --since=24h > /tmp/phoenix-logs-$(date +%Y%m%d).txt
```

### Étape 9 : Surveiller les événements de sécurité

**Pourquoi ?** Les événements Kubernetes révèlent les problèmes de sécurité.

**Comment ?**

```bash
kubectl get events -n phoenix --sort-by='.lastTimestamp' | tail -20
```

**Événements à surveiller :**

| Événement | Signification | Action |
|-----------|---------------|--------|
| `FailedScheduling` | Pas assez de ressources | Augmenter les limits |
| `BackOff` | Container crash en boucle | Vérifier les logs |
| `NetworkNotReady` | Problème réseau | Vérifier CNI |
| `FailedMount` | Volume non monté | Vérifier PVC |
| `Unhealthy` | Healthcheck échoué | Vérifier l'app |

---

## ✅ Checklist

- [ ] Prometheus Stack installé
- [ ] ServiceMonitor Phoenix créé
- [ ] Règles d'alertes configurées
- [ ] Notifications configurées (ntfy.sh)
- [ ] Grafana accessible
- [ ] Dashboard Phoenix créé
- [ ] Logs centralisés configurés

---

## ⚠️ Dépannage

**Problème :** "Prometheus ne collecte pas les métriques Phoenix"

**Solution :**
```bash
kubectl get endpoints -n phoenix
kubectl describe servicemonitor phoenix-monitor -n phoenix
```
Vérifie que le label `release: prometheus` est présent.

**Problème :** "Les alertes ne partent pas"

**Solution :**
```bash
kubectl logs -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0
```
Vérifie la configuration webhook.

**Problème :** "Grafana ne démarre pas"

**Solution :**
```bash
kubectl describe pod -n monitoring -l app.kubernetes.io/name=grafana
```
Vérifie les PVC et les ressources.

---

## 🔗 Ressources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [ntfy.sh Documentation](https://docs.ntfy.sh/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)

---

## ➡️ Prochaine étape

👉 [Chapitre 3.7 - Backup automatique](./07-backup-automatique.md)
