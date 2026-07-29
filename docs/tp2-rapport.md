# TP2 — Déploiement multi-cloud sécurisé (Module 3)

## Ce qui a été réalisé

### Partie A — Socle et état distant
Non conforme au TP original : la creation d'un bucket S3 pour un backend distant chiffre et versionne a echoue (`AccessDenied` sur `s3:CreateBucket`), le compte AWS Academy utilise (role `voclabs`) etant volontairement restreint sur les actions S3 et IAM.

**Adaptation retenue** : backend Terraform local (`terraform.tfstate` sur disque, exclu du depot Git via `.gitignore`). Cette limitation est documentee ici plutot que masquee.

### Partie B — Deploiement AWS
Realise integralement :
- VPC et sous-reseau existants reutilises (creation de VPC egalement bloquee par les permissions du lab)
- Security group : HTTP ouvert (`0.0.0.0/0`), SSH restreint a l'IP publique de l'administrateur (`/32`)
- Instance EC2 `t2.micro`, AMI Ubuntu 24.04, avec :
  - `http_tokens = "required"` (IMDSv2 impose)
  - Disque racine chiffre (`encrypted = true`)
  - nginx installe via `user_data`
- Sequence `terraform init` → `plan -out` → `apply <fichier>` respectee
- Verification fonctionnelle : `curl` sur l'IP publique renvoie le contenu attendu (HTTP 200)

### Partie C — Deploiement Azure
**Tente puis abandonne.** Un abonnement Azure for Students actif a ete utilise (tenant Ecole IPSSI). Le code Terraform equivalent (VNet, sous-reseau, NSG, IP publique, VM Linux) a ete ecrit et le plan valide sans erreur.

Blocages rencontres lors de l'`apply` :
1. Region `westeurope` refusee par une politique de l'abonnement (`RequestDisallowedByAzure`, restriction de regions autorisees)
2. Apres correction vers `francecentral` : trois tailles de VM differentes (`Standard_B1s`, `Standard_B1ms`, `Standard_B2s`) refusees successivement pour cause de **rupture de capacite** (`SkuNotAvailable ... Capacity Restrictions`) — probleme cote datacenter Microsoft, independant de la configuration

Faute de temps pour multiplier les tentatives de region/taille, le deploiement Azure a ete abandonne. Toutes les ressources partiellement creees (resource group, VNet, NSG, IP publique) ont ete detruites proprement avec `terraform destroy` avant l'abandon — aucune ressource Azure ne reste active ni facturee.

### Partie D — Derive de configuration
Realisee sur AWS :
1. Modification manuelle du security group via AWS CLI pour ouvrir le port SSH a `0.0.0.0/0` (simulation d'une intervention non maitrisee)
2. `terraform plan` a immediatement detecte l'ecart entre l'etat declare (SSH restreint) et la realite (SSH ouvert), proposant de supprimer la regle non desiree
3. `terraform apply` a reconcilie l'infrastructure avec le code, supprimant la regle indesirable

## Reponses au livrable

**1. Plan de la derive et interpretation**
Le plan a affiche `~ update in-place` sur `aws_security_group.web`, avec suppression (`-`) de la regle ingress ouverte a `0.0.0.0/0` sur le port 22. Interpretation : Terraform ne fait pas confiance a l'etat du monde reel, il compare systematiquement code declare, etat connu et realite observee — toute action manuelle en dehors du pipeline est detectee et peut etre annulee automatiquement au prochain apply.

**2. Trois informations sensibles trouvees dans le tfstate**
En inspectant `terraform.tfstate` localement (`jq` sur les attributs de `aws_instance.web`) :
- L'IP publique et l'IP privee de l'instance
- L'identifiant de l'AMI utilisee
- Le script `user_data` complet en clair (ici sans secret, mais demontre que tout mot de passe qui y serait inscrit serait visible)

Aucun chiffrement de l'etat n'a ete mis en place (backend local, pas de chiffrement applicatif de type OpenTofu) : le fichier est protege uniquement par les permissions du systeme de fichiers local et son exclusion du depot Git.

**3. Tableau comparatif AWS / Azure**

| Ressource | AWS | Azure |
|---|---|---|
| Reseau | VPC existant reutilise | VNet cree par Terraform (avant abandon) |
| Sous-reseau | Subnet existant reutilise | Subnet cree par Terraform |
| Pare-feu | Security Group | Network Security Group (NSG) |
| IP publique | Attribuee automatiquement a l'instance | Ressource distincte (`azurerm_public_ip`) |
| Calcul | `aws_instance` (EC2) | `azurerm_linux_virtual_machine` |
| Authentification | Cle SSH existante (non geree ici) | Cle SSH generee par Terraform (`tls_private_key`) |
| Resultat | Deploye et fonctionnel | Non deploye (contrainte de capacite) |

**4. IMDSv2 et l'affaire Capital One (2019), en cinq lignes**
`http_tokens = "required"` aurait empeche l'attaquant d'obtenir un jeton de metadonnees via une simple requete SSRF passive (GET sans en-tete), puisque IMDSv2 exige une requete PUT prealable avec un en-tete personnalise, injoignable par une primitive SSRF classique. Cela n'aurait cependant rien change au fait que le role IAM attache au WAF disposait de permissions bien trop larges (`s3:ListAllMyBuckets` et acces a ~700 buckets) : IMDSv2 protege l'acces au jeton, pas l'etendue des droits qu'il porte. De plus, IMDSv2 n'existait pas encore en mars 2019 (annonce en novembre 2019) : la seule defense disponible a l'epoque etait le moindre privilege IAM, absent ici. La combinaison des deux (moindre privilege + IMDSv2) reste la seule protection robuste contre ce type d'attaque.

**5. Capture de facturation apres destroy**
Non fournie dans ce rapport (l'instance AWS reste intentionnellement active a la demande, pour demonstration ulterieure). A fournir au moment de la destruction finale du TP.

## Limitations generales de l'environnement

Le compte utilise (AWS Academy / voclabs) impose des restrictions specifiques non documentees dans le cours generique :
- Region AWS forcee a `us-east-1` (echecs sur `eu-west-3`)
- Creation de bucket S3 et de VPC interdites
- Abonnement Azure for Students soumis a des quotas de capacite variables selon la region et l'heure

Ces contraintes ont necessite des adaptations documentees a chaque etape plutot qu'un suivi litteral du TP, sans en compromettre la comprehension des concepts (declaratif, plan/apply, derive, etat, IMDSv2).
