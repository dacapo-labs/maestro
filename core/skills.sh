#!/usr/bin/env bash
# lifemaestro/core/skills.sh - Skill-level AI integration framework
#
# Each skill decides its own AI usage level:
#   - none:   Pure bash, zero AI tokens
#   - light:  Single-shot AI call (categorize, classify, extract)
#   - medium: Multi-step AI (draft, refine, summarize)
#   - full:   Interactive AI session
#
# This approach is MORE TOKEN EFFICIENT than MCP because:
# - MCP tools load 5000+ tokens of tool definitions in EVERY conversation
# - Skills invoke AI only when needed, for specific purposes
# - User controls exactly where AI tokens are spent

# ============================================
# SKILL REGISTRY
# ============================================

declare -A SKILL_REGISTRY
declare -A SKILL_AI_LEVEL

# Register a skill with its AI level
skill::register() {
    local name="$1"
    local func="$2"
    local ai_level="${3:-none}"  # none, light, medium, full
    local description="${4:-}"

    SKILL_REGISTRY[$name]="$func"
    SKILL_AI_LEVEL[$name]="$ai_level"

    maestro::log "Registered skill: $name (AI: $ai_level)"
}

# Get AI level for a skill
skill::ai_level() {
    local name="$1"
    echo "${SKILL_AI_LEVEL[$name]:-none}"
}

# Run a skill
skill::run() {
    local name="$1"
    shift

    local func="${SKILL_REGISTRY[$name]}"
    if [[ -z "$func" ]]; then
        cli::error "Unknown skill: $name"
        return 1
    fi

    local ai_level=$(skill::ai_level "$name")
    cli::debug "Running skill '$name' (AI level: $ai_level)"

    # Track AI usage for reporting
    local start_time=$(date +%s)

    # Run the skill
    $func "$@"
    local result=$?

    local end_time=$(date +%s)
    maestro::log "Skill $name completed in $((end_time - start_time))s (AI: $ai_level)"

    return $result
}

# List all skills
skill::list() {
    cli::out "Available Skills:"
    cli::out ""
    for name in "${!SKILL_REGISTRY[@]}"; do
        local ai_level="${SKILL_AI_LEVEL[$name]}"
        local indicator=""
        case "$ai_level" in
            none)   indicator="○" ;;
            light)  indicator="◐" ;;
            medium) indicator="◑" ;;
            full)   indicator="●" ;;
        esac
        cli::out "  $indicator $name ($ai_level)"
    done
    cli::out ""
    cli::out "Legend: ○ none  ◐ light  ◑ medium  ● full"
}

# ============================================
# AI HELPERS FOR SKILLS
# ============================================
#
# Strategy for provider-agnostic AI calls:
# 1. Use 'llm' tool if available (supports 20+ providers via plugins)
# 2. Fall back to provider-specific CLI with proper flags
# 3. Use direct API calls as last resort
#
# This ensures skills work with ANY AI provider, not just Claude.

# Check if llm tool is available and configured
skill::_has_llm() {
    command -v llm &>/dev/null
}

