# SSH Permission Troubleshooting Guide

## Windows

### SSH Key Permissions
```powershell
# Set your device name (example: carbon, silicon, nitrogen, etc.)
$DEVICE_NAME = "carbon"

# Fix private key permissions (remove inheritance, grant only current user)
icacls $env:USERPROFILE\.ssh\id_ed25519_$DEVICE_NAME /inheritance:r
icacls $env:USERPROFILE\.ssh\id_ed25519_$DEVICE_NAME /grant:r "$($env:USERNAME):(R)"

# Fix public key permissions
icacls $env:USERPROFILE\.ssh\id_ed25519_$DEVICE_NAME.pub /inheritance:r
icacls $env:USERPROFILE\.ssh\id_ed25519_$DEVICE_NAME.pub /grant:r "$($env:USERNAME):(R)"

# Fix SSH folder permissions
icacls $env:USERPROFILE\.ssh /inheritance:r
icacls $env:USERPROFILE\.ssh /grant:r "$($env:USERNAME):(OI)(CI)(F)"
```

### SSH Config Permissions
```powershell
# Fix config file permissions
icacls $env:USERPROFILE\.ssh\config /inheritance:r
icacls $env:USERPROFILE\.ssh\config /grant:r "$($env:USERNAME):(R,W)"
```

## Linux

### SSH Key Permissions
```bash
# Set your device name (example: carbon, silicon, nitrogen, etc.)
DEVICE_NAME="carbon"

# Fix SSH directory permissions
chmod 700 ~/.ssh

# Fix private key permissions (read-only for owner)
chmod 600 ~/.ssh/id_ed25519_$DEVICE_NAME

# Fix public key permissions
chmod 644 ~/.ssh/id_ed25519_$DEVICE_NAME.pub

# Fix config file permissions
chmod 600 ~/.ssh/config

# Fix authorized_keys permissions (if applicable)
chmod 600 ~/.ssh/authorized_keys
```

### Quick Fix All
```bash
# Set your device name first
DEVICE_NAME="carbon"

# One-liner to fix all SSH permissions for named keys
chmod 700 ~/.ssh && \
chmod 600 ~/.ssh/id_ed25519_$DEVICE_NAME && \
chmod 644 ~/.ssh/id_ed25519_$DEVICE_NAME.pub && \
chmod 600 ~/.ssh/config
```

## Common Issues

- **"Permissions too open"**: Private keys must be readable only by owner (600 on Linux, restricted access on Windows)
- **"Could not load host key"**: SSH config or keys have incorrect permissions
- **"Permission denied (publickey)"**: Check both local key permissions and remote authorized_keys

## Verification

```bash
# Check current permissions
ls -la ~/.ssh/
```

```powershell
# Check current permissions (Windows)
icacls $env:USERPROFILE\.ssh\*
```