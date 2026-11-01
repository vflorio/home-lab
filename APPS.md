 (gateway server)
 
- Traefik (Reverse Proxy + TLS)
- Authentik (Authentication)
- Crowdsec (Security)
- Tailscale (VPN subnet router, unico accesso da remoto)
- Certificates Management

 (management server)

- Portainer (Container Management)
- Prometheus (Metrics)
- Grafana (Dashboards)
- Guacamole (Remote Desktop)
- PostgreSQL (Shared Database)
- Valkey/Redis (Cache)
- Homepage/Heimdall/Homarr (Dashboards)
- Semaphore (Ansible UI)
- [TODO] VaultWarden (Password manager)

(media server)

- Jellyfin/Emby (Media Streaming)
- Sonarr/Radarr/Lidarr (Automation)
- Prowlarr (Indexer Management)
- qBittorrent/SABnzbd (Download)
- Jellyseerr (Request Management)
- Bazarr (Subtitles)
- Tdarr (Transcoding)
- Unpackerr (Processing)
- Flaresolverr (Cloudflare Bypass)

(dev server)
- Gitea (Git repository server)
- Container Registry (Docker Registry)
- Verdaccio (Private NPM Store)
- Coder (VS Code nel browser)
- Excalidraw (Sketching)
- Drawio (Sketching)

(cloud server)
- Nextcloud (Cloud storage)
- OnlyOffice (Office suite)
- Immich (Photo management)


TODO:
- Guacamole RDP (cambio pass admin etc)
- Servarr stack + Navidrome
- Aggiornamenti: apt su tutti i server e immagini, Authentik a step.
- Terraform di Proxmox: import dello state per le 5 VM.