# Escape JSON string
skill::_json_escape() {
    local str="$1"
    # Escape backslashes, quotes, and newlines
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

# Single-shot AI call (for light AI skills)
# Uses the fastest/cheapest model appropriate
skill::ai_oneshot() {
    local prompt="$1"
    local provider="${2:-$(maestro::config 'ai.default_fast_provider' 'ollama')}"

    # Prefer 'llm' tool - it's provider-agnostic and handles auth
    if skill::_has_llm && [[ "$provider" != "ollama" ]]; then
        # llm can use any configured model
        case "$provider" in
            claude|anthropic)
                echo "$prompt" | llm -m claude-3-5-haiku-latest 2>/dev/null
                ;;
            openai|chatgpt|gpt)
                echo "$prompt" | llm -m gpt-4o-mini 2>/dev/null
                ;;
            gemini|google)
                echo "$prompt" | llm -m gemini-1.5-flash 2>/dev/null
                ;;
            *)
                # Use llm's default model
                echo "$prompt" | llm 2>/dev/null
                ;;
        esac
        return
    fi

    # Provider-specific fallbacks
    case "$provider" in
        ollama)
            local model=$(maestro::config 'ai.ollama.default_model' 'llama3.2')
            echo "$prompt" | ollama run "$model" 2>/dev/null
            ;;
        claude|anthropic)
            if command -v claude &>/dev/null; then
                # Claude Code CLI
                echo "$prompt" | claude --print 2>/dev/null
            elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
                # Direct API call
                local escaped_prompt=$(skill::_json_escape "$prompt")
                curl -s https://api.anthropic.com/v1/messages \
                    -H "Content-Type: application/json" \
                    -H "x-api-key: $ANTHROPIC_API_KEY" \
                    -H "anthropic-version: 2023-06-01" \
                    -d "{\"model\": \"claude-3-5-haiku-20241022\", \"max_tokens\": 1024, \"messages\": [{\"role\": \"user\", \"content\": \"$escaped_prompt\"}]}" \
                    | jq -r '.content[0].text // .error.message // "Error"'
            else
                cli::error "No Claude CLI or API key available"
                return 1
            fi
            ;;
        openai|chatgpt|gpt)
            if command -v openai &>/dev/null; then
                # OpenAI CLI (if installed)
                echo "$prompt" | openai api chat.completions.create -m gpt-4o-mini 2>/dev/null
            elif [[ -n "${OPENAI_API_KEY:-}" ]]; then
                # Direct API call
                local escaped_prompt=$(skill::_json_escape "$prompt")
                curl -s https://api.openai.com/v1/chat/completions \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $OPENAI_API_KEY" \
                    -d "{\"model\": \"gpt-4o-mini\", \"messages\": [{\"role\": \"user\", \"content\": \"$escaped_prompt\"}]}" \
                    | jq -r '.choices[0].message.content // .error.message // "Error"'
            else
                cli::error "No OpenAI CLI or API key available"
                return 1
            fi
            ;;
        gemini|google)
            if [[ -n "${GEMINI_API_KEY:-}" ]]; then
                local escaped_prompt=$(skill::_json_escape "$prompt")
                curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$GEMINI_API_KEY" \
                    -H "Content-Type: application/json" \
                    -d "{\"contents\": [{\"parts\": [{\"text\": \"$escaped_prompt\"}]}]}" \
                    | jq -r '.candidates[0].content.parts[0].text // .error.message // "Error"'
            else
                cli::error "No Gemini API key available"
                return 1
            fi
            ;;
        mistral)
            if [[ -n "${MISTRAL_API_KEY:-}" ]]; then
                local escaped_prompt=$(skill::_json_escape "$prompt")
                curl -s https://api.mistral.ai/v1/chat/completions \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $MISTRAL_API_KEY" \
                    -d "{\"model\": \"mistral-small-latest\", \"messages\": [{\"role\": \"user\", \"content\": \"$escaped_prompt\"}]}" \
                    | jq -r '.choices[0].message.content // .error.message // "Error"'
            else
                cli::error "No Mistral API key available"
                return 1
            fi
            ;;
        groq)
            if [[ -n "${GROQ_API_KEY:-}" ]]; then
                local escaped_prompt=$(skill::_json_escape "$prompt")
                curl -s https://api.groq.com/openai/v1/chat/completions \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $GROQ_API_KEY" \
                    -d "{\"model\": \"llama-3.1-8b-instant\", \"messages\": [{\"role\": \"user\", \"content\": \"$escaped_prompt\"}]}" \
                    | jq -r '.choices[0].message.content // .error.message // "Error"'
            else
                cli::error "No Groq API key available"
                return 1
            fi
            ;;
        llm)
            # Direct llm tool usage
            echo "$prompt" | llm 2>/dev/null
            ;;
        *)
            cli::error "Unknown AI provider: $provider"
            cli::error "Supported: ollama, claude, openai, gemini, mistral, groq, llm"
            return 1
            ;;
    esac
}

