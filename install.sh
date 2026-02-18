#!/bin/bash
set -e  # Le script s'arrête immédiatement si une commande échoue

# =================================================================
# AUTOMATISATION COMPLÈTE GLPI - DEBIAN VIERGE
# =================================================================

# 1. VÉRIFICATION ROOT
if [ "$EUID" -ne 0 ]; then
  echo "❌ ERREUR : Ce script doit être lancé en root. Tapez 'su -' d'abord."
  exit 1
fi

echo "--- [1/6] Mise à jour initiale et installation des pré-requis ---"
# On met à jour la liste des paquets existants
apt-get update -y

# On installe les outils indispensables qui manquent souvent sur une Debian vierge
# ca-certificates : pour parler aux sites en HTTPS
# lsb-release : pour savoir quelle version de Debian on utilise (évite l'erreur "mal formée")
# curl/gnupg : pour télécharger la clé Docker
apt-get install -y ca-certificates curl gnupg lsb-release ufw git

echo "--- [2/6] Préparation du dépôt Docker ---"
# Création du dossier pour les clés si inexistant
mkdir -m 0755 -p /etc/apt/keyrings

# Téléchargement de la clé GPG officielle
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
chmod a+r /etc/apt/keyrings/docker.gpg

# Ajout du dépôt DANS UN FORMAT PROPRE (Corrige l'erreur "mal formée")
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "--- [3/6] Installation du Moteur Docker ---"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# On active Docker au démarrage
systemctl enable --now docker

echo "--- [4/6] Vérification des fichiers de déploiement ---"
# On s'assure qu'on est dans le bon dossier (celui du script)
cd "$(dirname "$0")"

# Vérification de présence des fichiers vitaux
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ ERREUR CRITIQUE : Le fichier 'docker-compose.yml' est absent !"
    echo "Assurez-vous qu'il est dans le même dossier que ce script."
    exit 1
fi

if [ ! -f "nginx.conf" ]; then
    echo "⚠️ ATTENTION : 'nginx.conf' introuvable. Nginx risque de planter si le volume est monté."
fi

echo "--- [5/6] Lancement des conteneurs ---"
# On utilise la nouvelle commande 'docker compose' (sans tiret)
docker compose up -d --remove-orphans

echo "--- [6/6] Sécurisation Pare-feu (UFW) ---"
# On configure le pare-feu pour ne pas s'enfermer dehors
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp      # SSH Système
ufw allow 2222/tcp    # SSH Conteneur GLPI
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw --force enable

echo ""
echo "✅ INSTALLATION TERMINÉE AVEC SUCCÈS !"
echo "-------------------------------------"
echo "Machine : $(hostname -I | awk '{print $1}')"
echo "Statut des conteneurs :"
docker ps
