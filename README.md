# TERRAFORM-TEST — Journal de bord

Récapitulatif des actions effectuées sur le projet, dans l'ordre chronologique.

## 1. Installation de pre-commit

L'environnement Python du serveur (Ubuntu) est "externally managed" (PEP 668), donc `pip install` direct est bloqué. Installation via `pipx` à la place :

```bash
sudo apt install pipx
pipx install pre-commit
pipx ensurepath
source ~/.bashrc
```

Vérification :
```bash
pre-commit --version
```

## 2. Configuration de pre-commit

Création du fichier `.pre-commit-config.yaml` à la racine du projet, avec des hooks de base (whitespace, fin de fichier, yaml) et des hooks spécifiques Terraform (fmt, validate) :

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.96.1
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
```

Installation du hook Git :
```bash
pre-commit install
```

Test sur tous les fichiers :
```bash
pre-commit run --all-files
```

## 3. Gestion d'un fichier de config ignoré par Git

Création d'un dossier `config/` avec un fichier `app.env`, refusé par Git car la règle `*.env` (ligne 10 du `.gitignore`) l'exclut — comportement voulu pour ne pas versionner de fichiers contenant des secrets.

Solution retenue : créer un fichier d'exemple à côté, sans données sensibles :
```bash
cp config/app.env config/app.env.example
```

## 4. Incident de sécurité : credentials AWS commitées par erreur

Le fichier `app.env.example` contenait encore de vraies credentials AWS temporaires (Access Key ID, Secret Access Key, Session Token — préfixe `ASIA`, donc clés de session STS à durée limitée), simplement copiées depuis `app.env` sans être anonymisées.

**GitHub Push Protection** a bloqué le push (`GH013`) en détectant ces secrets dans le commit.

### Résolution
1. Le commit fautif n'avait pas encore atteint `origin/main` → possibilité de le corriger localement sans réécrire l'historique distant.
2. Annulation du commit local en gardant les modifications en attente :
   ```bash
   git reset --soft HEAD~1
   ```
3. Nettoyage complet du fichier `app.env.example` : suppression des vraies valeurs (même celles simplement commentées avec `#`, qui restent détectables) et remplacement par des placeholders génériques :
   ```
   AWS_ACCESS_KEY_ID=your-access-key-id-here
   AWS_SECRET_ACCESS_KEY=your-secret-access-key-here
   AWS_SESSION_TOKEN=your-session-token-here
   ```
4. Nouveau commit propre :
   ```bash
   git add config/app.env.example
   git commit -m "chore: add example config"
   ```

⚠️ **Point de vigilance** : les crédentials AWS exposées étaient temporaires (session STS), donc à durée de vie limitée, mais une vérification/révocation manuelle côté AWS reste recommandée par précaution.

## 5. Synchronisation avec origin/main (historique divergent)

Après le nettoyage, le push a été refusé (`non-fast-forward`) car `origin/main` avait avancé entre-temps (commit `chore: add precommit configuration`, absent en local suite aux `reset --soft` successifs).

Diagnostic :
```bash
git fetch origin
git log --oneline --all --graph -10
```

Résolution en cours : rebase du commit local par-dessus `origin/main` pour obtenir un historique linéaire, avant de repush :
```bash
git rebase origin/main
git push
```

