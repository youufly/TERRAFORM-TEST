# TP1 — Un dépôt IaC sain, de bout en bout (Module 2)

## Ce qui a été réalisé

### Partie A — Initialisation
- `.gitattributes` : normalisation des fins de ligne (LF), regles specifiques par type de fichier
- `.editorconfig` : coherence d'indentation entre editeurs, tabulations forcees pour les Makefile
- `README.md` : present a la racine du depot
- `Makefile` : cibles `help` (auto-documentee), `hello`, `build`, `clean`, avec `.PHONY` correct
- Plusieurs commits distincts realises au fil du projet (feat, chore, refactor), bien que non regroupes en exactement 3 commits comme demande dans l'enonce strict

### Partie B — Garde-fous
- `.pre-commit-config.yaml` installe avec les hooks de base : `trailing-whitespace`, `end-of-file-fixer`, `check-yaml`
- Limite identifiee : les hooks `gitleaks` et `detect-private-key` n'ont pas ete ajoutes a la configuration au moment de l'incident (voir Partie C)

### Partie C — Incident reel de secret expose
Plutot que de simuler une fuite avec la fausse cle d'exemple AWS (`AKIAIOSFODNN7EXAMPLE`), une **vraie fuite accidentelle** s'est produite en debut de projet :

1. Un fichier `config/app.env.example` a ete cree par copie directe d'un `config/app.env` contenant de vraies credentials AWS temporaires (session STS, prefixe `ASIA`)
2. `git commit` puis `git push` ont ete tentes
3. **GitHub Push Protection a bloque le push** (`GH013`), detectant une Access Key ID, une Secret Access Key et un Session Token AWS
4. Reaction : annulation du commit local (`git reset --soft HEAD~1`), nettoyage complet du fichier (remplacement par des placeholders generiques), nouveau commit propre, push reussi

Cet incident illustre exactement le scenario prevu par l'exercice, en conditions reelles :
- Le hook `pre-commit` local n'a rien detecte (car `gitleaks` n'etait pas configure) — seule la protection cote serveur GitHub a intercepte la fuite
- Cela demontre concretement le principe du cours : **les hooks locaux ne sont pas un controle de securite fiable**, seule la verification cote serveur (ou en CI) protege reellement

### Partie D — Signature et protection de branche
Non realisee dans ce projet : pas de signature SSH des commits, pas de regle de protection sur la branche `main` (pas de revue obligatoire, pas d'interdiction du push direct).

## Reponses aux questions du livrable

**1. Pourquoi `--no-verify` fonctionne-t-il, et quelle est la seule parade reellement efficace ?**
`--no-verify` fonctionne car les hooks pre-commit s'executent uniquement sur le poste du developpeur, avant le commit local — rien n'empeche l'utilisateur de sauter cette etape avec cette option. La seule parade fiable est de rejouer les memes verifications cote serveur (CI/CD), combinee a une protection de branche qui rend leur succes obligatoire pour fusionner. C'est exactement ce qui a ete verifie dans cet incident : le hook local n'a rien vu, seule la protection GitHub cote serveur a bloque le secret.

**2. Le secret etait-il, a un moment, present sur le serveur distant ?**
Non — GitHub a bloque le push **avant** que le commit contenant le secret n'atteigne le depot distant (`origin/main`). Le commit fautif est reste uniquement local. Si le secret avait ete reellement present sur le serveur, la premiere action aurait du etre de **revoquer immediatement la cle chez AWS** (avant toute reecriture d'historique), car une cle exposee doit etre consideree comme compromise des l'instant de la publication.

**3. En quoi la mutabilite des tags Git explique-t-elle l'incident tj-actions/changed-files ?**
Un tag Git est un pointeur nomme mais mutable : rien n'empeche de le deplacer vers un autre commit avec `git tag -f` puis un push force. Dans l'incident tj-actions/changed-files (mars 2025), l'attaquant a compromis le jeton du bot du projet et reecrit tous les tags de version (`v1` a `v45`) pour qu'ils pointent vers un commit malveillant unique. Les utilisateurs qui referencaient l'action par tag (`@v45`) ont alors execute du code malveillant sans le savoir, car le nom du tag n'avait pas change — seul le commit qu'il designait avait ete substitue. Seul l'epinglage par empreinte de commit complete (SHA) aurait empeche cette substitution.

**4. Trois elements du depot relevant de la gestion de configuration au sens ITIL**
- Le fichier `.gitattributes` et `.editorconfig` : ce sont des elements de configuration (CI) qui garantissent un comportement identique du depot pour tous les contributeurs
- Le fichier `.pre-commit-config.yaml` : element de configuration definissant les controles appliques a chaque changement avant integration
- Le code Terraform (`envs/dev-aws/*.tf`) : constitue lui-meme la CMDB executable du projet — la description declarative de l'infrastructure fait foi, contrairement a une CMDB traditionnelle alimentee manuellement
