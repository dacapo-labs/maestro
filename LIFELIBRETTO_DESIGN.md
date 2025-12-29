# LifeLibretto Design Specification

**Version:** 1.0.0
**Status:** Draft
**Date:** 2025-01-28

---

## Overview

LifeLibretto is an immutable, cryptographically-verified life archive that serves as the memory layer for LifeMaestro. It provides:

- **Guaranteed immutability** - Append-only chain with hash links
- **Tamper evidence** - Any modification breaks the chain
- **Completeness proof** - Signed Merkle root checkpoints
- **Rich querying** - Full-text and semantic search
- **AI context** - Feeds LifeMaestro with historical memory

### Relationship to LifeMaestro

```
┌─────────────────────────────────────────────────────────────────┐
│                      LifeLibretto (The Past)                     │
│  • Immutable archive - cryptographic proof                       │
│  • "What happened" - guaranteed truth                            │
│  • Content-addressed vault + hash chain                          │
└─────────────────────────┬───────────────────────────────────────┘
                          │ REST API (over Tailscale)
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      LifeMaestro (The Present)                   │
│  • Active AI operating system                                    │
│  • Zones, sessions, skills                                       │
│  • Search, context, action                                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Core Principles

1. **Append-only** - No edits, no deletes (corrections are new entries)
2. **Content-addressed** - Files stored by SHA-256 hash
3. **Chain-linked** - Each entry references previous (completeness proof)
4. **Encrypted at rest** - age encryption, keys in Bitwarden
5. **Human-readable manifests** - YAML chain files
6. **Query-first** - SQLite index for fast lookups, chain for truth
7. **Plain text** - No opaque formats, no complex dependencies

---

## Architecture

### Directory Structure

```
libretto/
├── vault/                      # IMMUTABLE - encrypted content
│   └── objects/
│       ├── a7/
│       │   └── b3c9f8e2d1...   # age-encrypted files by SHA-256
│       └── e2/
│           └── 1a2b3c4d5e...
│
├── chain/                      # IMMUTABLE - append-only manifests
│   ├── 2020/
│   │   ├── 01.yaml
│   │   └── 02.yaml
│   ├── 2025/
│   │   └── 01.yaml
│   └── HEAD                    # Current chain tip digest
│
├── annotations/                # IMMUTABLE - append-only corrections
│   ├── 2025/
│   │   └── 01.yaml
│   └── HEAD
│
├── checkpoints/                # IMMUTABLE - signed Merkle roots
│   ├── 2025-01-01.merkle
│   ├── 2025-01-01.merkle.sig
│   └── 2025-01-01.git
│
├── index/                      # DERIVED - rebuildable
│   ├── libretto.db             # SQLite (FTS, metadata)
│   ├── vectors.lance/          # LanceDB (embeddings)
│   └── VERSION                 # Index schema version
│
├── state/                      # OPERATIONAL - sync state
│   ├── cursors.yaml            # Per-source sync cursors
│   ├── errors.yaml             # Failed ingestions
│   └── daemon.pid
│
├── config.yaml                 # Configuration
├── CRYPTO.md                   # Key documentation for recovery
└── VERSION                     # Schema version
```

### File Categories

| Directory | Mutability | Backed Up | Rebuildable |
|-----------|------------|-----------|-------------|
| `vault/` | Immutable | Yes | No |
| `chain/` | Append-only | Yes | No |
| `annotations/` | Append-only | Yes | No |
| `checkpoints/` | Append-only | Yes | No |
| `index/` | Mutable | No | Yes |
| `state/` | Mutable | Yes | Partially |
| `config.yaml` | Mutable | Yes | No |

---

## Data Model

### Chain Entry Schema

```yaml
# chain/2025/01.yaml
entries:
  - id: "01JQXA1B2C3D"           # ULID (sortable, unique)
    ts: "2025-01-28T10:30:00Z"   # Event timestamp (when it happened)
    chained_at: "2025-01-28T10:35:00Z"  # Ingest timestamp
    prev: "sha256:abc123..."     # Previous entry digest (chain link)

    type: email                  # email|photo|video|calendar|slack|...
    source: gmail                # gmail|outlook|google-photos|...
    source_id: "msg_abc123"      # ID from source system
    action: created              # created|updated|deleted

    content:
      hash: "sha256:a7b3c9..."   # Vault object reference
      mime: "message/rfc822"
      size: 12834

    meta:                        # Type-specific, indexed
      from: "john@example.com"
      to: ["me@example.com"]
      subject: "Q4 Planning"
      message_id: "<123@example.com>"

    digest: "sha256:def456..."   # Hash of this entry (for chain)
