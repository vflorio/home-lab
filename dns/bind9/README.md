# Bind9 DNS Server - HomeLab Configuration

Configurazione e gestione del server DNS Bind9 per la rete intranet del HomeLab.

## 🚀 Setup Iniziale

### 1. Preparazione Ambiente

Prima di procedere con l'installazione, assicurarsi che:
- Il server target (192.168.1.150) sia accessibile via SSH
- L'utente abbia privilegi sudo
- Docker e Docker Compose siano installati

### 2. Deploy Iniziale

#### Sincronizzazione Files
```bash
# Copia la configurazione sul server DNS
rsync \
  --exclude '.git' \
  --progress \
  --recursive \
  . \
  vflorio@192.168.1.150:~/bind9
```

#### Correzione Permessi
```bash
# Accedere al server DNS
ssh vflorio@192.168.1.150

# Navigare nella directory bind9
cd ~/bind9

# Impostare proprietario corretto (root:root)
sudo chown -R 0:0 config

# Impostare permessi corretti (755 per directory, 644 per file)
sudo chmod -R 775 config
```

### 3. Inizializzazione Terraform

```bash
# Entrare nella directory terraform
cd terraform

# Inizializzare Terraform (prima volta)
terraform init

# Verificare la configurazione
terraform plan

# Applicare la configurazione DNS
terraform apply
```

## 🔄 Aggiornamento Configurazione

### Per Server già in Funzione

#### 1. Aggiornamento Files di Configurazione
```bash
# Sincronizzare le modifiche
rsync \
  --exclude '.git' \
  --progress \
  --recursive \
  . \
  vflorio@192.168.1.150:~/bind9

# Accedere al server
ssh vflorio@192.168.1.150
cd ~/bind9
```

#### 2. Applicare Modifiche DNS via Terraform
```bash
cd terraform

# Verificare le modifiche
terraform plan

# Applicare solo se le modifiche sono corrette
terraform apply
```

#### 3. Gestione Zone DNS (Metodo Alternativo)
Se si preferisce gestire le zone manualmente senza Terraform:

```bash
# Fermare le modifiche dinamiche
rndc freeze intranet.vflorio.com

# Modificare manualmente i file di zona in config/
# ... editing dei file ...

# Sincronizzare i dati journal con il file di zona
rndc sync intranet.vflorio.com

# Riavviare le modifiche dinamiche
rndc thaw intranet.vflorio.com
```

## 🛠️ Risoluzione Problemi

### Problemi di Permessi

#### Errore: "Permission denied" sui file di configurazione
```bash
# Verificare i permessi attuali
ls -la config/

# Correggere proprietario
sudo chown -R 0:0 config

# Correggere permessi
sudo chmod -R 775 config

# Verificare che i file zone abbiano permessi corretti
sudo chmod 644 config/zones/*
sudo chmod 755 config/zones/
```

#### Errore: "journal file not writable"
```bash
# Creare directory per i journal se non esiste
sudo mkdir -p config/zones/journals

# Impostare permessi per i journal
sudo chown -R bind:bind config/zones/journals
sudo chmod 755 config/zones/journals
```

### Problemi di Configurazione

#### Verificare sintassi configurazione
```bash
# Testare la configurazione principale
sudo named-checkconf config/named.conf

# Testare specifiche zone
sudo named-checkzone intranet.vflorio.com config/zones/intranet.vflorio.com.zone
```

#### Riavviare il servizio
```bash
# Se usando Docker Compose
docker-compose restart

# Se usando systemd
sudo systemctl restart bind9
```

### Debug e Monitoring

#### Verificare lo stato del servizio
```bash
# Log del container
docker-compose logs -f

# Status del servizio (se systemd)
sudo systemctl status bind9
```

#### Test risoluzione DNS
```bash
# Test locale
nslookup workstation.intranet.vflorio.com 192.168.1.150

# Test con dig
dig @192.168.1.150 workstation.intranet.vflorio.com

# Verificare tutti i record A
dig @192.168.1.150 intranet.vflorio.com AXFR
```

## 📋 Comandi di Gestione

### Remote Name Daemon Control (rndc)

#### Gestione Zone
```bash
# Sincronizzare journal con file di zona
rndc sync intranet.vflorio.com

# Bloccare modifiche dinamiche e salvare
rndc freeze intranet.vflorio.com

# Riabilitare modifiche dinamiche
rndc thaw intranet.vflorio.com

# Ricaricare configurazione
rndc reload

# Ricaricare specifica zona
rndc reload intranet.vflorio.com
```

#### Statistiche e Status
```bash
# Mostrare statistiche
rndc stats

# Stato del server
rndc status

# Flush cache
rndc flush
```

### Terraform

#### Comandi Base
```bash
# Inizializzazione (solo prima volta)
terraform init

# Pianificazione modifiche
terraform plan

# Applicazione modifiche
terraform apply

# Distruzione infrastruttura (⚠️ ATTENZIONE!)
terraform destroy

# Formattazione codice
terraform fmt

# Validazione sintassi
terraform validate
```

#### Gestione State
```bash
# Mostrare stato attuale
terraform show

# Listare risorse gestite
terraform state list

# Importare risorsa esistente
terraform import dns_a_record_set.example existing-record-id
```

## 📄 Configurazione SOA (Start of Authority)

```bind
$TTL 2d
$ORIGIN intranet.vflorio.com.

@       IN      SOA     ns.intranet.vflorio.com. admin.intranet.vflorio.com. (
                        2024091401  ; serial number (YYYYMMDDNN)
                        12h         ; refresh (12 ore)
                        15m         ; retry (15 minuti)
                        3w          ; expire (3 settimane)
                        2h          ; minimum TTL (2 ore)
                        )
        IN      NS      ns.intranet.vflorio.com.

; Name server
ns      IN      A       192.168.1.150
```

## 🔧 Struttura Directory

```
bind9/
├── README.md                   # Questa documentazione
├── docker-compose.yml          # Configurazione Docker
├── config/                     # Configurazioni Bind9
│   ├── named.conf              # Configurazione principale
│   ├── zones/                  # File delle zone DNS
│   │   ├── intranet.vflorio.com.zone
│   │   └── journals/           # File journal per aggiornamenti dinamici
│   └── keys/                   # Chiavi DNSSEC (se utilizzate)
└── terraform/                  # Infrastructure as Code
    ├── provider.tf             # Provider Terraform
    ├── infrastructure.tf       # Servizi infrastruttura
    ├── hardware.tf             # Dispositivi fisici
    ├── activasticks.tf         # Mini PC ActivaStick
    ├── srv-prod.tf            # Server produzione
    └── srv-demo.tf            # Server demo/test
```
---
