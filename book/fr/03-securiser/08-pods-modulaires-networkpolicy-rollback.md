# 3.8 - Pods Modulaires, NetworkPolicy et Rollback

## Pourquoi ce chapitre
Un cluster agentique sans micro-segmentation ni rollback automatise cree un risque de propagation rapide en cas d'erreur ou de compromission.

## Principes de securite appliques
1. 1 agent = 1 pod.
2. Deny-all par defaut (ingress + egress).
3. Allowlist explicite inter-agents.
4. Service account dedie par agent.
5. Pod security restrictive (`runAsNonRoot`, `no-new-privileges`, `readOnlyRootFilesystem`).
6. Rolling update controle + rollback automatique si echec.

## Policies reseau minimales
- `default-deny-all`: bloque tout.
- `allow-dns`: autorise DNS vers `kube-system`.
- `router-ingress-from-workers`: seuls les workers parlent au routeur.
- `workers-ingress-from-router`: seul le routeur parle aux workers.
- `workers-egress-to-router`: retour strict vers le routeur.
- `router-egress-local-llm`: sortie limitee aux endpoints LLM locaux autorises.

## Sequence de validation securisee
```bash
kubectl kustomize k8s/agents >/tmp/phoenix-agents-render.yaml
kubectl apply -k k8s/agents
kubectl rollout status deployment/phoenix-router -n phoenix-agents --timeout=120s
```

En cas d'echec:
```bash
kubectl rollout undo deployment/phoenix-router -n phoenix-agents
```

## Hygiene continue
- Audit regulier des ressources orphelines.
- Suppression immediate des pods en echec persistants.
- Traçabilite obligatoire dans le journal d'execution du projet.
