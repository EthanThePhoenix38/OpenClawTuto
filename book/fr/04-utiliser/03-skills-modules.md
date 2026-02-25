# 🎯 4.3 - Skills et Modules Marketplace

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas decouvrir le marketplace ClawHub et apprendre a installer, configurer et creer des skills pour etendre les capacites d'Phoenix. Les skills transforment ton assistant en outil specialise.

**Objectifs :**
- Comprendre l'architecture des skills
- Parcourir et installer des skills depuis ClawHub
- Configurer les skills installes
- Creer ton propre skill personnalise

---

## 🛠️ Prérequis

| Composant | Requis | Verification |
|-----------|--------|--------------|
| Phoenix Gateway | Actif | `curl http://localhost:18789/api/health` |
| Connexion Internet | Pour ClawHub | `ping clawhub.io` |
| Compte ClawHub | Optionnel | Pour publier des skills |

---

## 📝 Étapes détaillées

### Étape 1 : Comprendre les skills

**Pourquoi ?**
Les skills sont des modules qui ajoutent des fonctionnalites specifiques a Phoenix. Ils peuvent acceder a des APIs externes, executer du code, manipuler des fichiers ou integrer des services tiers.

**Comment ?**

Types de skills disponibles :

| Type | Description | Exemple |
|------|-------------|---------|
| **Tool** | Fonction appelee par le LLM | Recherche web, calcul |
| **Agent** | Workflow autonome multi-etapes | Assistant email |
| **Integration** | Connexion service externe | GitHub, Jira, Notion |
| **Persona** | Personnalite predefinee | Expert juridique |

Structure d'un skill :

```
mon-skill/
├── manifest.json      # Metadonnees et configuration
├── index.js           # Point d'entree
├── tools/             # Fonctions disponibles
├── prompts/           # Templates de prompts
└── README.md          # Documentation
```

**Vérification :**
```bash
docker exec phoenix-gateway phoenix skills types
```

---

### Étape 2 : Explorer ClawHub

**Pourquoi ?**
ClawHub est le marketplace officiel d'Phoenix. Il propose des skills gratuits et premium, evalues par la communaute.

**Comment ?**

Liste les skills populaires :

```bash
docker exec phoenix-gateway phoenix hub search --sort popularity
```

Recherche par categorie :

```bash
docker exec phoenix-gateway phoenix hub search --category productivity
```

Recherche par mot-cle :

```bash
docker exec phoenix-gateway phoenix hub search "github"
```

Affiche les details d'un skill :

```bash
docker exec phoenix-gateway phoenix hub info web-search
```

**Vérification :**
```bash
docker exec phoenix-gateway phoenix hub categories
```

Tu verras les categories disponibles : productivity, development, communication, data, creative, etc.

---

### Étape 3 : Installer un skill

**Pourquoi ?**
L'installation telecharge le skill, verifie sa signature et l'integre au gateway. Les skills sont isoles dans des conteneurs pour la securite.

**Comment ?**

Installe le skill de recherche web :

```bash
docker exec phoenix-gateway phoenix hub install web-search
```

Installe plusieurs skills :

```bash
docker exec phoenix-gateway phoenix hub install github-integration notion-sync calendar-manager
```

Installe une version specifique :

```bash
docker exec phoenix-gateway phoenix hub install web-search@1.2.0
```

Liste les skills installes :

```bash
docker exec phoenix-gateway phoenix skills list
```

**Vérification :**
```bash
docker exec phoenix-gateway phoenix skills status web-search
```

Le skill doit afficher `status: active`.

---

### Étape 4 : Configurer un skill

**Pourquoi ?**
Chaque skill a des options de configuration : cles API, preferences, limites. Sans configuration, certains skills ne fonctionnent pas.

**Comment ?**

Affiche la configuration requise :

```bash
docker exec phoenix-gateway phoenix skills config web-search --show-required
```

Configure via CLI :

```bash
docker exec phoenix-gateway phoenix skills config web-search --set apiKey=TA_CLE_API --set maxResults=10
```

Ou modifie le fichier de configuration :

```bash
nano ~/.phoenix/skills/web-search/config.json
```

```json
{
  "apiKey": "TA_CLE_API",
  "maxResults": 10,
  "safeSearch": true,
  "language": "fr",
  "region": "FR"
}
```

Recharge le skill :

```bash
docker exec phoenix-gateway phoenix skills reload web-search
```

**Vérification :**
```bash
docker exec phoenix-gateway phoenix skills test web-search "test de recherche"
```

---

### Étape 5 : Gerer les skills

**Pourquoi ?**
Tu dois pouvoir activer, desactiver, mettre a jour et supprimer des skills selon tes besoins.

**Comment ?**

Desactive un skill temporairement :

```bash
docker exec phoenix-gateway phoenix skills disable web-search
```

Reactive un skill :

```bash
docker exec phoenix-gateway phoenix skills enable web-search
```

Mets a jour un skill :

```bash
docker exec phoenix-gateway phoenix hub update web-search
```