```

### Two Timestamps

- **ts (event time):** When the event actually happened
- **chained_at:** When we ingested it into the archive

This allows late backfill - old data appended to chain with historical event timestamps.

### Annotation Schema

```yaml
# annotations/2025/01.yaml
entries:
  - id: "01JQXB..."
    ts: "2025-01-28T12:00:00Z"
    prev: "sha256:..."

    entry_id: "01JQXA..."        # References chain entry
    type: tag                    # tag|correction|link|note
    value:
      tags: ["important", "follow-up"]

    digest: "sha256:..."
```

Annotations are also chained and immutable - corrections don't modify, they append.

---

## Data Sources

| Source | Type | Method | Atomic Unit |
|--------|------|--------|-------------|
| Gmail | email | OAuth API | Single message |
| Outlook | email | Graph API | Single message |
| Google Calendar | calendar | OAuth API | Event + version |
| MS365 Calendar | calendar | Graph API | Event + version |
| Slack | chat | Socket Mode | Single message |
| ServiceDesk Plus | tickets | REST API | Single ticket |
| Google Photos | media | OAuth API / Takeout | Single photo/video |
| iCloud Photos | media | Local sync | Single photo/video |
| Telegram | notes | Bot API | Single message |
| Teller.io | financial | OAuth API | Single transaction |
| Garmin | health | garminconnect API | Daily summary |
| OwnTracks | location | HTTP push | Hourly bucket |
| Browser History | browsing | Tailscale SSH | Per-URL-per-day |
| ActivityWatch | activity | REST API | Hourly bucket |
| Books (EPUB) | media | ebooklib | Whole book |

---

## Cryptography

### Encryption (age)

- **Tool:** age v1.x
- **Algorithm:** X25519 + ChaCha20-Poly1305
- **Scope:** Per-file encryption in vault
- **Key storage:** Private key in Bitwarden

```bash
# Encrypt
age -e -r age1ql3z7hjy... -o vault/objects/a7/b3c9... original.file

# Decrypt
age -d -i ~/.config/libretto/age.key vault/objects/a7/b3c9... > decrypted.file
```

### Signing (minisign)

- **Tool:** minisign
- **Algorithm:** Ed25519
- **Scope:** Checkpoint Merkle roots
- **Key storage:** Private key in Bitwarden

```bash
# Sign checkpoint
minisign -Sm checkpoints/2025-01-01.merkle -s ~/.config/libretto/minisign.key

# Verify
minisign -Vm checkpoints/2025-01-01.merkle -p minisign.pub
```

### Why age + minisign (not GPG)

- Simpler, modern cryptography
- Smaller keys, easier backup
- Clear specifications, easy to reimplement
- Standard algorithms (X25519, Ed25519) used everywhere

---

## Deduplication Strategy

### Large Files (Photos/Videos)

Content hash deduplication - same content = same hash = stored once.

```
Photo (5MB) → SHA-256 → "a7b3c9..."
                         ↓
              vault/objects/a7/b3c9... (one copy)
```

Multiple chain entries can reference the same vault object.

### Small Structured Data (Email/Calendar/Slack)

Simple approach - don't overthink it:

- **Email:** Raw hash for vault, Message-ID for cross-provider linking
- **Calendar:** Event-ID for linking across updates
- **Slack:** ts + channel for identity

No canonical hashing complexity. Space is cheap, complexity is expensive.

---

## Chain Integrity

### Hash Chain

Each entry includes `prev:` pointing to previous entry's `digest`:

```
Entry 1: { digest: "aaa", prev: null }
Entry 2: { digest: "bbb", prev: "sha256:aaa" }
Entry 3: { digest: "ccc", prev: "sha256:bbb" }
```

Modifying or removing any entry breaks all subsequent links.

### Merkle Tree Checkpoints

Monthly signed checkpoints with Merkle root of all entries:

```yaml
# checkpoints/2025-01-01.merkle
checkpoint:
  date: "2025-01-01T00:00:00Z"
chain:
  entries: 145293
  last_digest: "sha256:abc123..."
merkle:
  root: "sha256:def456..."
  algorithm: sha256
```

Signed with minisign, committed to Git for third-party timestamp.

### Merkle Proofs

Can prove single entry existed without revealing entire chain:

```bash
libretto checkpoint prove 01JQXYZ --checkpoint 2025-01-01
```

---

## Ingestion Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│  1. FETCH              Connector pulls raw data                  │
│                        Tracks cursor/checkpoint per source       │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. NORMALIZE          Convert to common structure               │
│                        Extract metadata, preserve original       │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. HASH               SHA-256 content → check vault             │
│                        Dedupe: skip store if exists              │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. ENCRYPT            age encrypt → write to vault/objects/     │
│                        (skip if hash already exists)             │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. CHAIN              Append entry to chain/YYYY/MM.yaml        │
│                        Include prev hash, content hash, meta     │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  6. INDEX              Update SQLite + vectors (async)           │
│                        Classification, embeddings, FTS           │
└─────────────────────────────────────────────────────────────────┘
```

