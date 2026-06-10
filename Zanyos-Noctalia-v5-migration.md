# ZaneyOS Noctalia v5 migration (automated first, manual fallback)
This guide is for users on older/custom ZaneyOS branches who want to move from legacy Noctalia Shell integration to Noctalia v5 safely.

Noctalia v5 uses:

- standalone binary: `noctalia`
- IPC command style: `noctalia msg <command>`
- config directory: `~/.config/noctalia` (not `~/.config/quickshell/noctalia-shell`)

## Preferred path: use the migration scripts
If your repository contains these scripts, use this flow:

- `modules/src/noctalia-v5-prepare.sh`
- `modules/src/noctalia-v5-finalize.sh`

The script flow is designed to be safer and more repeatable than manual edits.

### Step A) Prepare test branch from `origin/noctaliav5`
Run from repo root:

```bash
./modules/src/noctalia-v5-prepare.sh
```

Default behavior:

- verifies repo/rebase/merge state
- stashes local changes (tracked + untracked) if needed
- fetches `origin/noctaliav5`
- creates local test branch `local/noctalia-v5-test` tracking `origin/noctaliav5`
- writes state to `.git/noctalia-v5-migration.state`

Useful options:

```bash
# Different remote/source branch:
./modules/src/noctalia-v5-prepare.sh --remote origin --source-branch noctaliav5

# Different local test branch name:
./modules/src/noctalia-v5-prepare.sh --test-branch local/my-noctalia-v5-test

# Refuse dirty tree instead of auto-stashing:
./modules/src/noctalia-v5-prepare.sh --no-stash

# Reset an already-existing test branch to latest remote branch:
./modules/src/noctalia-v5-prepare.sh --force-reset-test-branch
```

### Step B) Validate on the test branch
While on the test branch, run validation/build:

```bash
zcli rebuild --dry
```

Then do your normal live test build flow, for example:

```bash
fr
```

or:

```bash
zcli rebuild
```

### Step C) Merge tested branch back to your original branch
If testing passes:

```bash
./modules/src/noctalia-v5-finalize.sh
```

Default behavior:

- reads `.git/noctalia-v5-migration.state`
- switches back to your original branch
- merges in the tested branch (`--no-ff --no-edit`)
- restores prep stash if one was created
- removes state file on success

Useful options:

```bash
# Require fast-forward only merge:
./modules/src/noctalia-v5-finalize.sh --ff-only

# Keep stash untouched (restore manually later):
./modules/src/noctalia-v5-finalize.sh --no-restore-stash

# Delete local test branch after successful merge:
./modules/src/noctalia-v5-finalize.sh --drop-test-branch
```
### Step D) Publish the updated branch (usually your primary branch)
`noctalia-v5-finalize.sh` merges back into the branch you started from (`ORIGINAL_BRANCH`), which may or may not be `main`.

Publish whichever branch was updated:

```bash
# Confirm the currently checked-out branch (this should be your updated branch)
git branch --show-current

# Push that branch
git push origin "$(git branch --show-current)"
```

If you tested from one branch but publish from another (typically `main`), merge it explicitly:

```bash
# Replace these with your branch names
UPDATED_BRANCH="<branch-with-noctalia-v5-fixes>"
PUBLISH_BRANCH="<branch-you-release-from>"   # typically main

git switch "$PUBLISH_BRANCH"
git pull --ff-only origin "$PUBLISH_BRANCH"
git merge --ff-only "$UPDATED_BRANCH" || git merge "$UPDATED_BRANCH"
git push origin "$PUBLISH_BRANCH"
```

### Scripted flow rollback / abort
If you prepared but want to stop before finalizing:

```bash
# Load saved branch names:
source .git/noctalia-v5-migration.state

# Return to your original branch:
git switch "$ORIGINAL_BRANCH"

# Optionally delete the local test branch:
git branch -D "$TEST_BRANCH"

# Restore stashed work manually if needed:
git stash list
git stash apply stash@{N}

# Remove script state file:
rm -f .git/noctalia-v5-migration.state
```

---

## Manual/backport fallback (file-by-file)
Use this if you cannot use the scripts.

## Step 0) Safety first
From your ZaneyOS repo root:

```bash
# Optional isolated branch for manual migration:
git switch -c local/noctalia-v5-migration 2>/dev/null || git switch local/noctalia-v5-migration
git status
```

Optionally save a patch before editing:

```bash
git --no-pager diff > before-noctalia-v5-migration.patch
```

## Step 1) Update flake input to Noctalia v5
Edit `flake.nix`.

### File: `flake.nix`
```diff
diff --git a/flake.nix b/flake.nix
@@
     noctalia = {
-      url = "github:noctalia-dev/noctalia-shell";
+      url = "github:noctalia-dev/noctalia";
       inputs.nixpkgs.follows = "nixpkgs";
     };
```

