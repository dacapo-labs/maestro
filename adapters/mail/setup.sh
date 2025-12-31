#!/usr/bin/env bash
# adapters/mail/setup.sh - Email and calendar setup
# Configures Himalaya (Gmail/MS365), gcalcli, and thallo
# Reads OAuth credentials from Bitwarden

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAESTRO_ROOT="${MAESTRO_ROOT:-$(dirname "$(dirname "$SCRIPT_DIR")")}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Bitwarden credential names (customize as needed)
BW_GMAIL_OAUTH="gmail-oauth-credentials"
BW_MS365_OAUTH="ms365-oauth-credentials"
BW_GCAL_OAUTH="gcalcli-oauth-credentials"

usage() {
    cat <<EOF
Usage: $(basename "$0") [command] [options]

Commands:
    all                 Setup all mail/calendar tools
    himalaya            Setup Himalaya email client
    gcalcli             Setup Google Calendar CLI
    thallo              Setup Thallo calendar manager
    status              Check installation status

Options:
    --zone <name>       Configure for specific zone (work/personal)
    --gmail             Configure Gmail account (Himalaya)
    --ms365             Configure Microsoft 365 account (Himalaya)
    --help              Show this help message

Examples:
    $(basename "$0") all --zone work
    $(basename "$0") himalaya --gmail
    $(basename "$0") gcalcli --zone personal
EOF
}

# Ensure Bitwarden is unlocked
ensure_bw_unlocked() {
    if ! bw unlock --check &>/dev/null; then
        log_info "Unlocking Bitwarden..."
        source "$MAESTRO_ROOT/bin/bw-unlock" || {
            log_error "Failed to unlock Bitwarden"
            return 1
        }
    fi
}

# Get OAuth credentials from Bitwarden
get_bw_credential() {
    local item_name="$1"
    local field="${2:-notes}"

    ensure_bw_unlocked || return 1

    if [[ "$field" == "notes" ]]; then
        bw get notes "$item_name" 2>/dev/null
    else
        bw get item "$item_name" 2>/dev/null | jq -r ".fields[] | select(.name==\"$field\") | .value"
    fi
}

# Check if command exists
cmd_exists() {
    command -v "$1" &>/dev/null
}

# Setup Himalaya email client
setup_himalaya() {
    local account_type="${1:-gmail}"
    local zone="${2:-personal}"

    log_info "Setting up Himalaya for $account_type ($zone zone)..."

    if ! cmd_exists himalaya; then
        log_warn "Himalaya not installed. Install with: cargo install himalaya"
        return 1
    fi

    local himalaya_config="$CONFIG_DIR/himalaya/config.toml"
    mkdir -p "$(dirname "$himalaya_config")"

    case "$account_type" in
        gmail)
            log_info "Fetching Gmail OAuth credentials from Bitwarden..."
            local oauth_json
            oauth_json=$(get_bw_credential "$BW_GMAIL_OAUTH" "notes") || {
                log_warn "Gmail OAuth credentials not found in Bitwarden"
                log_info "Creating template config. You'll need to add credentials manually."
                oauth_json=""
            }

            # Extract OAuth fields if available
            local client_id client_secret refresh_token
            if [[ -n "$oauth_json" ]]; then
                client_id=$(echo "$oauth_json" | jq -r '.client_id // empty')
                client_secret=$(echo "$oauth_json" | jq -r '.client_secret // empty')
                refresh_token=$(echo "$oauth_json" | jq -r '.refresh_token // empty')
            fi

            cat >> "$himalaya_config" <<EOF

[accounts.$zone-gmail]
default = true
email = "<your-email@gmail.com>"
display-name = "Your Name"

backend.type = "imap"
backend.host = "imap.gmail.com"
backend.port = 993
backend.encryption = "tls"
backend.login = "<your-email@gmail.com>"
backend.auth.type = "oauth2"
backend.auth.client-id = "${client_id:-<client-id>}"
backend.auth.client-secret = "${client_secret:-<client-secret>}"
backend.auth.refresh-token = "${refresh_token:-<refresh-token>}"
backend.auth.auth-url = "https://accounts.google.com/o/oauth2/v2/auth"
backend.auth.token-url = "https://oauth2.googleapis.com/token"
backend.auth.scopes = ["https://mail.google.com/"]

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.gmail.com"
message.send.backend.port = 465
message.send.backend.encryption = "tls"
message.send.backend.login = "<your-email@gmail.com>"
message.send.backend.auth.type = "oauth2"
message.send.backend.auth.client-id = "${client_id:-<client-id>}"
message.send.backend.auth.client-secret = "${client_secret:-<client-secret>}"
message.send.backend.auth.refresh-token = "${refresh_token:-<refresh-token>}"
message.send.backend.auth.auth-url = "https://accounts.google.com/o/oauth2/v2/auth"
message.send.backend.auth.token-url = "https://oauth2.googleapis.com/token"
EOF
            log_info "Gmail config added to $himalaya_config"
            ;;

        ms365)
            log_info "Fetching MS365 OAuth credentials from Bitwarden..."
            local oauth_json
            oauth_json=$(get_bw_credential "$BW_MS365_OAUTH" "notes") || {
                log_warn "MS365 OAuth credentials not found in Bitwarden"
                oauth_json=""
            }

            local client_id tenant_id refresh_token
            if [[ -n "$oauth_json" ]]; then
                client_id=$(echo "$oauth_json" | jq -r '.client_id // empty')
                tenant_id=$(echo "$oauth_json" | jq -r '.tenant_id // empty')
                refresh_token=$(echo "$oauth_json" | jq -r '.refresh_token // empty')
            fi

            cat >> "$himalaya_config" <<EOF