# Multi-turn AI (for medium AI skills)
# Combines system prompt with user prompt for providers that support it
skill::ai_converse() {
    local system_prompt="$1"
    local user_prompt="$2"
    local provider="${3:-$(maestro::config 'ai.default_provider' 'claude')}"

    # Prefer 'llm' tool - it handles system prompts universally
    if skill::_has_llm && [[ "$provider" != "ollama" ]]; then
        case "$provider" in
            claude|anthropic)
                echo "$user_prompt" | llm -m claude-3-5-sonnet-latest -s "$system_prompt" 2>/dev/null
                ;;
            openai|chatgpt|gpt)
                echo "$user_prompt" | llm -m gpt-4o -s "$system_prompt" 2>/dev/null
                ;;
            gemini|google)
                echo "$user_prompt" | llm -m gemini-1.5-pro -s "$system_prompt" 2>/dev/null
                ;;
            *)
                echo "$user_prompt" | llm -s "$system_prompt" 2>/dev/null
                ;;
        esac
        return
    fi

    # Provider-specific fallbacks
    case "$provider" in
        ollama)
            local model=$(maestro::config 'ai.ollama.default_model' 'llama3.2')
            # Ollama doesn't have native system prompt in CLI, prepend it
            printf "System: %s\n\nUser: %s" "$system_prompt" "$user_prompt" | ollama run "$model" 2>/dev/null
            ;;
        claude|anthropic)
            if command -v claude &>/dev/null; then
                echo "$user_prompt" | claude --system-prompt "$system_prompt" --print 2>/dev/null
            elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
                local escaped_system=$(skill::_json_escape "$system_prompt")
                local escaped_user=$(skill::_json_escape "$user_prompt")
                curl -s https://api.anthropic.com/v1/messages \
                    -H "Content-Type: application/json" \
                    -H "x-api-key: $ANTHROPIC_API_KEY" \
                    -H "anthropic-version: 2023-06-01" \
                    -d "{\"model\": \"claude-3-5-sonnet-20241022\", \"max_tokens\": 4096, \"system\": \"$escaped_system\", \"messages\": [{\"role\": \"user\", \"content\": \"$escaped_user\"}]}" \
                    | jq -r '.content[0].text // .error.message // "Error"'
            else
                # Fallback: combine prompts
                skill::ai_oneshot "$system_prompt\n\n$user_prompt" "$provider"
            fi
            ;;
        openai|chatgpt|gpt)
            if [[ -n "${OPENAI_API_KEY:-}" ]]; then
                local escaped_system=$(skill::_json_escape "$system_prompt")
                local escaped_user=$(skill::_json_escape "$user_prompt")
                curl -s https://api.openai.com/v1/chat/completions \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $OPENAI_API_KEY" \
                    -d "{\"model\": \"gpt-4o\", \"messages\": [{\"role\": \"system\", \"content\": \"$escaped_system\"}, {\"role\": \"user\", \"content\": \"$escaped_user\"}]}" \
                    | jq -r '.choices[0].message.content // .error.message // "Error"'
            else
                skill::ai_oneshot "$system_prompt\n\n$user_prompt" "$provider"
            fi
            ;;
        gemini|google)
            # Gemini doesn't have a separate system message, prepend to user content
            local combined="Instructions: $system_prompt\n\nTask: $user_prompt"
            skill::ai_oneshot "$combined" "$provider"
            ;;
        mistral|groq)
            if [[ -n "${MISTRAL_API_KEY:-}" ]] && [[ "$provider" == "mistral" ]]; then
                local escaped_system=$(skill::_json_escape "$system_prompt")
                local escaped_user=$(skill::_json_escape "$user_prompt")
                curl -s https://api.mistral.ai/v1/chat/completions \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $MISTRAL_API_KEY" \
                    -d "{\"model\": \"mistral-medium-latest\", \"messages\": [{\"role\": \"system\", \"content\": \"$escaped_system\"}, {\"role\": \"user\", \"content\": \"$escaped_user\"}]}" \
                    | jq -r '.choices[0].message.content // .error.message // "Error"'
            elif [[ -n "${GROQ_API_KEY:-}" ]] && [[ "$provider" == "groq" ]]; then
                local escaped_system=$(skill::_json_escape "$system_prompt")
                local escaped_user=$(skill::_json_escape "$user_prompt")
                curl -s https://api.groq.com/openai/v1/chat/completions \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $GROQ_API_KEY" \
                    -d "{\"model\": \"llama-3.1-70b-versatile\", \"messages\": [{\"role\": \"system\", \"content\": \"$escaped_system\"}, {\"role\": \"user\", \"content\": \"$escaped_user\"}]}" \
                    | jq -r '.choices[0].message.content // .error.message // "Error"'
            else
                skill::ai_oneshot "$system_prompt\n\n$user_prompt" "$provider"
            fi
            ;;
        llm)
            echo "$user_prompt" | llm -s "$system_prompt" 2>/dev/null
            ;;
        *)
            # Unknown provider - combine prompts and try oneshot
            skill::ai_oneshot "$system_prompt\n\n$user_prompt" "$provider"
            ;;
    esac
}

