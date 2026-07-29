# Mini-writeup — Exercices pratiques (Modules 1, 2, 3)

## Module 1 — Le piege `set -e`

### Commande
```bash
bash -c '
set -e
if grep "xyz" /etc/hostname; then
  echo "trouve"
else
  echo "pas trouve"
fi
echo "le script continue malgre grep en echec"
'
```

### Resultat
### Explication
`set -e` est cense arreter un script des qu'une commande echoue (code de retour different de 0). Ici, `grep "xyz" /etc/hostname` echoue car le motif n'existe pas dans le fichier — pourtant le script continue normalement.

La raison : `set -e` ne se declenche **pas** quand la commande fait partie d'un `if`, d'un `while`, ou d'une liste `&&`/`||`. C'est un comportement documente et volontaire (sinon `if grep ...` serait inutilisable), mais il surprend souvent en pratique. Pour les cas critiques ou l'echec doit vraiment arreter le script, il faut verifier explicitement avec `if ! commande; then exit 1; fi`.

---

## Module 2 — Signer un commit avec une cle SSH

### Commandes
```bash
# Configuration du nom (corrige un placeholder par defaut, piege documente dans le cours)
git config --global user.name "Yoel Maincent"

# Generation d'une cle dediee a la signature
ssh-keygen -t ed25519 -C "ymaincent-signing" -f ~/.ssh/id_ed25519_signing -N ""

# Configuration de Git pour signer avec SSH
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519_signing.pub
git config --global commit.gpgsign true

# Fichier de signataires de confiance (verification locale)
echo "$(git config user.email) $(cat ~/.ssh/id_ed25519_signing.pub)" >> ~/.git-allowed-signers
git config --global gpg.ssh.allowedSignersFile ~/.git-allowed-signers

# Test
git commit --allow-empty -m "test: commit signe"
git log --show-signature -1
```

### Resultat
### Explication
Par defaut, l'auteur d'un commit Git (`user.name`/`user.email`) est du texte libre non authentifie : n'importe qui peut usurper une identite en configurant simplement ces champs. La signature SSH transforme ce champ en preuve cryptographique : elle garantit que le detenteur d'une cle privee precise a bien produit ce commit.

Point important : la signature prouve l'origine du commit, mais ne prouve ni que son contenu est correct, ni que l'auteur etait autorise a faire ce changement. C'est un maillon d'une chaine de securite (signature + revue + CI), jamais suffisant seul.

Pour que le badge "Verified" apparaisse sur GitHub, la cle publique doit etre declaree explicitement comme **Signing Key** (distincte d'une cle d'authentification classique utilisee pour push/pull).

---

## Module 3 — Expression `for` en HCL

### Commande
```bash
terraform console
> [for i in range(3) : "sous-reseau-${i}"]
```

### Resultat
### Explication
`terraform console` ouvre un bac a sable interactif pour tester des expressions HCL sans toucher a une vraie infrastructure. L'expression `for` genere une liste en appliquant une transformation a chaque element d'une sequence — ici, `range(3)` produit les entiers 0, 1, 2, et chacun est transforme en une chaine `"sous-reseau-N"`.

Ce type d'expression est la base du fonctionnement de `for_each` : au lieu de creer des ressources en dur une par une, on peut generer dynamiquement leurs noms ou leurs cles a partir d'une liste ou d'un ensemble, ce qui rend le code reutilisable et adaptable a differentes tailles d'infrastructure sans dupliquer de blocs `resource`.