[accounts.$zone-ms365]
email = "<your-email@company.com>"
display-name = "Your Name"

backend.type = "imap"
backend.host = "outlook.office365.com"
backend.port = 993
backend.encryption = "tls"
backend.login = "<your-email@company.com>"
backend.auth.type = "oauth2"
backend.auth.client-id = "${client_id:-<client-id>}"
backend.auth.auth-url = "https://login.microsoftonline.com/${tenant_id:-common}/oauth2/v2.0/authorize"
backend.auth.token-url = "https://login.microsoftonline.com/${tenant_id:-common}/oauth2/v2.0/token"
backend.auth.refresh-token = "${refresh_token:-<refresh-token>}"
backend.auth.scopes = ["https://outlook.office365.com/IMAP.AccessAsUser.All", "https://outlook.office365.com/SMTP.Send"]

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.office365.com"
message.send.backend.port = 587
message.send.backend.encryption = "starttls"
message.send.backend.login = "<your-email@company.com>"
message.send.backend.auth.type = "oauth2"
message.send.backend.auth.client-id = "${client_id:-<client-id>}"
message.send.backend.auth.auth-url = "https://login.microsoftonline.com/${tenant_id:-common}/oauth2/v2.0/authorize"
message.send.backend.auth.token-url = "https://login.microsoftonline.com/${tenant_id:-common}/oauth2/v2.0/token"
message.send.backend.auth.refresh-token = "${refresh_token:-<refresh-token>}"
EOF
            log_info "MS365 config added to $himalaya_config"
            ;;
    esac

    log_info "Himalaya setup complete. Edit $himalaya_config to finalize credentials."
}

# Setup gcalcli for Google Calendar
setup_gcalcli() {
    local zone="${1:-personal}"

    log_info "Setting up gcalcli ($zone zone)..."

    if ! cmd_exists gcalcli; then
        log_warn "gcalcli not installed. Install with: pip install gcalcli"
        return 1
    fi

    local gcalcli_dir="$CONFIG_DIR/gcalcli"
    mkdir -p "$gcalcli_dir"

    log_info "Fetching gcalcli OAuth credentials from Bitwarden..."
    local oauth_json
    oauth_json=$(get_bw_credential "$BW_GCAL_OAUTH" "notes") || {
        log_warn "gcalcli OAuth credentials not found in Bitwarden"
        oauth_json=""
    }

    if [[ -n "$oauth_json" ]]; then
        echo "$oauth_json" > "$gcalcli_dir/oauth"
        chmod 600 "$gcalcli_dir/oauth"
        log_info "OAuth credentials saved to $gcalcli_dir/oauth"
    else
        log_info "Run 'gcalcli init' to authenticate interactively"
    fi

    # Create gcalcli config
    cat > "$gcalcli_dir/gcalclirc" <<EOF
[gcalcli]
# Default calendar
default-calendar = primary

# Output settings
detail-all = false
tsv = false

# Week starts on Monday
week-start = monday
EOF

    log_info "gcalcli config created at $gcalcli_dir/gcalclirc"
}

# Setup thallo calendar manager
setup_thallo() {
    local zone="${1:-personal}"

    log_info "Setting up thallo ($zone zone)..."

    if ! cmd_exists thallo; then
        log_warn "thallo not installed. See: https://github.com/thallocli/thallo"
        return 1
    fi

    local thallo_config="$CONFIG_DIR/thallo/config.toml"
    mkdir -p "$(dirname "$thallo_config")"

    cat > "$thallo_config" <<EOF
# Thallo calendar configuration
# Zone: $zone

[general]
default_calendar = "primary"
timezone = "America/New_York"

[google]
# OAuth handled via gcalcli or separate thallo auth
enabled = true

[microsoft]
# For MS365 calendar integration
enabled = false
# tenant_id = "<tenant-id>"
# client_id = "<client-id>"
EOF

    log_info "thallo config created at $thallo_config"
}

# Check status of all tools
check_status() {
    echo "=== Mail/Calendar Tools Status ==="
    echo

    for tool in himalaya gcalcli thallo; do
        if cmd_exists "$tool"; then
            echo -e "$tool: ${GREEN}installed${NC}"
        else
            echo -e "$tool: ${RED}not installed${NC}"
        fi
    done

    echo
    echo "=== Config Files ==="

    local configs=(
        "$CONFIG_DIR/himalaya/config.toml"
        "$CONFIG_DIR/gcalcli/gcalclirc"
        "$CONFIG_DIR/thallo/config.toml"
    )

    for cfg in "${configs[@]}"; do
        if [[ -f "$cfg" ]]; then
            echo -e "$cfg: ${GREEN}exists${NC}"
        else
            echo -e "$cfg: ${YELLOW}not found${NC}"
        fi
    done
}

# Main
main() {
    local cmd="${1:-}"
    shift || true

    local zone="personal"
    local account_type="gmail"

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --zone)
                zone="$2"
                shift 2
                ;;
            --gmail)
                account_type="gmail"
                shift
                ;;
            --ms365)
                account_type="ms365"
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done

    case "$cmd" in
        all)
            setup_himalaya "$account_type" "$zone"
            setup_gcalcli "$zone"
            setup_thallo "$zone"
            ;;
        himalaya)
            setup_himalaya "$account_type" "$zone"
            ;;
        gcalcli)
            setup_gcalcli "$zone"
            ;;
        thallo)
            setup_thallo "$zone"
            ;;
        status)
            check_status
            ;;
        ""|--help|-h)
            usage
            ;;
        *)
            log_error "Unknown command: $cmd"
            usage
            exit 1
            ;;
    esac
}

main "$@"
