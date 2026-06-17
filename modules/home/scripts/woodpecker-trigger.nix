# Woodpecker CI/CD Local Trigger Script
# Provides a way to trigger Woodpecker pipelines locally without GitHub webhooks.
# Usage: woodpecker-trigger [repo] [branch] [pipeline]
# Can be used as a git post-receive hook or run manually.
{pkgs, ...}:
pkgs.writeShellScriptBin "woodpecker-trigger" ''
  #!/usr/bin/env bash
  set -euo pipefail

  # Colors
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'

  info() { echo -e "''${BLUE}ℹ''${NC}  ''$*"; }
  ok() { echo -e "''${GREEN}✔''${NC}  ''$*"; }
  warn() { echo -e "''${YELLOW}⚠''${NC}  ''$*"; }
  err() { echo -e "''${RED}✘''${NC}  ''$*" >&2; }
  die() { err "''$*"; exit 1; }

  # Load config from environment or ~/.config/woodpecker/trigger.conf
  CONFIG_FILE="''${HOME}/.config/woodpecker/trigger.conf"
  if [[ -f "''$CONFIG_FILE" ]]; then
    source "''$CONFIG_FILE"
  fi

  WOODPECKER_URL="''${WOODPECKER_URL:-http://woodpecker.homelab.lan}"
  WOODPECKER_TOKEN="''${WOODPECKER_TOKEN:-}"

  usage() {
    cat <<'EOF'
woodpecker-trigger - Trigger Woodpecker CI/CD pipelines locally

Usage:
  woodpecker-trigger [options] <repo> [branch] [pipeline]

Arguments:
  repo       Repository name (e.g., "owner/repo" or just "repo")
  branch     Branch to build (default: current git branch or "main")
  pipeline   Pipeline name to trigger (default: default pipeline)

Options:
  -u, --url URL        Woodpecker server URL (default: http://woodpecker.homelab.lan)
  -t, --token TOKEN    API token (or set WOODPECKER_TOKEN env var)
  -f, --file FILE      Pipeline file (default: .woodpecker.yml)
  -h, --help           Show this help

Examples:
  woodpecker-trigger myorg/myrepo main
  woodpecker-trigger myrepo feature-branch deploy
  woodpecker-trigger --token $TOKEN myorg/myrepo main

Configuration file (~/.config/woodpecker/trigger.conf):
  WOODPECKER_URL="http://woodpecker.homelab.lan"
  WOODPECKER_TOKEN="your-api-token-here"

Get API token from: Woodpecker UI > User Settings > API Token
EOF
  }

  # Parse arguments
  REPO=""
  BRANCH=""
  PIPELINE=""
  PIPELINE_FILE=".woodpecker.yml"

  while [[ ''$# -gt 0 ]]; do
    case "''$1" in
      -u|--url) WOODPECKER_URL="''$2"; shift 2 ;;
      -t|--token) WOODPECKER_TOKEN="''$2"; shift 2 ;;
      -f|--file) PIPELINE_FILE="''$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      -*) die "Unknown option: ''$1" ;;
      *)
        if [[ -z "''$REPO" ]]; then
          REPO="''$1"
        elif [[ -z "''$BRANCH" ]]; then
          BRANCH="''$1"
        elif [[ -z "''$PIPELINE" ]]; then
          PIPELINE="''$1"
        else
          die "Too many arguments"
        fi
        shift
        ;;
    esac
  done

  [[ -n "''$REPO" ]] || die "Repository required. Use -h for help."

  # Auto-detect branch if not provided
  if [[ -z "''$BRANCH" ]]; then
    if git rev-parse --git-dir &>/dev/null; then
      BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
      info "Auto-detected branch: ''$BRANCH"
    else
      BRANCH="main"
      warn "Not in a git repo, defaulting to 'main'"
    fi
  fi

  # Validate token
  [[ -n "''$WOODPECKER_TOKEN" ]] || die "WOODPECKER_TOKEN not set. Use -t or configure ~/.config/woodpecker/trigger.conf"

  # Get repo ID from Woodpecker
  info "Looking up repository: ''$REPO"
  REPO_INFO=$(curl -s -H "Authorization: Bearer ''$WOODPECKER_TOKEN" \
    "''${WOODPECKER_URL}/api/repos/''${REPO}" 2>/dev/null) || die "Failed to connect to Woodpecker at ''$WOODPECKER_URL"

  REPO_ID=$(echo "''$REPO_INFO" | jq -r '.id // empty' 2>/dev/null)
  [[ -n "''$REPO_ID" && "''$REPO_ID" != "null" ]] || die "Repository not found in Woodpecker: ''$REPO"

  ok "Found repository ID: ''$REPO_ID"

  # Trigger pipeline
  info "Triggering pipeline for branch: ''$BRANCH"
  TRIGGER_RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer ''$WOODPECKER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"branch\":\"''$BRANCH\",\"pipeline\":\"''$PIPELINE\"}" \
    "''${WOODPECKER_URL}/api/repos/''${REPO_ID}/builds" 2>/dev/null) || die "Failed to trigger pipeline"

  BUILD_NUMBER=$(echo "''$TRIGGER_RESPONSE" | jq -r '.number // empty' 2>/dev/null)
  if [[ -n "''$BUILD_NUMBER" && "''$BUILD_NUMBER" != "null" ]]; then
    ok "Pipeline triggered successfully! Build #''$BUILD_NUMBER"
    info "View at: ''${WOODPECKER_URL}/repos/''${REPO}/builds/''${BUILD_NUMBER}"
  else
    ERROR_MSG=$(echo "''$TRIGGER_RESPONSE" | jq -r '.message // .error // "Unknown error"' 2>/dev/null)
    die "Failed to trigger pipeline: ''$ERROR_MSG"
  fi
''