# Interactive AI session (for full AI skills)
skill::ai_interactive() {
    local context="${1:-}"
    local provider="${2:-$(maestro::config 'ai.default_provider' 'claude')}"

    session::ai "$provider"
}

# List available AI providers
skill::ai_providers() {
    cli::out "Available AI Providers for Skills:"
    cli::out ""
    cli::out "Provider       CLI Tool      API Key"
    cli::out "--------       --------      -------"

    # Check llm (universal)
    if skill::_has_llm; then
        cli::out "llm            ✅ llm        (manages own keys)"
    fi

    # Check each provider
    local providers=("ollama" "claude" "openai" "gemini" "mistral" "groq")
    local cli_tools=("ollama" "claude" "openai" "gemini" "mistral" "groq")
    local env_vars=("" "ANTHROPIC_API_KEY" "OPENAI_API_KEY" "GEMINI_API_KEY" "MISTRAL_API_KEY" "GROQ_API_KEY")

    for i in "${!providers[@]}"; do
        local provider="${providers[$i]}"
        local cli="${cli_tools[$i]}"
        local env="${env_vars[$i]}"

        local cli_status="⚪"
        local key_status="⚪"

        if command -v "$cli" &>/dev/null; then
            cli_status="✅"
        fi

        if [[ -n "$env" ]] && [[ -n "${!env:-}" ]]; then
            key_status="✅"
        elif [[ -z "$env" ]]; then
            key_status="n/a"
        fi

        printf "%-14s %-13s %s\n" "$provider" "$cli_status $cli" "$key_status ${env:-}"
    done
}

# ============================================
# LOAD SKILLS FROM DIRECTORY
# ============================================

