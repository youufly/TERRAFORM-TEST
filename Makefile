SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
MAKEFLAGS += --warn-undefined-variables --no-print-directory

.PHONY: help hello build clean

help: ## Affiche cette aide
	@echo ""
	@echo " Cibles disponibles :"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'
	@echo ""

hello: ## Affiche un message avec l'utilisateur système
	@echo "Bonjour, ceci est mon premier Makefile"
	@echo "Utilisateur système : $$USER"

build: ## Crée un dossier out/ avec un fichier version.txt daté
	mkdir -p out
	date > out/version.txt
	@echo "✓ out/version.txt créé"

clean: ## Supprime le dossier out/ sans erreur s'il n'existe pas
	rm -rf out
	@echo "✓ nettoyé"

.PHONY: tf-init tf-plan tf-apply provision deploy destroy

tf-init: ## Initialise Terraform pour dev-aws
	cd envs/dev-aws && terraform init

tf-plan: ## Calcule le plan Terraform pour dev-aws
	cd envs/dev-aws && terraform plan -out=dev.tfplan

tf-apply: ## Applique le plan Terraform pour dev-aws
	cd envs/dev-aws && terraform apply "dev.tfplan"

provision: ## Provisionne l'instance avec Ansible (nginx)
	cd ansible && ./inventory.sh > inventory.ini
	cd ansible && ansible-playbook -i inventory.ini playbook.yml

deploy: tf-init tf-plan tf-apply provision ## Deploie l'infra AWS puis la configure avec Ansible

destroy: ## Detruit l'infrastructure AWS
	cd envs/dev-aws && terraform destroy
