# 3.8 - Modular Pods, NetworkPolicy, and Rollback

## Why this matters
Without strict segmentation and rollback automation, a single faulty deployment can spread failure across the whole agent stack.

## Security baseline
1. 1 agent = 1 pod.
2. Default deny-all (ingress + egress).
3. Explicit allowlist for inter-agent flows.
4. Dedicated service account per agent.
5. Restricted pod security context (`runAsNonRoot`, `no-new-privileges`, `readOnlyRootFilesystem`).
6. Controlled rolling updates with automatic rollback on failure.

## Minimum required policies
- `default-deny-all`
- `allow-dns`
- `router-ingress-from-workers`
- `workers-ingress-from-router`
- `workers-egress-to-router`
- `router-egress-local-llm`

## Safe validation sequence
```bash
kubectl kustomize k8s/agents >/tmp/phoenix-agents-render.yaml
kubectl apply -k k8s/agents
kubectl rollout status deployment/phoenix-router -n phoenix-agents --timeout=120s
```

Rollback command:
```bash
kubectl rollout undo deployment/phoenix-router -n phoenix-agents
```

## Ongoing hygiene
- Schedule orphan-resource audits.
- Remove stale failed pods early.
- Keep an execution log entry for each security-impacting operation.