### Backfill vs Live

- **Backfill:** One-time historical import, newest-first, sequential per source
- **Live:** Ongoing sync, starts after backfill reaches overlap point
- **Overlap:** ~1 week between backfill end and live start, dedupe handles duplicates

### Large Files

Stream to disk during download, hash during transfer:

```python
with requests.get(url, stream=True) as r:
    with open(temp_path, 'wb') as f:
        for chunk in r.iter_content(chunk_size=8192):
            f.write(chunk)
            hasher.update(chunk)
```

---

## Calendar/Mutable Data Handling

Event-sourced approach - each change is a new entry:

```yaml
# Event created
- id: "01JQX001"
  type: calendar
  action: created
  meta:
    event_id: "gcal_xyz789"
    title: "Team Standup"
    start: "2025-01-30T10:00:00Z"

# Same event edited
- id: "01JQX002"
  type: calendar
  action: updated
  meta:
    event_id: "gcal_xyz789"
    title: "Team Standup"
    start: "2025-01-30T11:00:00Z"  # Changed
  previous: "01JQX001"

# Event cancelled
- id: "01JQX003"
  type: calendar
  action: deleted
  meta:
    event_id: "gcal_xyz789"
  previous: "01JQX002"
```

Index materializes current state. Chain preserves full history.

---

## Query Layer

### Index (SQLite + LanceDB)

```sql
CREATE TABLE entries (
  id TEXT PRIMARY KEY,
  ts TIMESTAMP NOT NULL,
  chained_at TIMESTAMP NOT NULL,
  type TEXT NOT NULL,
  source TEXT NOT NULL,
  source_id TEXT,
  content_hash TEXT NOT NULL,
  meta JSON,
  digest TEXT NOT NULL
);

CREATE VIRTUAL TABLE entries_fts USING fts5(
  id, content, meta_text
);

CREATE TABLE enrichments (
  entry_id TEXT PRIMARY KEY,
  classification TEXT,
  priority REAL,
  model_version TEXT
);

CREATE TABLE people (
  identifier TEXT PRIMARY KEY,
  display_name TEXT,
  aliases JSON,
  entry_count INTEGER
);
```

### Query Language

```bash
libretto search "from:brad type:email after:2024-12-01 migration"
```

| Modifier | Example | Meaning |
|----------|---------|---------|
| `from:` | `from:brad` | Sender/author |
| `to:` | `to:me` | Recipient |
| `type:` | `type:email` | Content type |
| `in:` | `in:slack` | Source |
| `date:` | `date:2025-01-15` | Specific date |
| `before:` | `before:2025-01-01` | Before date |
| `after:` | `after:2024-06-01` | After date |
| `has:` | `has:attachment` | Has property |
| `is:` | `is:important` | Has tag |

---

## API Surface

### CLI Commands

```bash
# Ingestion
libretto ingest gmail
libretto backfill gmail --since 2020-01-01
libretto daemon start|stop|status

# Search & Query
libretto search "query" [--type TYPE] [--since DATE]
libretto timeline DATE
libretto person "name or email"
libretto entry ID [--content]
libretto context [--hours N]

# Chain & Verification
libretto verify
libretto chain status

# Annotations
libretto annotate ID --tag "important"

# Checkpoints
libretto checkpoint create [--sign]
libretto checkpoint verify DATE

# Backup
libretto backup run [--dest NAME]
libretto backup status
libretto snapshot create|list|rollback

# Admin
libretto index rebuild
libretto stats
libretto health
```

### REST API

```
GET  /api/search?q=...&type=...&since=...
GET  /api/timeline/{date}
GET  /api/person/{identifier}
GET  /api/entry/{id}
GET  /api/context?hours=24
POST /api/annotate/{id}
GET  /api/health
```

### Output Formats

```bash
libretto search "query"              # Human-readable
libretto search "query" --format yaml
libretto search "query" --format json
libretto search "query" --format ids  # For piping
libretto search "query" --count
```

---

## LifeMaestro Integration

### Architecture

Skills call REST API directly (no MCP layer for token efficiency):

```
LifeMaestro
└── .claude/skills/libretto/
    ├── SKILL.md           # Triggers on "recall", "search", etc.
    └── scripts/
        ├── search.sh      # curl → /api/search
        ├── timeline.sh    # curl → /api/timeline
        └── person.sh      # curl → /api/person
```

### Transport

HTTPS over Tailscale mesh - no exposed ports, private network.

### Authentication

