SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
MAKEFLAGS += --warn-undefined-variables --no-print-directory

# ---- Parametres (surchargeables : make plan CIDR_ADMIN=1.2.3.4/32) ----------
TF_DIR := envs/dev-aws
ANSIBLE_DIR := ansible
TF_PLAN := dev.tfplan
INV_FILE := $(ANSIBLE_DIR)/inventory.ini
SSH_KEY := tpiac-dev-key.pem

# CIDR_ADMIN : si defini, surcharge l'IP autorisee en SSH (utilise par la CI)
CIDR_ADMIN ?=
TF_VARS := $(if $(CIDR_ADMIN),-var=cidr_admin=$(CIDR_ADMIN),)

.PHONY: help hello build clean \
        fmt tflint trivy check \
        init plan apply destroy \
        inventory configure deploy test

# ---- Aide --------------------------------------------------------------------
help: ## Affiche cette aide
	@echo ""
	@echo " Cibles disponibles :"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'
	@echo ""

hello: ## Affiche un message avec l'utilisateur systeme
	@echo "Bonjour, ceci est mon premier Makefile"
	@echo "Utilisateur systeme : $$USER"

build: ## Cree un dossier out/ avec un fichier version.txt date
	mkdir -p out
	date > out/version.txt
	@echo "✓ out/version.txt cree"

clean: ## Nettoie les fichiers temporaires
	rm -rf out $(TF_DIR)/.terraform $(TF_DIR)/*.tfplan $(INV_FILE)
	@echo "✓ nettoye"

# ---- Qualite et securite (etape 1 du pipeline) --------------------------------
fmt: ## Verifie le formatage du code Terraform
	terraform -chdir=$(TF_DIR) fmt -check -recursive

tflint: ## Analyse la qualite du code Terraform
	tflint --chdir=$(TF_DIR) --init
	tflint --chdir=$(TF_DIR)

trivy: ## Recherche les mauvaises configurations de securite
	trivy config --exit-code 1 --severity HIGH,CRITICAL --ignorefile $(TF_DIR)/.trivyignore $(TF_DIR)

check: fmt tflint trivy ## Chaine complete de validation (etape 1)
	@echo "✓ Toutes les validations sont passees."

# ---- Cycle Terraform (etape 2) -------------------------------------------------
init: ## Initialise Terraform
	terraform -chdir=$(TF_DIR) init

plan: init ## Calcule le plan Terraform
	terraform -chdir=$(TF_DIR) plan $(TF_VARS) -out=$(TF_PLAN)

apply: plan ## Applique le plan Terraform
	terraform -chdir=$(TF_DIR) apply "$(TF_PLAN)"

destroy: ## Detruit l'infrastructure AWS
	terraform -chdir=$(TF_DIR) destroy $(TF_VARS) -auto-approve

# ---- Pont Terraform -> Ansible (etape 3) ---------------------------------------
inventory: ## Genere l'inventaire Ansible depuis terraform output
	@IP=$$(terraform -chdir=$(TF_DIR) output -raw url_publique | sed -e 's|http://||'); \
	printf '[web]\n%s ansible_user=ubuntu ansible_ssh_private_key_file=%s/$(SSH_KEY) ansible_ssh_common_args=%s\n' \
		"$$IP" "$(TF_DIR)" "'-o StrictHostKeyChecking=no'" > $(INV_FILE); \
	echo "✓ Inventaire genere : $(INV_FILE) -> $$IP"

# ---- Configuration Ansible (etape 4) -------------------------------------------
configure: inventory ## Applique le playbook Ansible sur la machine
	ansible-playbook -i $(INV_FILE) $(ANSIBLE_DIR)/playbook.yml

# ---- Enchainement complet -------------------------------------------------------
deploy: check apply configure ## Pipeline complet : validations -> EC2 -> Ansible
	@echo "✓ Deploiement termine."

test: check ## Alias de check (compatibilite)
