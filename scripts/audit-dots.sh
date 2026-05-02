#!/bin/bash
########################################################################
##  SnowDots — SnowAuditdots                              Version: v1.1.0  ##
##  Last Edited: 2026-05-02                                           ##
########################################################################

HOSTNAME=$(hostname)

# Path Selection based on Hostname
if [[ "$HOSTNAME" == "snowpi" ]]; then
    PRIMARY_REPO="$HOME/SnowPi-Dotfiles"
    SECONDARY_REPO="$HOME/Dotfiles"
else
    PRIMARY_REPO="$HOME/Dotfiles"
    SECONDARY_REPO="$HOME/SnowPi-Dotfiles"
fi

echo "🔍 Global Dotfile Audit | Host: $HOSTNAME"
echo "-----------------------------------"

# 1. Compare Local vs GitLab
echo "☁️  GitLab Sync Gap [$PRIMARY_REPO]:"
if [ -d "$PRIMARY_REPO" ]; then
    cd "$PRIMARY_REPO"
    git fetch origin >/dev/null 2>&1
    BEHIND=$(git rev-list HEAD..origin/main --count)
    AHEAD=$(git rev-list origin/main..HEAD --count)

    if [ "$AHEAD" -eq 0 ] && [ "$BEHIND" -eq 0 ]; then
        echo "    ✅ GitLab is perfectly in sync."
    else
        [ "$AHEAD" -gt 0 ] && echo "    ⚠️ GitLab is BEHIND by $AHEAD commits (Local has new work)."
        [ "$BEHIND" -gt 0 ] && echo "    ⬇️  GitLab is AHEAD by $BEHIND commits (Remote has updates)."
        echo "    📂 Diverged files:"
        git diff --name-only origin/main HEAD | sed 's/^/      - /'
    fi
else
    echo "    ❌ Primary repo not found at $PRIMARY_REPO"
fi

# 2. Local Status for both repos
for REPO in "$PRIMARY_REPO" "$SECONDARY_REPO"; do
    if [ -d "$REPO" ]; then
        echo -e "\n📂 Status: $(basename "$REPO")"
        cd "$REPO"
        STATUS=$(git status --short)
        if [ -z "$STATUS" ]; then
            echo "    ✅ Working tree clean"
        else
            echo "$STATUS" | sed 's/^/    /'
        fi
    fi
done

echo -e "\n📜 Recent History (Last 3 Commits):"
cd "$PRIMARY_REPO" 2>/dev/null && git log -n 3 --oneline --graph --decorate

echo "-----------------------------------"
