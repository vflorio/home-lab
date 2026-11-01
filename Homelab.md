
# HomeLab Infrastructure Documentation

## Network & Devices

### Devices

| Dispositivo | Alias | IP | Descrizione |
|---|---|---|---|
| server | silicon | 192.168.1.1 | Server fisico principale |
| workstation | carbon | 192.168.1.2 | Workstation principale |
| macmini | nitrogen | 192.168.1.3 | Mac Mini |
| tablet-android | boron | 192.168.1.4 | Tablet Android |
| smartphone-ios | phosphorus | 192.168.1.5 | iPhone |
| tv-hisense | sulfur | 192.168.1.6 | Smart TV |
| tv-android | chlorine | 192.168.1.7 | Smart TV |
| laptop-discovery | argon | 192.168.1.8 | Laptop Discovery |
| laptop-kineton | neon | 192.168.1.9 | Laptop Kineton |
| iliadbox | iliadbox | 192.168.1.254 | Gateway principale |

### Network

- **192.168.1.1-32**: Dispositivi fisici primari (range espanso)
- **192.168.1.33-40**: Mini PC ActivaStick
- **192.168.1.150-152**: Servizi di infrastruttura
- **192.168.1.190-194**: Server applicativi (VM Docker: gateway, management, media, dev, cloud)
- **192.168.1.254**: Gateway Iliad Box

### DNS Records

| IP | Nome DNS | Alias DNS | Categoria | Descrizione |
|---|---|---|---|---|
| **DISPOSITIVI FISICI** |
| 192.168.1.1 | server | silicon | Hardware | Server fisico principale |
| 192.168.1.2 | workstation | carbon | Hardware | Workstation principale |
| 192.168.1.3 | macmini | nitrogen | Hardware | Mac Mini |
| 192.168.1.4 | tablet-android | boron | Hardware | Tablet Android |
| 192.168.1.5 | smartphone-ios | phosphorus | Hardware | iPhone |
| 192.168.1.6 | tv-hisense | sulfur | Hardware | Smart TV Hisense |
| 192.168.1.7 | tv-android | chlorine | Hardware | Smart TV Android |
| 192.168.1.8 | laptop-discovery | argon | Hardware | Laptop Discovery |
| 192.168.1.9 | laptop-kineton | neon | Hardware | Laptop Kineton |
| 192.168.1.10 | switch-2 | kripton | Hardware | Laptop Kineton |
| 192.168.1.254 | iliadbox | - | Gateway | Gateway principale |
| **SERVIZI INFRASTRUTTURA** |
| 192.168.1.150 | dns | - | Infrastruttura | Server DNS Bind9 |
| 192.168.1.151 | nas | - | Infrastruttura | Network Attached Storage |
| 192.168.1.152 | firewall | - | Infrastruttura | Firewall/Gateway |
| **MINI PC ACTIVASTICK** |
| 192.168.1.33 | activastick-0 | - | ActivaStick | Mini PC #0 *.activastick-0 |
| 192.168.1.34 | activastick-1 | - | ActivaStick | Mini PC #1 *.activastick-1 |
| 192.168.1.35 | activastick-2 | - | ActivaStick | Mini PC #2 *.activastick-2 |
| 192.168.1.36 | activastick-3 | - | ActivaStick | Mini PC #3 *.activastick-3 |
| 192.168.1.37 | activastick-4 | - | ActivaStick | Mini PC #4 *.activastick-4 |
| 192.168.1.38 | activastick-5 | - | ActivaStick | Mini PC #5 *.activastick-5 |
| 192.168.1.39 | activastick-6 | - | ActivaStick | Mini PC #6 *.activastick-6 |
| 192.168.1.40 | activastick-7 | - | ActivaStick | Mini PC #7 *.activastick-7 |
| **SERVER APPLICATIVI** |
| 192.168.1.190 | gateway | *.gateway | Server | Reverse proxy (Traefik), SSO, VPN |
| 192.168.1.191 | management | *.management → .190 | Server | Monitoring, gestione, dashboard |
| 192.168.1.192 | media | *.media → .190 | Server | Media streaming e download |
| 192.168.1.193 | dev | *.dev → .190 | Server | Sviluppo, Git, registry |
| 192.168.1.194 | cloud | *.cloud → .190 | Server | File, documenti, foto |

I wildcard `*.<server>.intranet.vflorio.com` puntano tutti al gateway (192.168.1.190): Traefik è l'unico reverse proxy e le app degli altri server gli vengono pubblicate tramite traefik-kop.