API key in environment variable, validated by Libretto API.

---

## Backup Strategy

### Topology

```
┌─────────────────────────────────────────────────────────────────┐
│  TIER 1: PRIMARY (Hetzner VPS + Storage Box)                    │
│  └── Live system, ZFS snapshots (hourly)                        │
└─────────────────────────┬───────────────────────────────────────┘
                          │ restic (hourly)
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  TIER 2: LOCAL (Windows machine)                                │
│  └── restic repo                                                │
│  └── Backblaze Personal Backup ($9/mo unlimited)                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  TIER 3: COLD (AWS Glacier Deep Archive)                        │
│  └── restic repo, monthly sync                                  │
│  └── ~$4/mo for 2TB                                             │
└─────────────────────────────────────────────────────────────────┘
```

### Tools

- **Local snapshots:** ZFS (instant, on Hetzner)
- **Remote backup:** restic (encrypted, deduplicated, agnostic)
- **Verification:** Weekly full checksum, monthly restore test

### What's Backed Up

| Component | Backed Up | Notes |
|-----------|-----------|-------|
| vault/ | Yes | Critical |
| chain/ | Yes | Critical |
| annotations/ | Yes | Critical |
| checkpoints/ | Yes | Critical |
| index/ | No | Rebuildable |
| state/ | Yes | Sync cursors |
| Keys | Bitwarden | Separate from data |

---

## Recovery

### Prerequisites (in Bitwarden)

- age private key
- minisign private key
- restic password
- API key
- Tailscale auth key

### Bootstrap Script

```bash
#!/bin/bash
# bootstrap.sh <source>

RESTORE_FROM="${1:-windows}"

# Install dependencies
apt install -y age minisign restic

# Restore from backup
restic -r $RESTORE_FROM restore latest --target /libretto

# Verify chain
libretto verify

# Rebuild index
libretto index rebuild

# Start daemon
libretto daemon start

# Health check
libretto health
```

### Recovery Times

| Scenario | Time | From |
|----------|------|------|
| Index corruption | 10-30 min | Rebuild |
| Hetzner dies | 1-2 hours | Windows |
| Hetzner + Windows | 4-8 hours | Backblaze Personal |
| Everything | 12-48 hours | Glacier |

---

## Cost Estimate

| Component | Monthly Cost |
|-----------|--------------|
| Hetzner VPS (CX22) | ~€5 |
| Hetzner Storage Box (5TB) | ~€13 |
| Backblaze Personal | $9 |
| AWS Glacier (2TB) | ~$4 |
| **Total** | **~$35/month** |

---

## Implementation Phases

1. **Core** - Directory structure, chain, vault, verify
2. **First connector** - Gmail ingestion + backfill
3. **Index** - SQLite, FTS, basic search
4. **API** - REST endpoints
5. **Maestro skill** - Integration with LifeMaestro
6. **More connectors** - Photos, calendar, slack
7. **Backup** - restic + ZFS setup
8. **Checkpoints** - Merkle roots, signing
9. **Daemon** - Continuous ingestion

---

## Appendix: Type-Specific Meta Fields

### Email
```yaml
meta:
  message_id: "<123@example.com>"
  from: "john@example.com"
  to: ["me@example.com"]
  cc: []
  subject: "Subject line"
  thread_id: "thread_xyz"
  has_attachments: true
```

### Photo/Video
```yaml
meta:
  filename: "IMG_1234.jpg"
  album: "Japan 2024"
  dimensions: {w: 4032, h: 3024}
  duration: null  # For video
  location: {lat: 35.6762, lon: 139.6503}
  camera: "iPhone 15 Pro"
  taken_at: "2024-03-15T14:22:00Z"
```

### Calendar
```yaml
meta:
  event_id: "gcal_xyz789"
  title: "Team Standup"
  start: "2025-01-30T11:00:00Z"
  end: "2025-01-30T11:30:00Z"
  location: "Zoom"
  attendees: ["brad@company.com"]
```

### Slack
```yaml
meta:
  team: "T12345"
  channel: "C67890"
  channel_name: "engineering"
  user: "U11111"
  user_name: "brad"
  thread_ts: "1706531234.567890"
```

### Location
```yaml
meta:
  lat: 37.7749
  lon: -122.4194
  accuracy: 10
  device: "iphone"
```

### Health (Garmin)
```yaml
meta:
  metric: "sleep"
  date: "2025-01-28"
  summary:
    duration: 28800
    deep: 7200
    light: 18000
    rem: 3600
```

### Financial
```yaml
meta:
  account: "checking_1234"
  transaction_id: "txn_abc"
  amount: -42.50
  currency: "USD"
  merchant: "Coffee Shop"
  category: "food"
```
