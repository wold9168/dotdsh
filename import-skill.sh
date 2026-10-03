#!/usr/bin/env bash

set -euo pipefail

function print_help {
cat <<EOF
Usage: $0 [--bare-repo] <git-repo-url>

Import a git repository containing a skill into ~/.dsh/skillrepo and link it into
~/.dsh/skills using a relative symlink.

By default the repository is registered as a submodule of the parent repository
(~/.dsh) and cloned into ~/.dsh/skillrepo, so that skill repositories are tracked
as submodules while skills without their own repository stay untracked.

Arguments:
  <git-repo-url>  URL of the git repository to import.

Options:
  --bare-repo     Clone the repository instead of registering a submodule.

If no argument is provided, this help message is shown.

All paths (including symlink targets) are relative, so the skillrepo tree can be
moved without breaking links.
EOF
}

BARE_REPO=false
REPO_URL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --bare-repo)
            BARE_REPO=true
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        -*)
            echo "ERROR: unknown option: $1" >&2
            print_help >&2
            exit 1
            ;;
        *)
            if [[ -n "$REPO_URL" ]]; then
                echo "ERROR: only one repository URL is accepted" >&2
                exit 1
            fi
            REPO_URL="$1"
            shift
            ;;
    esac
done

if [[ -z "$REPO_URL" ]]; then
    print_help
    exit 0
fi

PARENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKILLREPO_DIR="$PARENT_DIR/skillrepo"
SKILLS_DIR="$PARENT_DIR/skills"

mkdir -p "$SKILLREPO_DIR"
mkdir -p "$SKILLS_DIR"

# Repo name from URL, trailing .git stripped.
REPO_NAME=$(basename "$REPO_URL" .git)
TARGET_DIR="$SKILLREPO_DIR/$REPO_NAME"
SUBMODULE_PATH="skillrepo/$REPO_NAME"

if [[ -d "$TARGET_DIR/.git" || -f "$TARGET_DIR/.git" ]]; then
    echo "Updating existing repository at $TARGET_DIR"
    git -C "$TARGET_DIR" pull --ff-only
elif [[ "$BARE_REPO" == true ]]; then
    echo "Cloning $REPO_URL into $TARGET_DIR"
    git clone -- "$REPO_URL" "$TARGET_DIR"
else
    echo "Registering $REPO_URL as submodule $SUBMODULE_PATH"
    git -C "$PARENT_DIR" submodule add -- "$REPO_URL" "$SUBMODULE_PATH"
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
fi

if [[ -z "$LINK_SOURCE" && -f "$TARGET_DIR/SKILL.md" ]]; then
    LINK_SOURCE="."
fi

if [[ -z "$LINK_SOURCE" && -d "$TARGET_DIR/skills" ]]; then
    bundled_skills=()
    for candidate in "$TARGET_DIR/skills/"*/; do
        if [[ "${candidate%/}" != "$TARGET_DIR/skills/$REPO_NAME" && -f "${candidate}SKILL.md" ]]; then
            bundled_skills+=("$(basename "${candidate%/}")")
        fi
    done
    # A repo bundling several skills cannot be linked by name without shadowing the rest.
    if [[ ${#bundled_skills[@]} -gt 0 ]]; then
        echo "WARNING: $REPO_NAME bundles ${#bundled_skills[@]} skills (${bundled_skills[*]}) under skills/" >&2
        echo "WARNING: link each of them individually, or import a repo that holds a single skill" >&2
    fi
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
