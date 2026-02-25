# 5.4 - Durcissement Pods et Nettoyage des Orphelins

## Objectif
Mettre en place un socle Kubernetes modulaire (1 agent = 1 pod), activer un cycle de deploiement avec rollback, puis nettoyer les ressources orphelines.

## Prerequis
- Acces kubectl au cluster cible.
- Manifests presents dans `k8s/agents/*`.
- Namespace de travail: `phoenix-agents`.

## Etape 1 - Verifier l'etat du cluster
```bash
kubectl get pods -A -o wide --request-timeout=8s
kubectl get networkpolicy -A --request-timeout=8s
```

Si l'API ne repond pas, ne pas forcer le deploiement. Corriger d'abord la connectivite du cluster.

## Etape 2 - Verifier le bundle modulaire
```bash
kubectl kustomize k8s/agents | head -n 60
```

Points de controle:
- 6 deployments (router, planner, implementer, qa, security, messaging)
- 6 service accounts dedies
- `default-deny-all` + policies allowlist
- strategie rolling update sur chaque deployment

## Etape 3 - Deployer avec garde-fou rollback
```bash
./monitoring/deploy_agents_k8s.sh
```

Ce script:
- applique `k8s/agents`;
- attend le `rollout status` de chaque deployment;
- execute `kubectl rollout undo` automatiquement si un rollout echoue.

## Etape 4 - Nettoyer les orphelins
```bash
./monitoring/cleanup_orphans.sh --namespace phoenix-agents --k8s-only
./monitoring/cleanup_orphans.sh --local-only
```

Ce nettoyage couvre:
- pods `Failed`/`Succeeded` devenus inutiles;
- deployments labels `phoenix.dev/managed=true` hors liste attendue;
- PID files locaux stale (processus inexistants).

## Verification finale
```bash
kubectl get deploy -n phoenix-agents
kubectl get pods -n phoenix-agents -o wide
kubectl get networkpolicy -n phoenix-agents
```

Critere de succes:
- chaque agent a exactement 1 pod sain;
- aucune ressource orpheline detectee;
- policies reseau actives avec deny-all par defaut.
