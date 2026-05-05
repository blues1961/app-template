.DEFAULT_GOAL := help

SCRIPTS_DIR := ./scripts

.PHONY: help init dev prod up down restart rebuild logs ps check

help:
	@printf '%s\n' \
		'Usage: make <target>' \
		'' \
		'Cibles disponibles :' \
		'  help      Affiche cette aide' \
		'  init      Initialise le projet en développement (scripts/init.sh dev)' \
		'  dev       Bascule l’environnement actif vers .env.dev' \
		'  prod      Bascule l’environnement actif vers .env.prod' \
		'  up        Démarre les services de l’environnement actif' \
		'  down      Arrête les services de l’environnement actif' \
		'  restart   Redémarre les services de l’environnement actif' \
		'  rebuild   Reconstruit les images (optionnel : make rebuild SERVICE=backend)' \
		'  logs      Affiche les logs (optionnel : make logs SERVICE=backend)' \
		'  ps        Affiche l’état des services de l’environnement actif' \
		'  check     Vérifie les invariants du template'

init:
	$(SCRIPTS_DIR)/init.sh dev

dev:
	$(SCRIPTS_DIR)/env-switch.sh dev

prod:
	$(SCRIPTS_DIR)/env-switch.sh prod

up:
	$(SCRIPTS_DIR)/up.sh

down:
	$(SCRIPTS_DIR)/down.sh

restart:
	$(SCRIPTS_DIR)/restart.sh

rebuild:
	$(SCRIPTS_DIR)/rebuild.sh $(SERVICE)

logs:
	$(SCRIPTS_DIR)/logs.sh $(SERVICE)

ps:
	$(SCRIPTS_DIR)/ps.sh

check:
	$(SCRIPTS_DIR)/check-invariants.sh
