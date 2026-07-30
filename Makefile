SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
MAKEFLAGS += --warn-undefined-variables --no-print-directory

TF_DIR := envs/dev-aws
ANSIBLE_DIR := ansible

.PHONY: help hello build clean \
        tf-init tf-fmt tf-validate tf-plan tf-apply \
        provision deploy destroy test

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

clean: ## Supprime le dossier out/ sans erreur s'il n'existe pas
	rm -rf out
	@echo "✓ nettoye"

tf-init: ## Initialise Terraform
	cd $(TF_DIR) && terraform init

tf-fmt: ## Formate le code Terraform
	cd $(TF_DIR) && terraform fmt -recursive

tf-validate: tf-init ## Valide la syntaxe Terraform
	cd $(TF_DIR) && terraform validate

tf-plan: tf-validate ## Calcule le plan Terraform
	cd $(TF_DIR) && terraform plan -out=dev.tfplan

tf-apply: ## Applique le plan Terraform precedemment calcule
	cd $(TF_DIR) && terraform apply "dev.tfplan"

provision: ## Provisionne l'instance avec Ansible (nginx)
	cd $(ANSIBLE_DIR) && ./inventory.sh > inventory.ini
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini playbook.yml

deploy: tf-init tf-plan tf-apply provision ## Deploie l'infra AWS puis la configure avec Ansible

test: tf-fmt tf-validate ## Chaine de verification complete (fmt + validate)
	@echo "✓ Verifications Terraform passees."

destroy: ## Detruit l'infrastructure AWS
	cd $(TF_DIR) && terraform destroy