## Step 2) Refresh lock file
Do **not** hand-edit `flake.lock` unless you absolutely must.
Run:

```bash
nix flake lock --update-input noctalia
```

### File: `flake.lock` (expected change pattern)
Your exact `rev`, `lastModified`, and `narHash` will vary over time, but the key migration is:

```diff
diff --git a/flake.lock b/flake.lock
@@
-        "repo": "noctalia-shell",
+        "repo": "noctalia",
@@
-    "noctalia-qs": { ... }
+    # removed (no longer needed for v5)
```

## Step 3) Move Home Manager Noctalia module to v5 model
Edit `modules/home/noctalia.nix`.

### File: `modules/home/noctalia.nix`
```diff
diff --git a/modules/home/noctalia.nix b/modules/home/noctalia.nix
@@
 }: let
   system = pkgs.stdenv.hostPlatform.system;
   noctaliaPkg = inputs.noctalia.packages.${system}.default;
-  configDir = "${noctaliaPkg}/share/noctalia-shell";
 in {
-  # Install the Noctalia package
-  home.packages = [
-    noctaliaPkg
-    pkgs.quickshell # Ensure quickshell is available for the service
-  ];
+  home.packages = [noctaliaPkg];
 
-  # Seed the configuration
-  home.activation.seedNoctaliaShellCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
+  # Ensure declarative v5 config directory exists
+  home.activation.ensureNoctaliaConfigDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
     set -eu
-    DEST="$HOME/.config/quickshell/noctalia-shell"
-    SRC="${configDir}"
+    DEST="$HOME/.config/noctalia"
 
     if [ ! -d "$DEST" ]; then
-      $DRY_RUN_CMD mkdir -p "$HOME/.config/quickshell"
-      $DRY_RUN_CMD cp -R "$SRC" "$DEST"
-      $DRY_RUN_CMD chmod -R u+rwX "$DEST"
+      $DRY_RUN_CMD mkdir -p "$DEST"
     fi
   '';
 }
```

## Step 4) Start Noctalia v5 with Hyprland
Edit `modules/home/hyprland/exec-once.nix`.

### File: `modules/home/hyprland/exec-once.nix`
```diff
diff --git a/modules/home/hyprland/exec-once.nix b/modules/home/hyprland/exec-once.nix
@@
       "pkill waybar"
       "killall -q swaync"
       "pkill swaync"
-      "noctalia-shell &"
+      "noctalia"
     ]
```

## Step 5) Convert legacy Noctalia keybind IPC calls to v5 commands
Edit `modules/home/hyprland/binds.nix`.

### File: `modules/home/hyprland/binds.nix`
```diff
diff --git a/modules/home/hyprland/binds.nix b/modules/home/hyprland/binds.nix
@@
-      "$modifier,D, Noctalia Launcher, exec, noctalia-shell ipc call launcher toggle"
-      "$modifier SHIFT,Return, Noctalia Launcher, exec, noctalia-shell ipc call launcher toggle"
-      "$modifier,M, Noctalia Notifications, exec,  noctalia-shell ipc call notifications toggleHistory"
-      "$modifier,V, Noctalia Clipboard, exec,  noctalia-shell ipc call launcher clipboard"
-      "$modifier ALT,P, Noctalia Settings, exec, noctalia-shell ipc call settings toggle"
-      "$modifier SHIFT,comma, Noctalia Settings, exec, noctalia-shell ipc call settings toggle"
-      "$modifier CTRL,L, Noctalia Lock Screen, exec,  noctalia-shell ipc call sessionMenu lockscreen lock"
-      "$modifier SHIFT,W, Noctalia Wallpaper, exec, noctalia-shell ipc call wallpaper toggle"
-      "$modifier,X, Noctalia Power Menu, exec,  noctalia-shell ipc call sessionMenu toggle"
-      "$modifier,C, Noctalia Control Center, exec,  noctalia-shell ipc call controlCenter toggle"
-      "$modifier CTRL,R, Noctalia Screen Recorder, exec,  noctalia-shell ipc call screenRecorder toggle"
-      "$modifier SHIFT,R, Restart Noctalia shell, exec,  restart.noctalia"
+      "$modifier,D, Noctalia Launcher, exec, noctalia msg panel-toggle launcher"
+      "$modifier SHIFT,Return, Noctalia Launcher, exec, noctalia msg panel-toggle launcher"
+      "$modifier,M, Noctalia Notifications, exec, noctalia msg panel-toggle control-center notifications"
+      "$modifier,V, Noctalia Clipboard, exec, noctalia msg panel-toggle clipboard"
+      "$modifier ALT,P, Noctalia Settings, exec, noctalia msg settings-toggle"
+      "$modifier SHIFT,comma, Noctalia Settings, exec, noctalia msg settings-toggle"
+      "$modifier CTRL,L, Noctalia Lock Screen, exec, noctalia msg session lock"
+      "$modifier SHIFT,W, Noctalia Wallpaper, exec, noctalia msg panel-toggle wallpaper"
+      "$modifier,X, Noctalia Power Menu, exec, noctalia msg panel-toggle session"
+      "$modifier,C, Noctalia Control Center, exec, noctalia msg panel-toggle control-center"
+      "$modifier CTRL,R, Noctalia Screenshot Region, exec, noctalia msg screenshot-region"
+      "$modifier SHIFT,R, Restart Noctalia shell, exec, restart.noctalia"
```

