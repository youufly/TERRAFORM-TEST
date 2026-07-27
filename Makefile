SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

.DEFAULT_GOAL := help

help:
    @echo "Commandes disponibles:"
    @echo "  make lint"
    @echo "  make secrets"
    @echo "  make clean"

lint:
    pre-commit run --all-files

secrets:
    gitleaks detect --source . --verbose

clean:
    rm -rf .terraform
    rm -f *.tfstate
