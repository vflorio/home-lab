# HomeLab Infrastructure

Single Proxmox VE node (**silicon**) hosting infrastructure VMs (DNS, NAS, firewall) and five Docker application servers. Everything lives under the internal zone `intranet.vflorio.com`, nothing is exposed to the internet, and remote access goes through Tailscale only.

- [Network](#network)
- [Physical devices](#physical-devices)
- [Virtual machines](#virtual-machines)
- [Infrastructure services](#infrastructure-services)
- [Storage](#storage)
- [Applications](#applications)

## Network

### Address plan (192.168.1.0/24)

| Range | Usage |
|---|---|
| 192.168.1.1-32 | Primary physical devices |
| 192.168.1.33-40 | ActivaStick mini PCs |
| 192.168.1.150-152 | Infrastructure VMs (DNS, NAS, firewall) |
| 192.168.1.190-194 | Application servers (Docker VMs: gateway, management, media, dev, cloud) |
| 192.168.1.254 | Iliad Box gateway |

### DNS

- **Zone**: `intranet.vflorio.com`, authoritative on Bind9 (192.168.1.150), managed via Terraform (TSIG).
- **Host records**: one per device / VM (see the tables below).
- **App records**: each application server has a wildcard (`*.<server>.intranet.vflorio.com`) pointing to the gateway (192.168.1.190), where Traefik routes to the right backend.
- **Cloudflare**: used only for Let's Encrypt DNS-01, no app records (see [dns/cloudflare/dns.tf](dns/cloudflare/dns.tf)).

### Exposure & remote access

- No port forwards and no public app records.
- Remote access via **Tailscale** only: subnet router for 192.168.1.0/24 and split DNS `intranet.vflorio.com` → 192.168.1.150.
- All web UIs are served over HTTPS by Traefik, with CrowdSec on every router and Authentik on every router except apps whose native clients can't pass forward auth (Vaultwarden, Navidrome: own login).

## Physical devices

| IP | DNS name | Alias | Description |
|---|---|---|---|
| 192.168.1.1 | server | silicon | Main physical server (Proxmox VE) |
| 192.168.1.2 | workstation | carbon | Main workstation |
| 192.168.1.3 | macmini | nitrogen | Mac Mini |
| 192.168.1.4 | tablet-android | boron | Android tablet |
| 192.168.1.5 | smartphone-ios | phosphorus | iPhone |
| 192.168.1.6 | tv-hisense | sulfur | Hisense Smart TV |
| 192.168.1.7 | tv-android | chlorine | Android Smart TV |
| 192.168.1.8 | laptop-discovery | argon | Discovery laptop |
| 192.168.1.9 | laptop-kineton | neon | Kineton laptop |
| 192.168.1.10 | switch-2 | kripton | Nintendo Switch 2 |
| 192.168.1.254 | iliadbox | - | Router / default gateway |

### ActivaStick mini PCs

| IP | DNS name | Records |
|---|---|---|
| 192.168.1.33 | activastick-0 | `*.activastick-0` |
| 192.168.1.34 | activastick-1 | `*.activastick-1` |
| 192.168.1.35 | activastick-2 | `*.activastick-2` |
| 192.168.1.36 | activastick-3 | `*.activastick-3` |
| 192.168.1.37 | activastick-4 | `*.activastick-4` |
| 192.168.1.38 | activastick-5 | `*.activastick-5` |
| 192.168.1.39 | activastick-6 | `*.activastick-6` |
| 192.168.1.40 | activastick-7 | `*.activastick-7` |

## Virtual machines

All VMs run on Proxmox VE on silicon (1 TB NVMe).

### Infrastructure

| VM ID | Name | IP | DNS name | Role |
|---|---|---|---|---|
| 1010 | dns | 192.168.1.150 | dns | Bind9 DNS server |
| 1020 | nas | 192.168.1.151 | nas | NAS (OpenMediaVault) |
| 1030 | firewall | 192.168.1.152 | firewall | Firewall (OPNsense) |

### Application servers

| VM ID | Name | IP | DNS | Resources | Role |
|---|---|---|---|---|---|
| 3100 | srv-gateway | 192.168.1.190 | gateway, `*.gateway` | 4 vCPU, 4 GB | Reverse proxy (Traefik), SSO, VPN, IDS |
| 3200 | srv-management | 192.168.1.191 | management, `*.management` → .190 | 4 vCPU, 4 GB | Dashboard, monitoring, management |
| 3300 | srv-media | 192.168.1.192 | media, `*.media` → .190 | 6 vCPU, 12 GB | Media streaming and downloads |
| 3400 | srv-dev | 192.168.1.193 | dev, `*.dev` → .190 | 8 vCPU, 16 GB | Development, Git, registries |
| 3500 | srv-cloud | 192.168.1.194 | cloud, `*.cloud` → .190 | 4 vCPU, 8 GB | Files, documents, photos |

## Infrastructure services

| Service | Description | URL |
|---|---|---|
| Proxmox VE | Hypervisor on silicon | https://192.168.1.1:8006 |
| Bind9 | Authoritative DNS for `intranet.vflorio.com` | 192.168.1.150:53 (`ns.intranet.vflorio.com`) |
| OpenMediaVault | NAS | http://192.168.1.151 |
| OPNsense | Firewall | https://192.168.1.152 |
| Iliadbox | Router / default gateway | http://192.168.1.254 |
| Cloudflare | DNS-01 for Let's Encrypt | https://dash.cloudflare.com |

## Storage

NFS shares exported by the NAS:

| Share | Type | Usage | Mount point |
|---|---|---|---|
| ssd-0 | SSD | App data, photos, relax, *arr downloads & library | `nas:/ssd-0` → `/mnt/nfs/ssd-0` |
| media-0 | SMR HDD (JBOD) | Media library | `nas:/media-0` → `/mnt/nfs/media-0` |
| media-1 | SMR HDD (JBOD) | Media library | `nas:/media-1` → `/mnt/nfs/media-1` |
| media-2 | SMR HDD (JBOD) | Media library | `nas:/media-2` → `/mnt/nfs/media-2` |

## Applications

Source of truth: [servers/management/homepage/services.yaml](servers/management/homepage/services.yaml).

URLs go through Traefik on the gateway (Let's Encrypt via Cloudflare DNS-01, LAN and tailnet only, CrowdSec + Authentik; Vaultwarden and Navidrome skip Authentik). The direct `ip:port` endpoints bypass Traefik/Authentik.

Every application server also runs **Traefik-kop** (publishes local routers to the gateway's Valkey); all except management run a **Portainer Agent** on `:9001`.

### Gateway — srv-gateway (192.168.1.190)

| App | Description | URL | Direct endpoint |
|---|---|---|---|
| Traefik | Reverse proxy & TLS | https://traefik.gateway.intranet.vflorio.com/dashboard/ | 192.168.1.190:8082 (metrics) |
| Authentik | SSO / forward auth | https://auth.gateway.intranet.vflorio.com | 192.168.1.190:6080 |
| Tailscale | VPN · subnet router · split DNS | https://login.tailscale.com/admin/machines | no inbound ports |
| CrowdSec | IDS + Traefik bouncer + AppSec WAF | - | 192.168.1.190:6060/metrics |

| Support service | Description | Endpoint |
|---|---|---|
| Authentik Worker | Authentik background tasks | - |
| PostgreSQL | Authentik DB | 192.168.1.190:5432 |
| Valkey | Authentik cache (db 0) · Traefik provider (db 1) | 192.168.1.190:6379 |

### Management — srv-management (192.168.1.191)

| App | Description | URL | Direct endpoint |
|---|---|---|---|
| Homepage | Homelab dashboard | https://home.management.intranet.vflorio.com | 192.168.1.191:3100 |
| Grafana | Metrics dashboards | https://grafana.management.intranet.vflorio.com | 192.168.1.191:3800 |
| Prometheus | Metrics collection | https://prometheus.management.intranet.vflorio.com | 127.0.0.1:9090 only |
| Portainer | Container management (all servers) | https://portainer.management.intranet.vflorio.com | 192.168.1.191:9000 |
| Guacamole | Remote desktop gateway | https://guacamole.management.intranet.vflorio.com | 192.168.1.191:9200 |
| Semaphore | Ansible UI | https://semaphore.management.intranet.vflorio.com | 192.168.1.191:3001 |
| Vaultwarden | Password manager (Bitwarden compatible, admin at `/admin`) | https://vaultwarden.management.intranet.vflorio.com | 192.168.1.191:8222 |

| Support service | Description | Endpoint |
|---|---|---|
| Guacd | Guacamole daemon | 192.168.1.191:4822 |
| PostgreSQL | Semaphore, Guacamole, Vaultwarden DB | 192.168.1.191:5432 |

### Media — srv-media (192.168.1.192)

| App | Description | URL | Direct endpoint |
|---|---|---|---|
| Jellyfin | Media server | https://jellyfin.media.intranet.vflorio.com | 192.168.1.192:8096 |
| Emby | Media server | https://emby.media.intranet.vflorio.com | 192.168.1.192:8097 |
| Navidrome | Music streaming (Subsonic API) | https://navidrome.media.intranet.vflorio.com | 192.168.1.192:4533 |
| Sonarr | TV series | https://sonarr.media.intranet.vflorio.com | 192.168.1.192:8989 |
| Radarr | Movies | https://radarr.media.intranet.vflorio.com | 192.168.1.192:7878 |
| Lidarr | Music | https://lidarr.media.intranet.vflorio.com | 192.168.1.192:8686 |
| Bazarr | Subtitles | https://bazarr.media.intranet.vflorio.com | 192.168.1.192:6767 |
| Prowlarr | Indexers | https://prowlarr.media.intranet.vflorio.com | 192.168.1.192:9696 |
| qBittorrent | Torrent client | https://qbittorrent.media.intranet.vflorio.com | 192.168.1.192:8200 |
| SABnzbd | Usenet client | https://sabnzbd.media.intranet.vflorio.com | 192.168.1.192:8100 |
| Tdarr | Transcoding | https://tdarr.media.intranet.vflorio.com | 192.168.1.192:8265 (UI), 192.168.1.192:8266 (server) |
| FlareSolverr | Cloudflare bypass for Prowlarr | https://flaresolverr.media.intranet.vflorio.com | 192.168.1.192:8191 |

| Support service | Description | Endpoint |
|---|---|---|
| Unpackerr | Archive extraction for *arr | 192.168.1.192:5656/metrics |
| Tdarr Node | Transcoding worker | - |

*arr layout (temporary, all on ssd-0 so imports are hardlinks; to be moved to the SMR disks after checking the I/O impact). Inside the *arr / download containers `/mnt/nfs` is mounted as `/media`:

| Path | Content |
|---|---|
| `/mnt/nfs/ssd-0/homelab-data/media/downloads/torrents/{tv,movies,music}` | qBittorrent, one category per *arr |
| `/mnt/nfs/ssd-0/homelab-data/media/downloads/usenet/{incomplete,complete/{tv,movies,music}}` | SABnzbd |
| `/mnt/nfs/ssd-0/homelab-data/media/library/{tv,movies,music}` | Sonarr / Radarr / Lidarr root folders; Jellyfin `/mnt/library`, Navidrome `/music` |

Indexers live in Prowlarr only (public ones, Cloudflare-protected via the `flaresolverr` tag) and are synced to Sonarr/Radarr/Lidarr. Quality profile `HD-1080p` prefers Italian audio (custom formats ITA +100, ENG +25). Bazarr: ITA+ENG subtitles, providers that need no account.

### Dev — srv-dev (192.168.1.193)

| App | Description | URL | Direct endpoint |
|---|---|---|---|
| Coder | Development environments | https://coder.dev.intranet.vflorio.com | 192.168.1.193:7080 |
| Gitea | Git server | https://git.dev.intranet.vflorio.com | 192.168.1.193:3000, SSH 192.168.1.193:2222 |
| Container Registry | Docker registry | https://container-registry.dev.intranet.vflorio.com | 192.168.1.193:5000 |
| Verdaccio | npm registry | https://npm.dev.intranet.vflorio.com | 192.168.1.193:4873 |
| Excalidraw | Quick sketches | https://excalidraw.dev.intranet.vflorio.com | 192.168.1.193:8043 |
| Draw.io | Diagrams | https://drawio.dev.intranet.vflorio.com | 192.168.1.193:8084 |

| Support service | Description | Endpoint |
|---|---|---|
| PostgreSQL | Coder, Gitea DB | Docker network only |

### Cloud — srv-cloud (192.168.1.194)

| App | Description | URL | Direct endpoint |
|---|---|---|---|
| Nextcloud | Cloud storage | https://nextcloud.cloud.intranet.vflorio.com | 192.168.1.194:8080 |
| OnlyOffice | Document server | https://onlyoffice.cloud.intranet.vflorio.com | 192.168.1.194:8081 |
| Immich | Photos & videos | https://immich.cloud.intranet.vflorio.com | 192.168.1.194:2283 |

| Support service | Description | Endpoint |
|---|---|---|
| PostgreSQL Nextcloud | Nextcloud DB | 192.168.1.194:5432 |
| PostgreSQL Immich | Immich DB (vectorchord) | Docker network only |
| Valkey | Nextcloud / Immich cache | 192.168.1.194:6379 |
