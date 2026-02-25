# Master Plan - Plateforme IA hybride (Local + VPS) multi-apps

## 1) Vision produit
Construire une plateforme exploitable en production avec:
- installation locale automatisee,
- installation VPS en un clic (offre payante),
- supervision via applications operateur,
- orchestration hybride IA locale + IA payantes,
- extension future Windows et Android.

Objectif business principal:
- vendre le deploiement VPS one-click comme offre payante.

## 2) Perimetre produit

### 2.1 Phase 1 (obligatoire)
- Installation locale HYPER securisee (priorite absolue)
- Installateur VPS one-click
- App macOS (supervision local + VPS)
- App iOS (supervision local + VPS)
- Control-plane API commun

### 2.2 Phase 2
- App Windows
- App Android
- Reuse complet des APIs, policies et runbooks

## 3) Priorite #1 - Installation locale HYPER securisee

Objectif:
- livrer d'abord une installation locale ultra robuste, auto-corrective, auto-reparable,
- pilotable en CLI simple ET en interface graphique.

### 3.1 Exigences minimales
- Installation en 1 commande
- Verification complete post-install
- Auto-correction des ecarts standards
- Auto-reparation guidee en cas de panne
- Rollback automatique en cas d'echec critique
- Journal d'audit lisible

### 3.2 Securite par defaut
- bind loopback force
- auth forte activee
- sandbox activee (non-main minimum)
- permissions strictes sur secrets/config
- blocage des options dangereuses sans override explicite
- verification version Phoenix minimale securisee

