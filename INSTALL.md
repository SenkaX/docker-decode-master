# Instructions d'installation et d'utilisation

## Architecture du projet

Ce projet est organisé avec **2 fichiers docker-compose séparés** :

1. **docker-compose.db.yaml** : Gère la base de données PostgreSQL
2. **docker-compose.app.yaml** : Gère l'application Symfony et Adminer

Les deux utilisent un réseau Docker partagé (`app-network`) pour communiquer.

## Images Docker customisées (Alpine)

- ✅ **Symfony** : Dockerfile (basé sur FrankenPHP Alpine)
- ✅ **PostgreSQL** : Dockerfile.postgres (basé sur postgres:16-alpine)
- ✅ **Adminer** : Dockerfile.adminer (basé sur php:8.4-fpm-alpine)
- ✅ **Composer** : Dockerfile.composer (basé sur php:8.4-cli-alpine)

## Prérequis

- Docker et Docker Compose v2.10+
- Fichier `.env.local` avec les variables d'environnement PostgreSQL

## Installation

### 1. Créer le fichier .env.local

```bash
cat > .env.local << EOF
POSTGRES_DB=app
POSTGRES_PASSWORD=SecurePassword123
POSTGRES_USER=app

DATABASE_URL="postgresql://app:SecurePassword123@database:5432/app?serverVersion=16&charset=utf8"
EOF
```

### 2. Démarrer la base de données

```bash
# Construction et démarrage de PostgreSQL
docker compose -f docker-compose.db.yaml build
docker compose -f docker-compose.db.yaml up -d

# Vérifier que la base de données est démarrée
docker compose -f docker-compose.db.yaml ps
```

### 3. Démarrer l'application

```bash
# Construction et démarrage de Symfony + Adminer
docker compose -f docker-compose.app.yaml build
docker compose -f docker-compose.app.yaml up -d

# Exécuter les migrations
docker compose -f docker-compose.app.yaml exec php php bin/console doctrine:migrations:migrate --no-interaction
```

## Utilisation avec le Makefile

Pour simplifier, utilisez les commandes du Makefile :

```bash
# Démarrer tout le projet
make start-all

# Arrêter tout le projet
make stop-all

# Voir les logs
make logs-app
make logs-db

# Accéder au shell PHP
make sh

# Exécuter les migrations
make migrate
```

## Accès aux services

- **Application** : https://localhost (acceptez le certificat auto-signé)
- **Adminer** : http://localhost:8081
- **API REST** : https://localhost/api/todos
- **PostgreSQL** : localhost:5433 (host:port externe)

### Connexion Adminer

- Système : PostgreSQL
- Serveur : database
- Utilisateur : app
- Mot de passe : SecurePassword123
- Base de données : app

## Fonctionnalités de l'application

- ✅ Créer des todos
- ✅ Marquer comme terminé/non terminé
- ✅ Supprimer des todos
- ✅ Effacer tous les todos terminés
- ✅ API REST complète avec API Platform

## Arrêt du projet

```bash
# Arrêter l'application
docker compose -f docker-compose.app.yaml down

# Arrêter la base de données
docker compose -f docker-compose.db.yaml down

# Ou via le Makefile
make stop-all
```

## Nettoyage complet

```bash
# Supprimer tous les conteneurs, réseaux et volumes
docker compose -f docker-compose.app.yaml down -v
docker compose -f docker-compose.db.yaml down -v
```

## Structure des Dockerfiles

### Dockerfile.postgres
Base Alpine avec PostgreSQL 16, variables d'environnement personnalisées et healthcheck.

### Dockerfile.adminer
Base Alpine avec PHP 8.4-FPM, support PostgreSQL, téléchargement d'Adminer.

### Dockerfile.composer
Base Alpine avec PHP 8.4-CLI et Composer pour la gestion des dépendances.

### Dockerfile (Symfony)
FrankenPHP sur Alpine avec PHP 8.4, support PostgreSQL, Composer intégré.