Mets a jour tous les skills :

```bash
docker exec phoenix-gateway phoenix hub update --all
```

Supprime un skill :

```bash
docker exec phoenix-gateway phoenix hub uninstall web-search
```

**Vérification :**
```bash
docker exec phoenix-gateway phoenix skills list --status
```

---

### Étape 6 : Creer un skill personnalise

**Pourquoi ?**
Tu peux creer des skills sur mesure pour tes besoins specifiques : automatisations internes, integrations proprietaires, logique metier.

**Comment ?**

Cree la structure du skill :

```bash
mkdir -p ~/.phoenix/skills/mon-skill/tools && cd ~/.phoenix/skills/mon-skill
```

Cree le manifest :

```bash
cat > manifest.json << 'EOF'
{
  "name": "mon-skill",
  "version": "1.0.0",
  "description": "Mon skill personnalise",
  "author": "Ton Nom",
  "main": "index.js",
  "tools": ["calculer", "convertir"],
  "permissions": ["network"],
  "config": {
    "precision": {
      "type": "number",
      "default": 2,
      "description": "Decimales pour les calculs"
    }
  }
}
EOF
```

Cree le point d'entree :

```bash
cat > index.js << 'EOF'
module.exports = {
  name: 'mon-skill',

  async initialize(config) {
    this.precision = config.precision || 2;
    console.log('Mon skill initialise');
  },

  tools: {
    calculer: {
      description: 'Effectue un calcul mathematique',
      parameters: {
        expression: { type: 'string', required: true }
      },
      async execute({ expression }) {
        const result = eval(expression);
        return { result: Number(result.toFixed(this.precision)) };
      }
    },
    convertir: {
      description: 'Convertit une temperature',
      parameters: {
        valeur: { type: 'number', required: true },
        de: { type: 'string', enum: ['celsius', 'fahrenheit'] },
        vers: { type: 'string', enum: ['celsius', 'fahrenheit'] }
      },
      async execute({ valeur, de, vers }) {
        let result;
        if (de === 'celsius' && vers === 'fahrenheit') {
          result = (valeur * 9/5) + 32;
        } else if (de === 'fahrenheit' && vers === 'celsius') {
          result = (valeur - 32) * 5/9;
        } else {
          result = valeur;
        }
        return { result: Number(result.toFixed(this.precision)) };
      }
    }
  }
};
EOF
```

Installe le skill local :

```bash
docker exec phoenix-gateway phoenix skills install-local /app/skills/mon-skill
```

**Vérification :**
```bash
docker exec phoenix-gateway phoenix skills test mon-skill calculer '{"expression": "2+2*3"}'
```

Resultat attendu : `{"result": 8}`

---

## ✅ Checklist

- [ ] ClawHub accessible et recherche fonctionnelle
- [ ] Au moins un skill installe depuis ClawHub
- [ ] Skill configure avec les parametres requis
- [ ] Skill teste avec succes
- [ ] Commandes de gestion maitrisees (enable, disable, update)
- [ ] Structure d'un skill personnalise comprise
- [ ] Skill personnalise cree et fonctionnel (optionnel)

---

## ⚠️ Dépannage

### Erreur : "Skill not found on ClawHub"

**Cause :** Nom incorrect ou skill retire.

**Solution :**
```bash
docker exec phoenix-gateway phoenix hub search "nom-partiel"
```

---

### Erreur : "Configuration required"

**Cause :** Le skill necessite des parametres obligatoires.

**Solution :**
```bash
docker exec phoenix-gateway phoenix skills config NOM_SKILL --show-required
```

Configure les champs marques `required: true`.

---

### Erreur : "Permission denied"

**Cause :** Le skill demande des permissions non accordees.

**Solution :**
```bash
docker exec phoenix-gateway phoenix skills permissions NOM_SKILL --grant network,filesystem
```

---

### Skill personnalise non detecte

**Cause :** Chemin incorrect ou manifest invalide.

**Solution :**
```bash
docker exec phoenix-gateway phoenix skills validate ~/.phoenix/skills/mon-skill
```

Corrige les erreurs indiquees dans le manifest.json.

---

### Skill bloque au chargement

**Cause :** Erreur dans le code du skill.

**Solution :**
```bash
docker logs phoenix-gateway | grep "mon-skill"
```

Verifie la syntaxe JavaScript et les imports.

---

## 🔗 Ressources

| Ressource | URL |
|-----------|-----|
| ClawHub Marketplace | https://clawhub.io |
| Documentation Skills | https://docs.phoenix.ai/skills |
| SDK Developpeur | https://docs.phoenix.ai/sdk |
| Exemples de Skills | https://github.com/phoenix/skill-examples |
| Forum Communaute | https://community.phoenix.ai |

---

## ➡️ Prochaine étape

Tu maitrises les skills ! Dans le chapitre suivant, tu vas automatiser des workflows complexes avec **n8n** : [4.4 - Workflows n8n](./04-workflows-n8n.md).
