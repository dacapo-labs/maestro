# LifeLibretto

Immutable, cryptographically-verified life archive.

## What is it?

LifeLibretto is your guaranteed memory - an append-only archive of your digital life with tamper-evident integrity. It serves as the memory layer for [LifeMaestro](https://github.com/sethdf/lifemaestro).

## Core Features

- **Immutable** - Append-only chain, no edits, no deletes
- **Tamper-evident** - Hash-linked entries, any change breaks the chain
- **Encrypted** - age encryption at rest, keys in Bitwarden
- **Verifiable** - Signed Merkle root checkpoints
- **Searchable** - Full-text and semantic search
- **Multi-source** - Email, photos, calendar, chat, health, financial, location

## Architecture

```
libretto/
├── vault/          # Encrypted content (age)
├── chain/          # Hash-chained YAML manifests
├── annotations/    # Corrections and tags (also chained)
├── checkpoints/    # Signed Merkle roots
└── index/          # SQLite + vectors (rebuildable)
```

## Data Sources

| Source | Type |
|--------|------|
| Gmail / Outlook | Email |
| Google Photos / iCloud | Photos & Videos |
| Google Calendar / MS365 | Calendar |
| Slack / Telegram | Chat & Notes |
| Garmin | Health & Fitness |
| Teller.io | Financial |
| OwnTracks | Location |
| Browser History | Browsing |
| ActivityWatch | App Usage |

## Status

**Design complete.** See [DESIGN.md](DESIGN.md) for full specification.

## License

Private