skill::load_all() {
    local skills_dir="$MAESTRO_ROOT/skills"

    [[ -d "$skills_dir" ]] || return

    for skill_file in "$skills_dir"/*.sh; do
        [[ -f "$skill_file" ]] || continue
        source "$skill_file"
        maestro::log "Loaded skill file: $(basename "$skill_file")"
    done
}

# Auto-load skills on source
skill::load_all

# ============================================
# BUILT-IN SKILLS
# ============================================

# --- CREDENTIAL SKILLS (No AI) ---

_skill_creds_status() {
    keepalive::status
}
skill::register "creds" "_skill_creds_status" "none" "Show credential status"

_skill_creds_refresh() {
    AWS_REFRESH_THRESHOLD=999999 OAUTH_REFRESH_THRESHOLD=999999 keepalive::check_all
}
skill::register "creds-refresh" "_skill_creds_refresh" "none" "Force refresh credentials"

# --- SESSION SKILLS (No AI) ---

_skill_session_new() {
    local type="${1:-exploration}"
    local name="${2:-}"

    if [[ -z "$name" ]]; then
        cli::die_usage "Usage: skill session-new <type> <name>"
    fi

    session::create "$type" "$name"
}
skill::register "session-new" "_skill_session_new" "none" "Create new session"

_skill_session_list() {
    session::list "$@"
}
skill::register "session-list" "_skill_session_list" "none" "List sessions"

# --- CONTEXT SKILLS (No AI) ---

_skill_context_switch() {
    local ctx="${1:-}"
    [[ -z "$ctx" ]] && cli::die_usage "Usage: skill context-switch <work|home>"
    session::switch "$ctx"
}
skill::register "context-switch" "_skill_context_switch" "none" "Switch context"

_skill_context_show() {
    session::show_context
}
skill::register "context" "_skill_context_show" "none" "Show current context"

# --- QUICK AI SKILLS (Light AI) ---

_skill_categorize() {
    local input="${1:-}"

    if [[ -z "$input" ]] && cli::has_stdin; then
        input=$(cat)
    fi

    [[ -z "$input" ]] && cli::die_usage "Usage: skill categorize <text> or pipe input"

    skill::ai_oneshot "Categorize this into one of: work, personal, urgent, info, spam. Just respond with the category name, nothing else.\n\nText: $input"
}
skill::register "categorize" "_skill_categorize" "light" "Categorize text"

_skill_extract_action() {
    local input="${1:-}"

    if [[ -z "$input" ]] && cli::has_stdin; then
        input=$(cat)
    fi

    [[ -z "$input" ]] && cli::die_usage "Usage: skill extract-action <text>"

    skill::ai_oneshot "Extract the main action item from this text. Respond with just the action, starting with a verb. If no action, respond 'None'.\n\nText: $input"
}
skill::register "extract-action" "_skill_extract_action" "light" "Extract action from text"

_skill_sentiment() {
    local input="${1:-}"

    if [[ -z "$input" ]] && cli::has_stdin; then
        input=$(cat)
    fi

    [[ -z "$input" ]] && cli::die_usage "Usage: skill sentiment <text>"

    skill::ai_oneshot "Rate the sentiment: positive, neutral, or negative. Just the word, nothing else.\n\nText: $input"
}
skill::register "sentiment" "_skill_sentiment" "light" "Analyze sentiment"

# --- SUMMARIZATION SKILLS (Medium AI) ---

_skill_summarize() {
    local input="${1:-}"

    if [[ -z "$input" ]] && cli::has_stdin; then
        input=$(cat)
    fi

    [[ -z "$input" ]] && cli::die_usage "Usage: skill summarize <text> or pipe input"

    skill::ai_converse \
        "You are a concise summarizer. Summarize the given text in 2-3 sentences." \
        "$input"
}
skill::register "summarize" "_skill_summarize" "medium" "Summarize text"

_skill_draft_reply() {
    local input="${1:-}"

    if [[ -z "$input" ]] && cli::has_stdin; then
        input=$(cat)
    fi

    [[ -z "$input" ]] && cli::die_usage "Usage: skill draft-reply <email text>"

    local ctx=$(session::current_context)
    local name=$(maestro::config "contexts.$ctx.git.user" "User")

    skill::ai_converse \
        "You are drafting a professional email reply. Be concise and helpful. Sign as '$name'." \
        "Draft a reply to this email:\n\n$input"
}
skill::register "draft-reply" "_skill_draft_reply" "medium" "Draft email reply"

_skill_explain() {
    local input="${1:-}"

    if [[ -z "$input" ]] && cli::has_stdin; then
        input=$(cat)
    fi

    [[ -z "$input" ]] && cli::die_usage "Usage: skill explain <code or text>"

    skill::ai_converse \
        "Explain the following clearly and concisely. If it's code, explain what it does. If it's text, explain the key points." \
        "$input"
}
skill::register "explain" "_skill_explain" "medium" "Explain code or text"

# --- CODING SKILLS (Full AI) ---

_skill_code() {
    skill::ai_interactive "" "claude"
}
skill::register "code" "_skill_code" "full" "Start coding session"

_skill_chat() {
    local provider="${1:-$(maestro::config 'ai.default_provider' 'claude')}"
    skill::ai_interactive "" "$provider"
}
skill::register "chat" "_skill_chat" "full" "Start AI chat session"