Notes:

- `screenRecorder toggle` from the old setup is not available in v5 IPC.
- This migration maps that bind to `screenshot-region` as a compatible built-in action.

## Step 6) Update restart helper script
Edit `modules/home/scripts/restart.noctalia`.

### File: `modules/home/scripts/restart.noctalia`
```diff
diff --git a/modules/home/scripts/restart.noctalia b/modules/home/scripts/restart.noctalia
@@
-# Restart the Noctalia QuickShell session by terminating only the noctalia-shell
-# processes, avoiding any signals to unrelated process groups (e.g. Hyprland).
+# Restart the Noctalia session by terminating only Noctalia-related processes,
+# avoiding any signals to unrelated process groups (e.g. Hyprland).
@@
-  # Collect only PIDs whose command explicitly runs noctalia-shell
-  # - direct wrapper: ".../noctalia-shell"
-  # - quickshell/qs with "-c noctalia-shell"
+  # Collect only PIDs whose command explicitly runs:
+  # - standalone v5 binary: ".../noctalia"
+  # - legacy wrapper: ".../noctalia-shell"
+  # - legacy quickshell launch: quickshell/qs with "-c noctalia-shell"
   ps -eo pid=,cmd= \
-    | ${GREP:-grep} -E "(^|/)(noctalia-shell)( |$)|(^| )((qs|quickshell))( | ).*-c( |=)?noctalia-shell( |$)" \
+    | ${GREP:-grep} -E "(^|/)(noctalia)( |$)|(^|/)(noctalia-shell)( |$)|(^| )((qs|quickshell))( | ).*-c( |=)?noctalia-shell( |$)" \
     | awk '{print $1}'
@@
-  # Prefer the noctalia-shell wrapper to ensure proper env and runtime flags
-  if command -v noctalia-shell >/dev/null 2>&1; then
+  # Prefer the standalone v5 binary; keep legacy fallbacks for compatibility.
+  if command -v noctalia >/dev/null 2>&1; then
+    nohup setsid noctalia >/dev/null 2>&1 &
+  elif command -v noctalia-shell >/dev/null 2>&1; then
     nohup setsid noctalia-shell >/dev/null 2>&1 &
@@
-    echo "Error: noctalia-shell/quickshell/qs not found in PATH" >&2
+    echo "Error: noctalia/noctalia-shell/quickshell/qs not found in PATH" >&2
```

## Step 7) Update panel switcher helper detection
Edit `modules/home/scripts/qs-panels.nix`.

### File: `modules/home/scripts/qs-panels.nix`
```diff
diff --git a/modules/home/scripts/qs-panels.nix b/modules/home/scripts/qs-panels.nix
@@
-  if pgrep -fa quickshell | grep -q "noctalia-shell"; then active="noctalia"; fi
+    if pgrep -x noctalia >/dev/null 2>&1 || pgrep -fa quickshell | grep -q "noctalia-shell"; then active="noctalia"; fi
```

## Step 8) Validate and rebuild
Run:

```bash
nix-instantiate --parse flake.nix \
  modules/home/noctalia.nix \
  modules/home/hyprland/exec-once.nix \
  modules/home/hyprland/binds.nix \
  modules/home/scripts/qs-panels.nix

bash -n modules/home/scripts/restart.noctalia
```

Then rebuild:

```bash
fr
```

or:

```bash
zcli rebuild
```

## Step 9) Runtime verification checklist
- `pgrep -x noctalia` shows running process after login.
- Launcher bind works (`SUPER+D` / your mapped key).
- Settings opens with `noctalia msg settings-toggle`.
- Lock command works (`noctalia msg session lock`).
- Control Center, clipboard, wallpaper, and session panel binds all respond.
## Step 10) Publish your updated branch
Same idea as scripted Step D: push whichever branch you actually updated (typically `main`, but many users release from a stable/custom branch).

```bash
# Confirm your updated branch
git branch --show-current

# Push that branch
git push origin "$(git branch --show-current)"
```

If you need to publish from a different branch, merge first (for example into `main`) and then push that publish branch.

## Rollback
If needed:

```bash
git restore flake.nix flake.lock \
  modules/home/noctalia.nix \
  modules/home/hyprland/exec-once.nix \
  modules/home/hyprland/binds.nix \
  modules/home/scripts/restart.noctalia \
  modules/home/scripts/qs-panels.nix
```

or just return to your pre-migration branch/commit.
