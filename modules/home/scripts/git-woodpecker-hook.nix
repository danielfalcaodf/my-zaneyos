# Git Hook Helper for Woodpecker
# Installs a post-receive hook that triggers Woodpecker on push.
# Usage: git-woodpecker-hook install|uninstall|status
{pkgs, ...}:
pkgs.writeShellScriptBin "git-woodpecker-hook" ''
  #!/usr/bin/env bash
  set -euo pipefail

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

  HOOK_FILE=".git/hooks/post-receive"

  install_hook() {
    [[ -d ".git" ]] || die "Not a git repository (run from repo root)"

    if [[ -f "''$HOOK_FILE" ]] && grep -q "woodpecker-trigger" "''$HOOK_FILE"; then
      warn "Woodpecker hook already installed"
      return
    fi

    cat > "''$HOOK_FILE" <<'HOOK'
#!/usr/bin/env bash
# Woodpecker CI/CD post-receive hook
# Triggers pipeline on push to tracked branches

set -euo pipefail

# Load woodpecker config
CONFIG_FILE="''${HOME}/.config/woodpecker/trigger.conf"
[[ -f "''$CONFIG_FILE" ]] && source "''$CONFIG_FILE"

WOODPECKER_URL="''${WOODPECKER_URL:-http://woodpecker.homelab.lan}"
WOODPECKER_TOKEN="''${WOODPECKER_TOKEN:-}"

[[ -n "''$WOODPECKER_TOKEN" ]] || { echo "WOODPECKER_TOKEN not configured"; exit 0; }

# Read stdin for ref updates
while read oldrev newrev refname; do
  branch="''${refname#refs/heads/}"
  # Only trigger on main branches (adjust as needed)
  case "''$branch" in
    main|master|develop|release/*)
      ;;
    *) continue ;;
  esac

  # Get repo name from git config
  repo_url=$(git config --get remote.origin.url 2>/dev/null || true)
  if [[ -z "''$repo_url" ]]; then
    echo "No origin remote configured"
    continue
  fi

  # Extract owner/repo from various URL formats
  if [[ "''$repo_url" =~ github.com[:/](.+)/(.+)\.git$ ]]; then
    repo="''${BASH_REMATCH[1]}/''${BASH_REMATCH[2]}"
  elif [[ "''$repo_url" =~ github.com[:/](.+)/(.+)$ ]]; then
    repo="''${BASH_REMATCH[1]}/''${BASH_REMATCH[2]}"
  else
    echo "Cannot parse repo from: ''$repo_url"
    continue
  fi

  echo "Triggering Woodpecker for ''$repo @ ''$branch"
  woodpecker-trigger --url "''$WOODPECKER_URL" --token "''$WOODPECKER_TOKEN" "''$repo" "''$branch" &
done
HOOK

    chmod +x "''$HOOK_FILE"
    ok "Installed post-receive hook at ''$HOOK_FILE"
  }

  uninstall_hook() {
    [[ -f "''$HOOK_FILE" ]] || { warn "No hook found"; return; }

    if grep -q "woodpecker-trigger" "''$HOOK_FILE"; then
      rm "''$HOOK_FILE"
      ok "Removed Woodpecker hook"
    else
      warn "Hook exists but not managed by this tool (manual edit?)"
    fi
  }

  status_hook() {
    if [[ -f "''$HOOK_FILE" ]] && grep -q "woodpecker-trigger" "''$HOOK_FILE"; then
      ok "Woodpecker hook is installed"
      cat "''$HOOK_FILE"
    else
      warn "Woodpecker hook is NOT installed"
    fi
  }

  case "''${1:-status}" in
    install) install_hook ;;
    uninstall) uninstall_hook ;;
    status) status_hook ;;
    *) die "Usage: git-woodpecker-hook [install|uninstall|status]" ;;
  esac
''