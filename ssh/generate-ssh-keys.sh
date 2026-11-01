#!/bin/bash
# SSH Key Generation Script for HomeLab Devices
# Generates ed25519 SSH keys for each device alias

# Device aliases from Homelab.md
DEVICE_ALIASES=(
    "silicon"     # server
    "carbon"      # workstation
    "nitrogen"    # macmini
    "boron"       # tablet-android
    "phosphorus"  # smartphone-ios
    "sulfur"      # tv-hisense
    "chlorine"    # tv-android
    "argon"       # laptop-discovery
    "neon"        # laptop-kineton
)

# SSH directory
SSH_DIR="$HOME/.ssh"

# Create .ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    echo "✅ Created SSH directory: $SSH_DIR"
fi

echo "🔑 Generating SSH keys for HomeLab devices..."
echo "========================================="

for alias in "${DEVICE_ALIASES[@]}"; do
    key_path="$SSH_DIR/id_ed25519_$alias"
    pub_key_path="$key_path.pub"
    
    # Check if key already exists
    if [ -f "$key_path" ]; then
        echo "⚠️  Key already exists for $alias - skipping"
        continue
    fi
    
    echo "🔑 Generating key for: $alias"
    
    # Generate SSH key
    ssh-keygen -t ed25519 -f "$key_path" -N "" -C "$alias-homelab-$(date +%Y-%m-%d)"
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully generated key for $alias"
        
        # Set proper permissions
        chmod 600 "$key_path"
        chmod 644 "$pub_key_path"
        
        echo "🔒 Set proper permissions for $alias keys"
        
        # Add public key to authorized_keys
        authorized_keys_path="$SSH_DIR/authorized_keys"
        
        # Create authorized_keys if it doesn't exist
        if [ ! -f "$authorized_keys_path" ]; then
            touch "$authorized_keys_path"
            chmod 600 "$authorized_keys_path"
        fi
        
        # Check if key already exists in authorized_keys
        if ! grep -Fq "$(cat "$pub_key_path")" "$authorized_keys_path" 2>/dev/null; then
            cat "$pub_key_path" >> "$authorized_keys_path"
            echo "🔓 Added $alias public key to authorized_keys"
        fi
        
        # Ensure proper permissions for authorized_keys
        chmod 600 "$authorized_keys_path"
        
    else
        echo "❌ Failed to generate key for $alias"
    fi
    
    echo ""
done

echo "========================================="
echo "✅ SSH key generation completed!"
echo ""
echo "📋 Generated keys:"
ls -la "$SSH_DIR"/id_ed25519_* 2>/dev/null | awk '{print $9}' | sed 's|.*/||'
echo ""
echo "📝 Next steps:"
echo "1. ✅ All public keys have been added to local authorized_keys"
echo "2. Copy authorized_keys to target devices if needed"
echo "3. Update SSH config to use specific keys per host"
echo "4. Test connections: ssh -i ~/.ssh/id_ed25519_<alias> user@host"
echo ""
echo "💡 Commands to copy authorized_keys to remote devices:"
echo "scp ~/.ssh/authorized_keys user@192.168.1.X:~/.ssh/"
echo "ssh-copy-id -i ~/.ssh/id_ed25519_carbon.pub user@192.168.1.2"