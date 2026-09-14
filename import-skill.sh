#!/usr/bin/env bash

set -euo pipefail

function print_help {
cat <<EOF
Usage: $0 <git-repo-url>

Clone a git repository containing a skill into ~/.dsh/skillrepo and link it into ~/.dsh/skills using relative symlinks.

Arguments:
  <git-repo-url>  URL of the git repository to clone.

If no argument is provided, this help message is shown.

All paths (including symlink targets) are relative, so the skillrepo tree can be moved without breaking links.
EOF
}

if [[ $# -eq 0 ]]; then
    print_help
    exit 0
fi

REPO_URL="$1"
SKILLREPO_DIR="$HOME/.dsh/skillrepo"
SKILLS_DIR="$HOME/.dsh/skills"

mkdir -p "$SKILLREPO_DIR"
mkdir -p "$SKILLS_DIR"

# Repo name from URL, trailing .git stripped.
REPO_NAME=$(basename "$REPO_URL" .git)
TARGET_DIR="$SKILLREPO_DIR/$REPO_NAME"

if [[ -d "$TARGET_DIR" ]]; then
    echo "Updating existing clone at $TARGET_DIR"
    git -C "$TARGET_DIR" pull --ff-only
else
    echo "Cloning $REPO_URL into $TARGET_DIR"
    git clone -- "$REPO_URL" "$TARGET_DIR"
fi

# Locate the skill inside the repo. Supported layouts:
#   1) skills/<repo_name>/SKILL.md
#   2) skills/*/SKILL.md (single skill folder under skills/)
#   3) <repo_root>/SKILL.md
LINK_SOURCE=""
if [[ -f "$TARGET_DIR/skills/$REPO_NAME/SKILL.md" ]]; then
    LINK_SOURCE="skills/$REPO_NAME"
elif [[ -d "$TARGET_DIR/skills" ]]; then
    skill_dirs=("$TARGET_DIR/skills/"*/)
    if [[ ${#skill_dirs[@]} -eq 1 && -f "${skill_dirs[0]}SKILL.md" ]]; then
        LINK_SOURCE="skills/$(basename "${skill_dirs[0]}")"
    fi
elif [[ -f "$TARGET_DIR/SKILL.md" ]]; then
    LINK_SOURCE="."
fi

if [[ -z "$LINK_SOURCE" ]]; then
    echo "ERROR: no SKILL.md found under $TARGET_DIR (looked for skills/<repo>/SKILL.md, a single skills/*/SKILL.md, or a root SKILL.md)" >&2
    exit 1
fi

# Relative path from the skills directory to the skill.
REL_PATH=$(realpath --relative-to="$SKILLS_DIR" "$TARGET_DIR/$LINK_SOURCE")
LINK_NAME="$SKILLS_DIR/$REPO_NAME"

if [[ -L "$LINK_NAME" || -e "$LINK_NAME" ]]; then
    echo "Replacing existing link/file at $LINK_NAME"
    rm -f "$LINK_NAME"
fi

ln -s "$REL_PATH" "$LINK_NAME"
echo "Linked $LINK_NAME -> $REL_PATH"
