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
