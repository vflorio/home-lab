#!/usr/bin/bash
set -e

PATH_DATA=/mnt/nfs/ssd-0/homelab-data

# Gateway
mkdir -p $PATH_DATA/gateway/{authentik/{certs,media,templates},crowdsec,headscale,headplane,valkey}

# Management
mkdir -p $PATH_DATA/management/{grafana,prometheus,portainer,homepage,semaphore,vaultwarden}

# Media
mkdir -p $PATH_DATA/media/{jellyfin,emby,navidrome,qbittorrent,sabnzbd,prowlarr,sonarr,radarr,lidarr,bazarr,unpackerr,logs,tdarr}
# *arr downloads + library on the same export so imports are hardlinks
mkdir -p $PATH_DATA/media/downloads/torrents/{tv,movies,music} $PATH_DATA/media/downloads/usenet/{incomplete,complete/{tv,movies,music}} $PATH_DATA/media/library/{tv,movies,music}

# Dev 
mkdir -p $PATH_DATA/dev/{coder,gitea,container-registry,verdaccio}

# Cloud 
mkdir -p $PATH_DATA/cloud/{nextcloud,onlyoffice}
    

mkdir -p $PATH_DATA/{authentik/{certs,media,templates,database},bazarr,chromium,coder,container-registry,crowdsec/data,filebot,gitea,gluetun,grafana,headplane/data,headscale/data,heimdall,homarr/{configs,data,icons},homepage,huntarr,jellyfin,jellyseerr,lidarr,logs/{unpackerr,traefik},mylar,plex,portainer,postgresql,prometheus,prowlarr,qbittorrent,radarr,readarr,sabnzbd,sonarr,tailscale,tdarr/{server,configs,logs},tdarr-node,traefik/letsencrypt,traefik-certs-dumper,unpackerr,valkey,verdaccio,whisparr}
mkdir -p $PATH_DATA/media/{anime,audio,books,comics,movies,music,photos,tv,xxx}
mkdir -p $PATH_DATA/usenet/{anime,audio,books,comics,complete,console,incomplete,movies,music,prowlarr,software,tv,xxx}
mkdir -p $PATH_DATA/torrents/{anime,audio,books,comics,complete,console,incomplete,movies,music,prowlarr,software,tv,xxx}
mkdir -p $PATH_DATA/watch
mkdir -p $PATH_DATA/filebot/{input,output}