### 3.3 Auto-correction / auto-reparation
- detection continue des derives de config
- correction safe automatique
- mode reparation complete (avec plan d'action)
- baseline de sante periodique

### 3.4 Interface CLI simple
Commandes cibles:
- `platform install local`
- `platform doctor`
- `platform repair --safe`
- `platform repair --full`
- `platform status --deep`
- `platform rollback`

### 3.5 Interface graphique (obligatoire)
Fonctions GUI minimales:
- bouton Install local
- panneau Health / Security status
- bouton Auto-fix safe
- bouton Repair complete
- vue Logs et audit
- bouton Rollback
- assistant guide (wizard) pour setup initial

### 3.6 Definition of done priorite #1
- machine neuve installable en local en 1 action CLI ou GUI
- auto-correction fonctionne sur les erreurs courantes
- auto-reparation restaure un etat operationnel
- rollback valide en test
- runbook local finalise

## 4) Consolidation de l'existant ORCHESTRATION_IA
Base a reutiliser:
- `monitoring/control_server.py`
- `monitoring/chat_api.py`
- `monitoring/superviseur_server.py`
- `monitoring/network_monitor.py`
- `monitoring/llm_monitor.sh`
- `monitoring/dashboard.html`
- `monitoring/superviseur-llm.html`
- `monitoring/watchdog_control_server.sh`
- `bridges/codex_bridge.py`
- `start_all.sh`
- `tests/test_chat_api.py`
- `test_models.sh`

Regle:
- encapsuler et migrer progressivement, pas de refonte destructrice.

## 5) Architecture cible

### 5.1 Topologie
- Control Plane API
- Orchestrateur de taches
- Providers locaux (Ollama, LM Studio, Open WebUI)
- Providers payants (OpenAI, Anthropic, autres)
- Couche securite/policies
- Observabilite
- Apps clientes (macOS, iOS, puis Windows/Android)

### 5.2 Frontieres de securite
- host -> VM
- VM -> sandbox tools
- control-plane -> clients
- agent -> tools

### 5.3 Modes
- Local
- VPS
- Hybride

## 6) Produits a livrer

### 6.1 Installateur local automatise
- preflight machine
- install runtime + VM
- deploy stack locale
- hardening auto
- doctor + repair + rollback
- CLI + GUI

### 6.2 Installateur VPS one-click (payant)
- provisioning VPS
- hardening OS
- deploy stack
- DNS/TLS
- URL + token operateur
- rollback en echec

### 6.3 App macOS (dual-mode)
- supervision local/VPS
- actions ops controlees
- logs/audit
- diagnostics

### 6.4 App iOS (dual-mode)
- supervision local/VPS
- alerting
- actions limitees et confirmees

## 7) Plan hybride IA locale + IA payantes

### 7.1 Routage
- local prioritaire
- payant pour taches complexes
- fallback local -> payant
- fallback payant -> local degrade

### 7.2 Confidentialite
- redaction avant cloud
- classification des requetes
- audit des decisions de routage

### 7.3 Config
- `providers.local.*`
- `providers.cloud.*`
- `routing.policy.*`
- `security.redaction.*`

## 8) Control-plane API commune

### 8.1 Endpoints coeur
- `GET /api/status`
- `GET /api/models`
- `POST /api/chat`
- `POST /api/context/reset`

### 8.2 Endpoints ops
- `POST /api/ops/restart-service`
- `POST /api/ops/approve-pairing`
- `GET /api/ops/log-stream`
- `POST /api/routing/dry-run`

### 8.3 Endpoints install/deploy
- `POST /api/deploy/local/install`
- `POST /api/deploy/local/doctor`
- `POST /api/deploy/local/repair`
- `POST /api/deploy/local/rollback`
- `POST /api/deploy/vps/one-click`
- `POST /api/deploy/vps/update`
- `POST /api/deploy/vps/rollback`

## 9) Monétisation VPS
- Stripe subscriptions
- activation/suspension auto
- quotas par plan
- isolation tenant stricte
- backup/restore par tenant

## 10) Roadmap implementation

### Sprint 0
- contrat API
- baseline securite
- scaffold modules

### Sprint 1 (prioritaire)
- install local CLI + GUI
- doctor + repair + rollback
- hardening local complet

### Sprint 2
- control-plane v1
- routage hybride v1

### Sprint 3
- one-click VPS v1

### Sprint 4
- app macOS v1

### Sprint 5
- app iOS v1

### Sprint 6
- billing + quotas + production readiness

### Sprint 7
- Windows + Android

## 11) Backlog technique priorise
1. `deploy/local` (install/doctor/repair/rollback)
2. `ui/installer` (wizard + health + repair)
3. `src/contracts/api`
4. `src/control-plane`
5. `src/security`
6. `src/providers/local`
7. `src/providers/paid`
8. `src/routing`
9. `deploy/vps`
10. `apps/macos`
11. `apps/ios`
12. `billing`
13. `apps/windows` (phase 2)
14. `apps/android` (phase 2)

## 12) KPIs
- succes install local (CLI)
- succes install local (GUI)
- succes auto-repair
- temps moyen recovery
- succes one-click VPS
- latence p50/p95
- cout cloud
- incidents critiques

## 13) Definition of done globale
- installation locale hyper securisee operationnelle (CLI + GUI)
- auto-correction et auto-reparation validees
- supervision macOS/iOS sur local et VPS
- one-click VPS payant operationnel
- routing hybride local/cloud stable
- runbooks incident et rollback valides

## 14) Execution immediate
Ordre strict:
1. livrer installation locale hyper securisee (CLI + GUI)
2. livrer apps macOS et iOS (supervision dual-mode)
3. livrer doctor/repair/rollback locaux
4. livrer control-plane v1
5. livrer one-click VPS payant
6. ouvrir Windows + Android

## 15) Durcissement SSH / Tailscale / Cloudflare (obligatoire)

Objectif:
- reduire le risque d'acces distant compromis,
- maintenir un acces operateur fiable (local + VPS),
- integrer ces controles dans l'installation locale hyper securisee et l'auto-reparation.

### 15.1 Risques recents a prendre en compte (dates explicites)

#### OpenSSH
- **CVE-2025-26465** (MITM dans certains contextes `VerifyHostKeyDNS`) - publie le **18 fevrier 2025**.
- **CVE-2025-26466** (DoS pre-auth via `SSH2_MSG_PING`) - publie le **18 fevrier 2025**.
- **CVE-2025-61985** (risque autour des URI `ssh://` et `ProxyCommand` selon usage) - publie le **6 octobre 2025**.

#### Tailscale
- **TS-2025-008** (Tailnet Lock non applique sur certains noeuds sans state dir) - publie le **19 novembre 2025**.
  - Correctif: **1.90.8+** (et definir `--statedir` / `TS_STATE_DIR`).
- **TS-2026-001** (execution de commandes elevees dans scenario macOS specifique) - publie le **15 janvier 2026**.
  - Correctif: **1.94.0+**.

#### Cloudflare
- Changement securite: suppression de `cloudflared proxy-dns` a partir du **2 fevrier 2026** (annonce du **11 novembre 2025**) suite a une vuln dans une lib sous-jacente.
- Risque operationnel majeur: vol de token tunnel = risque d'usurpation de tunnel.

### 15.2 Position architecture (decision)
- SSH et Tailscale restent les canaux principaux d'admin privee.
- Cloudflare est utilise en couche complementaire de Zero Trust (pas un remplacement des patchs ni du hardening SSH/Tailscale).
- Interdiction d'exposer un port SSH brut sur Internet quand Access/Tunnel est en place.

### 15.3 Baseline SSH (a appliquer par defaut)
- `PermitRootLogin no`
- `PasswordAuthentication no`
- `KbdInteractiveAuthentication no`
- `PubkeyAuthentication yes`
- `AllowUsers` strict
- limiter forwarding non necessaire (`AllowTcpForwarding`, `PermitTunnel`, `X11Forwarding`, `AllowAgentForwarding`)
- rotation reguliere des cles / certificats
- logs SSH centralises + alertes brute-force/anomalies

### 15.4 Baseline Tailscale (a appliquer par defaut)
- version client minimum enforcee (>= 1.94.0 sur macOS cibles sensibles)
- definir explicitement `--statedir` ou `TS_STATE_DIR` sur tous les noeuds daemonises
- activer Tailnet Lock quand possible
- ACL minimales (deny par defaut)
- clefs auth one-off/ephemeres
- verification periodique `tailscale lock status`

### 15.5 Baseline Cloudflare (si active)
- preferer **Access for Infrastructure (SSH)** avec certificats courts + MFA
- appliquer politiques d'acces par utilisateur + machine posture
- activer journaux de commandes SSH
- rotation des tokens tunnel
- 2 connectors/tunnels minimum pour rotation sans coupure
- ne pas utiliser `proxy-dns` apres 2 fevrier 2026; migrer vers WARP client/connector selon cas

### 15.6 Auto-correction / auto-reparation (integree au produit)
Le module local doit verifier et corriger automatiquement:
- version OpenSSH/Tailscale/cloudflared sous seuil
- presence et permissions de config SSH durcie
- absence de `TS_STATE_DIR` / `--statedir`
- configuration Tailnet Lock incoherente
- presence d'un token tunnel non tourne depuis trop longtemps
- exposition reseau non conforme (port SSH public direct)

Actions automatiques:
- `repair --safe`: corrige config non destructive + hardening standard.
- `repair --full`: applique correction complete + redemarrages controles + validation finale.
- `rollback`: retour dernier etat sain si echec.

### 15.7 Commandes operateur simples (CLI)
- `platform doctor --scope remote`
- `platform repair --safe --scope remote`
- `platform repair --full --scope remote`
- `platform status --deep --scope remote`
- `platform rollback --scope remote`

### 15.8 Tests obligatoires
- test MITM-resistant host validation SSH
- test DoS tolerance basique SSH front
- test Tailscale lock enforcement
- test rotation token tunnel Cloudflare
- test perte tunnel + reprise auto

### 15.9 Critere d'acceptation securite remote
- aucune administration distante sans auth forte
- aucun service critique expose brut sur Internet
- non-conformites detectees par `doctor` et corrigeables par `repair`
- logs d'audit exploitables en incident

### 15.10 Sources de reference (officielles)
- OpenSSH security: https://www.openssh.org/security.html
- NVD CVE-2025-61985: https://nvd.nist.gov/vuln/detail/CVE-2025-61985
- Tailscale Security Bulletins: https://tailscale.com/security-bulletins/
- Tailscale Changelog: https://tailscale.com/changelog
- Cloudflare SSH Access for Infrastructure: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/use-cases/ssh/ssh-infrastructure-access/
- Cloudflare changelog (`proxy-dns` removal): https://developers.cloudflare.com/changelog/2025-11-11-cloudflared-proxy-dns/

## 16) Cas d'usage demande - Plateforme autonome de bout en bout

### 16.1 Besoin exprime
L'utilisateur veut des agents coordonnes capables de:
- concevoir et developper une plateforme/OS sandbox ultra securisee,
- ecrire le code, tester les vulnerabilites, corriger,
- publier le code sur GitHub/GitLab,
- deployer une offre payante de VM en ligne,
- fournir acces distant securise,
- construire le site web et integrer les paiements.

### 16.2 Reponse technique
Oui, faisable avec une architecture multi-agents, mais en mode **autonomie controlee**:
- autonomie elevee sur build/test/ops repetables,
- approbation humaine obligatoire sur actions critiques,
- interdictions techniques sur actions irreversibles non validees.

### 16.3 Matrice d'autonomie

#### A) Actions autonomes (sans validation manuelle)
- generation/refactor de code
- execution tests unitaires/integration
- scan securite (SAST/dependencies/secrets scan)
- generation docs techniques
- ouverture/maj MR/PR
- deploiement en environnement non-prod
- diagnostics + auto-repair safe

#### B) Actions avec approbation humaine obligatoire
- merge/release production
- deploiement production VPS multi-tenant
- rotation/creation secrets critiques
- publication package public
- activation plan payant client
- changements d'ACL/reseau expose

#### C) Actions interdites par defaut
- suppression irreversible donnees client
- exposition directe de services critiques sans Zero Trust
- desactivation globale des controles securite
- execution root arbitraire hors policy
- publication de code/secrets non scannes

### 16.4 Workflow cible (resume)
1. Agents design + codent (local branch)
2. Tests + security checks automatiques
3. PR/MR creee + rapport risques
4. Validation humaine sur gates critiques
5. Deploy staging puis prod
6. Monitoring continu + auto-remediation safe

### 16.5 Gates de securite obligatoires
- gate 1: tests [OK]
- gate 2: scans securite [OK]
- gate 3: policy compliance [OK]
- gate 4: approbation humaine (prod/paiement/secrets)

### 16.6 Definition of done du cas d'usage
- la chaine autonome fonctionne de dev a deploy
- les actions critiques ne passent jamais sans approbation
- audit trail complet disponible
- rollback operationnel teste

## 17) Expression complete du besoin utilisateur (demande officielle)

### 17.1 Demande centrale
Construire un **OS/plateforme d'execution ultra securise(e)**, orientee agents autonomes, capable de fonctionner en:
- local hyper securise (priorite #1),
- cloud/VPS (offre payante one-click),
- mode hybride local + cloud.

### 17.2 Capacites attendues
Le systeme doit permettre aux agents de se coordonner pour:
- concevoir l'architecture,
- ecrire le code,
- tester, securiser et corriger les vulnerabilites,
- publier le code source (GitHub/GitLab),
- deployer et exploiter des VM en ligne,
- fournir un acces en ligne securise,
- construire le site web produit,
- integrer les paiements et la gestion des plans.

### 17.3 Produits a livrer
- Produit A: Installateur local hyper securise (CLI + GUI)
- Produit B: App macOS (supervision local + VPS)
- Produit C: App iOS (supervision local + VPS)
- Produit D: Installateur VPS one-click payant
- Produit E: Control-plane API multi-agents
- Produit F (phase 2): Apps Windows + Android

### 17.4 Exigences de securite non negociables
- Zero-trust et moindre privilege
- Sandbox par defaut
- Auth forte obligatoire
- Journal d'audit complet
- Auto-correction et auto-reparation integrees
- Rollback fiable sur incident
- Validation humaine sur actions critiques

### 17.5 Exigences d'autonomie
Autonomie elevee autorisee sur:
- code, tests, scans, refactor, documentation, deploiement non-prod.
Approbation obligatoire sur:
- production, secrets critiques, paiements, publication publique finale.
Interdiction par defaut:
- actions irreversibles non validees, exposition brute de services critiques.

### 17.6 Exigences produit/business
- Offre payante VPS industrialisable
- Onboarding simple (one-click)
- Supervision operateur multi-plateforme
- Telemetrie et KPIs business/techniques
- Scalabilite multi-tenant

### 17.7 Critere de succes global
Le besoin est considere satisfait quand:
- l'installation locale hyper securisee est operationnelle,
- les apps macOS/iOS pilotent local et VPS,
- le one-click VPS payant est en production,
- la chaine autonome (dev -> test -> secure -> deploy) est exploitable,
- la gouvernance securite empêche toute action critique non approuvee.

## 18) Execution autonome par droits + feuilles de route en langage naturel

### 18.1 Principe
Le systeme doit tourner de facon autonome selon les droits explicitement accordes par l'utilisateur.
Les agents ne doivent jamais depasser leur perimetre d'autorisation.

### 18.2 Modele de droits (RBAC + policies)
Chaque agent recoit un profil de droits:
- `read-only`
- `read-write-limited`
- `ops-limited`
- `release-manager` (avec approbation humaine)

Chaque profil precise:
- outils autorises,
- chemins accessibles,
- actions reseau autorisees,
- actions interdites,
- actions avec approbation obligatoire.

### 18.3 Moteur de feuille de route agent (langage naturel)
Le systeme doit accepter des feuilles de route redigees en langage naturel, puis:
1. parser les objectifs,
2. decouper en taches executables,
3. mapper chaque tache a un agent autorise,
4. executer avec controle des droits,
5. produire un journal d'avancement lisible.

### 18.4 Format cible d'une feuille de route (naturel)
Exemple attendu:
- objectif global,
- contraintes securite,
- priorites,
- definition de termine,
- actions interdites,
- budget/temps limite.

Le moteur convertit cela en:
- backlog technique,
- plan d'execution ordonne,
- checkpoints de validation,
- demandes d'approbation si necessaire.

### 18.5 Exigences d'autonomie controlee
- execution continue sans intervention humaine pour taches non critiques,
- pause automatique et demande de validation pour taches critiques,
- reprise automatique apres validation,
- rollback si echec critique.

### 18.6 Interface operateur
CLI:
- `platform roadmap parse <fichier_nl.md>`
- `platform roadmap plan --id <roadmap_id>`
- `platform roadmap run --id <roadmap_id>`
- `platform roadmap status --id <roadmap_id>`
- `platform roadmap approve --task <task_id>`

GUI:
- editeur de feuille de route en langage naturel,
- vue graphe taches/agents,
- indicateur droits par tache,
- bouton approuver/refuser,
- timeline d'execution.

### 18.7 Critere de succes
- une feuille de route en langage naturel peut etre executee de bout en bout,
- chaque tache respecte strictement les droits attribues,
- aucune action critique n'est executee sans validation,
- l'etat d'avancement est lisible en temps reel.

### 18.8 Capacites etendues du parseur (agents + skills + MCP)
Le parseur de feuille de route en langage naturel doit aussi:
- detecter les besoins en nouveaux agents,
- generer automatiquement la specification de chaque agent (role, droits, outils, limites),
- creer/deployer ces agents dans l'environnement cible (local ou VPS),
- attribuer les skills necessaires a chaque agent selon la tache,
- identifier les MCP requis (figma, notion, etc.) et preparer leur configuration,
- verifier les prerequis MCP avant execution (auth, permissions, reachability),
- fallback sur un plan alternatif si un MCP est indisponible.

Contraintes de securite:
- aucune activation MCP hors politique autorisee,
- toute creation d'agent privilegie passe en validation humaine,
- journal complet des decisions: agent cree, skills actives, MCP choisis, raisons.

Commandes cibles supplementaires:
- `platform roadmap synthesize-agents --id <roadmap_id>`
- `platform roadmap deploy-agents --id <roadmap_id>`
- `platform roadmap plan-mcp --id <roadmap_id>`
- `platform roadmap apply-mcp --id <roadmap_id>`

Definition of done supplementaire:
- le parseur produit automatiquement les agents et skills adaptes,
- les MCP necessaires sont proposes/configures sans intervention manuelle lourde,
- toute action critique reste gatee par approbation selon la policy.

## 19) Support utilisateurs auto-gere (site + Discord) pilote par IA locale

### 19.1 Objectif
Ajouter un support utilisateur autonome pour aider les personnes a:
- installer l'outil,
- l'utiliser correctement,
- diagnostiquer et corriger les problemes courants automatiquement.

Canaux support cibles:
- site web officiel (docs, guides, FAQ, assistant support),
- serveur Discord officiel (support communautaire et bot d'assistance).

### 19.2 Principe de fonctionnement
L'IA locale agit comme moteur de support et utilise:
- une base de connaissance versionnee,
- des runbooks techniques,
- des procedures de diagnostic automatisees,
- des actions de correction safe (avec garde-fous).

### 19.3 Contenu a injecter dans l'IA (knowledge pack)
- documentation produit (installation local/VPS, usage apps)
- FAQ support et cas d'erreur frequents
- runbooks incidents (reseau, auth, sandbox, providers)
- procedures `doctor/repair/rollback`
- politiques securite et limitations d'actions
- changelog versions + incompatibilites connues

### 19.4 Capacites de support automatise
- reponse contextuelle en langage naturel
- triage des incidents (niveau 1/2/3)
- collecte automatique de diagnostics
- proposition de correctifs guides
- execution automatique de correctifs non critiques
- escalation humaine pour cas sensibles/critique

### 19.5 Site support auto-gere
- generation et mise a jour docs automatiques
- pages etat systeme, incidents, notes de version
- assistant support integre (chat)
- formulaire de ticket structure + export diagnostic

### 19.6 Discord auto-gere
- bot support avec commandes d'aide et diagnostic
- moderation automatique de base
- categories/channels par type de probleme
- routage vers runbooks et procedures officielles
- escalation vers humain selon criticite

### 19.7 Garde-fous securite support
- aucune action destructive sans validation explicite
- actions auto limitees a un scope safe
- secrets jamais affiches en clair
- journaux d'audit obligatoires pour toute correction appliquee

### 19.8 Commandes support cibles
- `platform support diagnose`
- `platform support fix --safe`
- `platform support fix --guided`
- `platform support escalate`
- `platform support publish-docs`

### 19.9 Definition of done support
- le site support est operationnel et maintenu automatiquement
- le Discord support est operationnel avec bot d'assistance
- l'IA aide effectivement les utilisateurs et corrige les problemes standards
- les cas critiques sont escalades proprement vers un humain

## 20) Capacite IA avancee: RAG + fine-tuning + modele derive

### 20.1 Exigence
La plateforme doit etre capable de:
- faire du RAG production-grade,
- faire du fine-tuning supervise,
- produire un modele derive a partir d'un modele existant (sans repartir de zero).

### 20.2 RAG (obligatoire)
Composants cibles:
- pipeline d'ingestion (docs, tickets, runbooks, code, changelogs),
- nettoyage/segmentation/versioning des connaissances,
- embeddings + index vectoriel,
- retrieval hybride (vectoriel + keyword + reranker),
- citations/sources dans les reponses,
- re-indexation incremental automatique.

Exigences securite RAG:
- filtrage ACL par utilisateur/tenant,
- redaction donnees sensibles avant indexation,
- politique de retention + purge,
- tracabilite des documents utilises dans chaque reponse.

### 20.3 Fine-tuning (obligatoire)
Capacites:
- jeu de donnees d'instruction versionne,
- pipeline de preparation (quality checks, dedup, safety filters),
- entrainement supervise (SFT) sur taches metier,
- evaluation automatique avant promotion,
- registry de modeles (versions, metadonnees, scores).

Garde-fous:
- interdire donnees sensibles non anonymisees,
- validation humaine avant promotion prod,
- rollback vers modele precedent en un clic.

### 20.4 Modele derive depuis modele existant
Approche cible:
- demarrer d'un modele fondation open-weight ou licence compatible,
- adapter par LoRA/QLoRA ou equivalent,
- eventuellement distillation specialisee selon domaine,
- exporter des variantes optimisees (local inferencing).

Contrainte legale:
- respecter strictement les licences des modeles/datasets,
- conserver la provenance (dataset lineage, model lineage).

### 20.5 MLOps minimal requis
- `data/` versionne (schemas, jeux train/eval),
- `training/` pipelines reproductibles,
- `evaluation/` benchmark qualite/securite,
- `registry/` versions modeles,
- `deployment/` promotion canary -> prod,
- monitoring drift/perf/cout.

### 20.6 Commandes cibles (simples)
- `platform rag ingest`
- `platform rag reindex`
- `platform rag eval`
- `platform tune prepare`
- `platform tune run`
- `platform tune evaluate`
- `platform model promote`
- `platform model rollback`

### 20.7 Definition of done
- RAG fiable avec citations et ACL respectees,
- fine-tuning reproductible avec evaluation objective,
- au moins un modele derive deployable localement,
- promotion/rollback modele operationnels,
- pipeline complet auditable de bout en bout.

## 21) Injection des bonnes pratiques Codex (gouvernance obligatoire)

Cette section formalise les standards `~/.codex` a appliquer au projet.

### 21.1 Regles globales
- [FORBIDDEN] zero emoji dans code, docs, commits, configs.
- [OK] utiliser les marqueurs: `[OK]`, `[WARNING]`, `[ERROR]`, `[PRIVATE]`, `[INFO]`.
- Francais par defaut pour specs/docs/communications (hors mots techniques).

### 21.2 Securite zero-trust
- Le repo est traite comme public par defaut.
- [FORBIDDEN] secrets/credentials/PII en clair dans git.
- Toute doc sensible reste hors publication (zone privee locale).
- Gitleaks + controles CI obligatoires sur secrets/docs sensibles.

### 21.3 Discipline d'execution (anti-rush)
- [FORBIDDEN] coder sans spec validee.
- Demarrer le code uniquement apres validation explicite du scope.
- TDD requis pour logique metier: test d'abord, code ensuite.
- [FORBIDDEN] pseudo-code non executable (`TODO` bloquant, mock permanent).

### 21.4 Protection des assets
- Modifier uniquement ce qui est dans le scope actif.
- [FORBIDDEN] suppression "nettoyage" hors demande explicite.
- Avant action sensible: verifier impact sur backlog et livrables futurs.

### 21.5 Regles git/versioning
- Conventional Commits obligatoires.
- Commits unitaires: 1 intention = 1 commit.
- Staging selectif obligatoire (`git restore --staged .` puis `git add` ciblé).
- [FORBIDDEN] `git add .` sans validation explicite.
- Audit securite staged obligatoire avant commit (`git diff --cached`).

### 21.6 Pre-flight obligatoire
Avant toute tache non triviale:
- lire le backlog actif,
- lire les standards `00_*` a `06_*`,
- verifier contraintes locales du repo.

Avant release/commit:
- tests [OK],
- audit staged [OK],
- conformite standards [OK]/[WARNING]/[ERROR] explicitee.

### 21.7 Nommage/conventions
- fichiers courts, lisibles, sans caracteres speciaux,
- camelCase/PascalCase/UPPER_SNAKE_CASE selon contexte,
- pas d'invention de nom produit sans validation humaine.

### 21.8 Agnosticisme et portabilite
- standards independants de l'outil/IDE/agent,
- separation stricte: standards (quoi/pourquoi), agents (qui), skills (comment),
- eviter tout couplage dur a une stack unique quand une abstraction est possible.

### 21.9 Integration au workflow autonome
Ces regles s'appliquent aussi au moteur de feuille de route:
- aucune tache ne s'execute hors droits/policies,
- taches critiques en approbation obligatoire,
- journal d'audit complet de chaque decision agent.

### 21.10 Critere d'acceptation gouvernance
- chaque pipeline respecte ces standards par defaut,
- les violations critiques bloquent commit/deploy,
- les exceptions sont explicites, tracees, et validees humainement.

## 22) Pipeline d'execution Codex obligatoire (incluant audit-security)

### 22.1 Pipeline standard (ordre impose)
1. Preflight
2. Specification validee
3. Developpement
4. Tests locaux
5. Audit-security
6. Validation humaine des actions critiques
7. Deploiement (local puis VPS)
8. Verification post-deploiement

### 22.2 Definition des gates bloquants
- Gate A `preflight`: [OK] obligatoire (contexte, backlog, standards)
- Gate B `tests`: [OK] obligatoire
- Gate C `audit-security`: [OK] obligatoire
- Gate D `validation humaine`: obligatoire pour production/secrets/paiement/exposition reseau

[ERROR] Si `audit-security` n'est pas `[OK]`, aucun deploiement n'est autorise.

### 22.3 Audit-security (minimum)
- scan dependances et CVE critiques
- scan secrets (gitleaks ou equivalent)
- verification config securite (auth, bind, sandbox, ACL)
- audit diff staged avant commit (`git diff --cached`)

### 22.4 Integration dans mon execution (Codex)
- je considere ce pipeline comme reference obligatoire avant toute action de release/deploy,
- je signale explicitement les verdicts en chat: `[OK]`, `[WARNING]`, `[ERROR]`,
- je bloque les actions critiques tant que le gate `audit-security` n'est pas valide.
