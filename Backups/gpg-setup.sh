#!/usr/bin/env bash
# ========================================
# GPG Setup Wizard for Backup Encryption
# ========================================

set -euo pipefail

echo "Welcome to the GPG Setup Wizard!"

# Ask for user email
read -rp "What is your email (used for GPG key)?: " EMAIL

# Check if the key already exists
if gpg --list-keys "$EMAIL" > /dev/null 2>&1; then
    echo "Found existing GPG key for $EMAIL."
else
    echo "No GPG key found for $EMAIL."
    read -rp "Do you want to generate a new GPG key for this email? [y/N] " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo "Generating a new key..."
        gpg --batch --gen-key <<EOF
        Key-Type: RSA
        Key-Length: 4096
        Name-Email: $EMAIL
        Expire-Date: 0
        %no-protection
        %commit
EOF
        echo "Key generated!"
    else
        echo "Cannot continue without a GPG key. Exiting."
        exit 1
    fi
fi

# Ask to export the key
read -rp "Do you want to export your public key so you can import it on the server? [Y/n] " EXPORT_REPLY
if [[ "$EXPORT_REPLY" =~ ^[Yy]?$ ]]; then
    FILE="${EMAIL//[@.]/_}_publickey.asc"
    gpg --output "$FILE" --armor --export "$EMAIL"
    echo "Public key exported to: $FILE"
    echo "Now transfer it to your server using:"
    echo "scp $FILE your-user@your-server-ip:~"
fi

# Ask if they want to import a key (e.g., if running this on the server)
read -rp "Do you want to import a public key (e.g., from another machine)? [y/N] " IMPORT_REPLY
if [[ "$IMPORT_REPLY" =~ ^[Yy]$ ]]; then
    read -rp "Path to the .asc file to import: " KEY_FILE
    if [[ -f "$KEY_FILE" ]]; then
        gpg --import "$KEY_FILE"
        echo "Key imported!"
    else
        echo "File not found: $KEY_FILE"
        exit 1
    fi
fi

# Final check
echo "Verifying key installation..."
if gpg --list-keys "$EMAIL" > /dev/null 2>&1; then
    echo "All set! Your GPG key for $EMAIL is ready to use for encrypted backups."
else
    echo "Something went wrong. GPG key not found."
    exit 1
fi

