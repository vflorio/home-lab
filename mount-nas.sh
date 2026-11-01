#!/bin/bash

set -e

# Share NFS da montare
declare -A shares=(
  ["media-0"]="/mnt/nfs/media-0"
  ["media-1"]="/mnt/nfs/media-1"
  ["media-2"]="/mnt/nfs/media-2"
  ["ssd-0"]="/mnt/nfs/ssd-0"
)

# Server NFS
NAS="nas.intranet.vflorio.com"

# Opzioni di mount
OPTIONS="defaults,rw,_netdev"

echo "🔧 Montaggio delle share NFS da $NAS..."

for remote in "${!shares[@]}"; do
  local="${shares[$remote]}"
  echo "📁 Verifico $local..."
  sudo mkdir -p "$local"
  

  fstab_entry="$NAS:/$remote $local nfs $OPTIONS 0 0"

  # Aggiungi a /etc/fstab solo se non già presente
  if ! grep -qs "$local" /etc/fstab; then
    echo "$fstab_entry" | sudo tee -a /etc/fstab > /dev/null
    echo "✅ Aggiunto a /etc/fstab: $fstab_entry"

    # Crea i link simbolici
    sudo ln -s "$local" "/mnt/nfs/media/$remote"
  else
    echo "⏩ Già presente in /etc/fstab: $local"
  fi
done

echo "🚀 Eseguo mount..."
sudo systemctl daemon-reexec
sudo mount -a

echo "✅ Tutte le share NFS sono montate correttamente."