## Virtual Machines

### VM Infrastructure

| VM ID | Nome | IP | Progetto | Descrizione |
|---|---|---|---|---|
| 1010 | dns | 192.168.1.150 | DNS Resolution | Server DNS Bind9 per risoluzione intranet |
| 1020 | nas | 192.168.1.151 | Storage | HomeLab NAS (OpenMediaVault) |
| 1030 | firewall | 192.168.1.152 | Security | HomeLab Firewall (OpnSense) |
| 3100 | srv-gateway | 192.168.1.190 | Server | Gateway: Traefik, Authentik, Tailscale, CrowdSec (4 vCPU, 4 GB) |
| 3200 | srv-management | 192.168.1.191 | Server | Management: Homepage, Grafana, Portainer, Guacamole (4 vCPU, 4 GB) |
| 3300 | srv-media | 192.168.1.192 | Server | Media: Jellyfin, Emby, *arr, download (6 vCPU, 12 GB) |
| 3400 | srv-dev | 192.168.1.193 | Server | Dev: Coder, Gitea, registry, Verdaccio (8 vCPU, 16 GB) |
| 3500 | srv-cloud | 192.168.1.194 | Server | Cloud: Nextcloud, OnlyOffice, Immich (4 vCPU, 8 GB) |

## Storage Architecture

### Physical Storage Configuration

Il server fisico principale (**silicon** - 192.168.1.1) gestisce lo storage attraverso una configurazione multi-tier:

#### Primary Storage - NVMe
- **Dispositivo**: NVMe SSD 1TB
- **Utilizzo**: Hypervisor e Virtual Machines
- **Scopo**: Storage ad alte prestazioni per:
  - Sistema operativo Proxmox VE
  - VM disk images (thin provisioning)
  - VM snapshots e backup locali
  - Swap e cache del sistema

#### OpenMediaVault (OMV) Pool
La gestione dei dati è centralizzata tramite **OpenMediaVault** su VM dedicata (nas - 192.168.1.151):

##### SSD Pool - Application Data
- **Dispositivo**: SSD (capacità variabile)
- **Accesso**: export NFS `ssd-0` (≈440 GB)
- **Utilizzo**: Dati delle applicazioni Docker
- **Contenuto**:
  - Dati applicativi per server: `homelab-data/<server>` (npm store, container-registry, config, log, ...)
  - Foto (`photos`, usate da Immich) e archivio documenti
  - Storage per Nextcloud files

##### HDD Pool - Media Storage
- **Dispositivi**: 3x HDD SMR (Shingled Magnetic Recording)
- **Configurazione**: JBOD (Just a Bunch Of Disks) - dischi indipendenti
- **Accesso**: export NFS `media-0` (7.3 TB), `media-1` (5.5 TB), `media-2` (5.5 TB)
- **Utilizzo**: Media server e archivio a lungo termine
- **Contenuto**:
  - Libreria multimediale Jellyfin / Emby (film, serie TV, musica)


### Storage Integration

#### NFS Mount Configuration
Gli export OMV vengono montati via NFS su tutti i server applicativi (vedi `mount-nas.sh`):

```bash
# /etc/fstab sui server Docker
nas.intranet.vflorio.com:/ssd-0   /mnt/nfs/ssd-0   nfs defaults,rw,_netdev 0 0
nas.intranet.vflorio.com:/media-0 /mnt/nfs/media-0 nfs defaults,rw,_netdev 0 0
nas.intranet.vflorio.com:/media-1 /mnt/nfs/media-1 nfs defaults,rw,_netdev 0 0
nas.intranet.vflorio.com:/media-2 /mnt/nfs/media-2 nfs defaults,rw,_netdev 0 0
```

#### Docker Volume Management
- I dati delle app sono bind mount sotto `PATH_DATA=/mnt/nfs/ssd-0/homelab-data/<server>` (definito nel `.env` di ogni server).
- Il media server monta l'intero `PATH_MEDIA=/mnt/nfs/` (tutti e tre gli HDD).
- I database PostgreSQL usano invece **volumi Docker locali** sul disco della VM: Postgres su NFS non è sicuro (locking/corruzione).

```yaml
services:
  app:
    volumes:
      - ${PATH_DATA:?err}/app:/config   # NFS, ssd-0
  postgresql:
    volumes:
      - postgresql-data:/var/lib/postgresql   # disco locale della VM

volumes:
  postgresql-data:
    driver: local
```
---
