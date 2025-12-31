# LifeLibretto Cryptography

Documentation for encryption and signing used in LifeLibretto.

## Encryption (age)

- **Tool:** age v1.x
- **Algorithm:** X25519 + ChaCha20-Poly1305
- **Specification:** https://age-encryption.org/v1
- **Key format:** Bech32 (age1...)

### Key Storage

- **Public key:** Can be stored in config.yaml
- **Private key:** Store in Bitwarden ("LifeLibretto Keys"), NOT in repo

### Usage

```bash
# Encrypt a file for vault
age -e -r age1ql3z7hjy... -o vault/objects/a7/b3c9... original.file

# Decrypt a vault object
age -d -i ~/.config/libretto/age.key vault/objects/a7/b3c9... > decrypted.file
```

### Key Generation

```bash
age-keygen -o ~/.config/libretto/age.key
# Outputs public key to stdout, private key to file
```

## Signing (minisign)

- **Tool:** minisign
- **Algorithm:** Ed25519
- **Specification:** https://jedisct1.github.io/minisign/

### Key Storage

- **Public key:** Can be stored in repo (minisign.pub)
- **Private key:** Store in Bitwarden, NOT in repo

### Usage

```bash
# Sign a checkpoint
minisign -Sm checkpoints/2025-01-01.merkle -s ~/.config/libretto/minisign.key

# Verify a checkpoint
minisign -Vm checkpoints/2025-01-01.merkle -p minisign.pub
```

### Key Generation

```bash
minisign -G -p minisign.pub -s ~/.config/libretto/minisign.key
```

## Backup Encryption (restic)

- **Tool:** restic
- **Encryption:** AES-256 in counter mode
- **Authentication:** Poly1305-AES

### Password Storage

Store restic password in Bitwarden ("LifeLibretto Keys").

## Recovery

1. Get keys from Bitwarden:
   - age private key
   - minisign private key
   - restic password

2. Place age key:
   ```bash
   mkdir -p ~/.config/libretto
   echo "$AGE_SECRET_KEY" > ~/.config/libretto/age.key
   chmod 600 ~/.config/libretto/age.key
   ```

3. Restore data:
   ```bash
   export RESTIC_PASSWORD="..."
   restic -r <backup-repo> restore latest --target /libretto
   ```

4. Verify:
   ```bash
   libretto verify
   ```

## Security Notes

- Private keys should NEVER be committed to the repo
- Use Bitwarden or similar secure storage for keys
- Keep a paper backup of keys in a secure location
- The age and minisign algorithms are modern and widely supported
- If tools disappear, the underlying algorithms (X25519, ChaCha20, Ed25519) are available in every major cryptography library
