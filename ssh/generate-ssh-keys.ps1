# SSH Key Generation Script for HomeLab Devices
# Generates ed25519 SSH keys for each device alias

# Device aliases from Homelab.md
$DeviceAliases = @(
    "silicon",     # server
    "carbon",      # workstation
    "nitrogen",    # macmini
    "boron",       # tablet-android
    "phosphorus",  # smartphone-ios
    "sulfur",      # tv-hisense
    "chlorine",    # tv-android
    "argon",       # laptop-discovery
    "neon"         # laptop-kineton
)

# SSH directory
$SshDir = "$env:USERPROFILE\.ssh"

# Create .ssh directory if it doesn't exist
if (-not (Test-Path $SshDir)) {
    New-Item -ItemType Directory -Path $SshDir -Force
    Write-Host "Created SSH directory: $SshDir" -ForegroundColor Green
}

Write-Host "Generating SSH keys for HomeLab devices..." -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

foreach ($alias in $DeviceAliases) {
    $keyPath = "$SshDir\id_ed25519_$alias"
    $pubKeyPath = "$keyPath.pub"
    
    # Check if key already exists
    if (Test-Path $keyPath) {
        Write-Host "⚠️  Key already exists for $alias - skipping" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "🔑 Generating key for: $alias" -ForegroundColor Green
    
    # Generate SSH key
    & ssh-keygen -t ed25519 -f $keyPath -N '""' -C "$alias-homelab-$(Get-Date -Format 'yyyy-MM-dd')"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Successfully generated key for $alias" -ForegroundColor Green
        
        # Set proper permissions on Windows
        icacls $keyPath /inheritance:r | Out-Null
        icacls $keyPath /grant:r "$($env:USERNAME):(R)" | Out-Null
        icacls $pubKeyPath /inheritance:r | Out-Null
        icacls $pubKeyPath /grant:r "$($env:USERNAME):(R)" | Out-Null
        
        Write-Host "🔒 Set proper permissions for $alias keys" -ForegroundColor Blue
        
        # Add public key to authorized_keys
        $authorizedKeysPath = "$SshDir\authorized_keys"
        $publicKeyContent = Get-Content $pubKeyPath
        
        if (-not (Test-Path $authorizedKeysPath)) {
            New-Item -ItemType File -Path $authorizedKeysPath -Force | Out-Null
        }
        
        # Check if key already exists in authorized_keys
        $existingKeys = Get-Content $authorizedKeysPath -ErrorAction SilentlyContinue
        if ($existingKeys -notcontains $publicKeyContent) {
            Add-Content -Path $authorizedKeysPath -Value $publicKeyContent
            Write-Host "🔓 Added $alias public key to authorized_keys" -ForegroundColor Magenta
        }
        
        # Set proper permissions for authorized_keys
        icacls $authorizedKeysPath /inheritance:r | Out-Null
        icacls $authorizedKeysPath /grant:r "$($env:USERNAME):(R,W)" | Out-Null
        
    } else {
        Write-Host "❌ Failed to generate key for $alias" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "SSH key generation completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Generated keys:" -ForegroundColor Yellow
Get-ChildItem "$SshDir\id_ed25519_*" | Select-Object Name | Format-Table -HideTableHeaders
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. All public keys have been added to local authorized_keys" -ForegroundColor White
Write-Host "2. Copy authorized_keys to target devices if needed" -ForegroundColor White
Write-Host "3. Update SSH config to use specific keys per host" -ForegroundColor White
Write-Host "4. Test connections: ssh -i ~/.ssh/id_ed25519_<alias> user@host" -ForegroundColor White
Write-Host ""
Write-Host "💡 To copy authorized_keys to a remote device:" -ForegroundColor Yellow
Write-Host "   scp $SshDir\authorized_keys user@192.168.1.X:~/.ssh/" -ForegroundColor Gray