# 5.4 - Pod Hardening and Orphan Cleanup

## Goal
Deploy a modular Kubernetes baseline (1 agent = 1 pod), enforce safe rollouts with rollback, and clean orphan resources.

## Prerequisites
- Working kubectl access to the target cluster.
- Manifests available under `k8s/agents/*`.
- Working namespace: `phoenix-agents`.

## Step 1 - Check cluster health
```bash
kubectl get pods -A -o wide --request-timeout=8s
kubectl get networkpolicy -A --request-timeout=8s
```

If the API is unavailable, stop and fix connectivity first.

## Step 2 - Review the modular bundle
```bash
kubectl kustomize k8s/agents | head -n 60
```

Checklist:
- 6 deployments (router, planner, implementer, qa, security, messaging)
- 6 dedicated service accounts
- `default-deny-all` plus allowlist policies
- rolling update strategy on every deployment

## Step 3 - Deploy with automatic rollback guard
```bash
./monitoring/deploy_agents_k8s.sh
```

This script:
- applies `k8s/agents`;
- waits for each rollout status;
- triggers `kubectl rollout undo` when a rollout fails.

## Step 4 - Clean orphan resources
```bash
./monitoring/cleanup_orphans.sh --namespace phoenix-agents --k8s-only
./monitoring/cleanup_orphans.sh --local-only
```

Cleanup scope:
- stale `Failed`/`Succeeded` pods;
- managed deployments outside the expected list;
- stale local PID files.

## Final verification
```bash
kubectl get deploy -n phoenix-agents
kubectl get pods -n phoenix-agents -o wide
kubectl get networkpolicy -n phoenix-agents
```

Success criteria:
- exactly 1 healthy pod per agent;
- no orphan managed resource;
- deny-all + allowlist policies effectively active.
