#!/bin/bash

# Création du dossier de travail
mkdir -p ~/glpi && cd ~/glpi

# Mise à jour et installation de Docker si nécessaire
sudo apt update && sudo apt install -y docker.io docker-compose-plugin

# Lancement des services définis dans le YAML
sudo docker compose up -d

# Configuration du pare-feu
sudo ufw allow 80/tcp
sudo ufw allow 22/tcp
sudo ufw allow 2222/tcp
sudo ufw --force enable

echo "Déploiement terminé !"
