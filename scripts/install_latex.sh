#!/usr/bin/env bash
# Sets up LaTeX for RF_PROJECT without root / apt. See latex_install.md.
#
# Idempotent: every step checks its own state and does only what is missing.
# Prints "Setup is complete" only when everything is in place.
#
# Usage: bash scripts/install_latex.sh
set -uo pipefail

TEXDIR="$HOME/texlive"
INSTALLER_DIR="$HOME/texlive-installer"
URL="https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz"
EXT="James-Yu.latex-workshop"
PACKAGES="collection-latexextra collection-langpolish collection-bibtexextra \
collection-pictures collection-fontsrecommended latexmk biber"
# Files that must be findable by TeX (one per required package)
REQUIRED_FILES="biblatex.sty csquotes.sty circuitikz.sty tabularx.sty makecell.sty \
threeparttable.sty polski.sty pdfescape.sty plr10.tfm"

CHANGED=0     # something was installed / modified
PENDING=0     # something could not be verified or done

say()  { echo "[latex-setup] $*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------- 1. TeX Live
if have pdflatex && have latexmk; then
    say "TeX Live found: $(command -v pdflatex)"
elif [ -d "$TEXDIR/bin" ]; then
    say "TeX Live found in $TEXDIR but not on PATH (fixed below)."
else
    say "Installing TeX Live into $TEXDIR (10-20 minutes)..."
    mkdir -p "$INSTALLER_DIR" && cd "$INSTALLER_DIR" || exit 1
    if have wget; then wget -N "$URL"
    elif have curl; then curl -LO "$URL"
    else say "Need wget or curl."; exit 1; fi
    tar xzf install-tl-unx.tar.gz && cd install-tl-* || exit 1
    perl install-tl --no-interaction --scheme=small \
         --no-doc-install --no-src-install --texdir="$TEXDIR" || exit 1
    CHANGED=1
fi

# ---------------------------------------------------------------- 2. PATH
if [ -d "$TEXDIR/bin" ]; then
    BIN_DIR=$(echo "$TEXDIR"/bin/*)
    LINE="export PATH=\"$BIN_DIR:\$PATH\""
    # .bashrc for terminals, .profile for VS Code Remote - SSH
    for rc in "$HOME/.bashrc" "$HOME/.profile"; do
        if ! grep -qxF "$LINE" "$rc" 2>/dev/null; then
            echo "$LINE" >> "$rc"
            say "Added TeX Live to PATH in $rc"
            CHANGED=1
        fi
    done
    case ":$PATH:" in *":$BIN_DIR:"*) ;; *) export PATH="$BIN_DIR:$PATH" ;; esac
fi

for tool in pdflatex latexmk biber; do
    have "$tool" || say "WARNING: $tool still not found (installed below if possible)."
done

# ---------------------------------------------------------------- 3. Packages
missing=""
for f in $REQUIRED_FILES; do
    kpsewhich "$f" >/dev/null 2>&1 || missing="$missing $f"
done
if [ -n "$missing" ] || ! have latexmk || ! have biber; then
    if have tlmgr; then
        say "Missing:${missing:- latexmk/biber}. Installing packages..."
        # shellcheck disable=SC2086
        if tlmgr install $PACKAGES; then CHANGED=1
        else say "WARNING: tlmgr install failed."; PENDING=1; fi
    else
        say "WARNING: tlmgr not available; cannot install missing packages:$missing"
        PENDING=1
    fi
else
    say "All required LaTeX packages present."
fi

have latexmk && have biber || { say "ERROR: latexmk or biber still missing."; exit 1; }

# ---------------------------------------------------------------- 3b. bibliography backend
# The project uses biber by default. The prebuilt biber needs a recent glibc (>= 2.23);
# on older systems (e.g. CentOS 7, glibc 2.17) it crashes with "POSIX::_exit" /
# "POSIX::WNOHANG" errors. In that case create a local, git-ignored bibbackend.tex
# that makes RF_PROJECT.tex use the bibtex backend instead.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_FILE="$REPO_ROOT/bibbackend.tex"

if biber --version >/dev/null 2>&1; then
    say "biber runs correctly (backend: biber)."
    BIB_BACKEND=biber
    if [ -f "$BACKEND_FILE" ]; then
        rm -f "$BACKEND_FILE"
        say "Removed $BACKEND_FILE (biber works, no override needed)."
        CHANGED=1
    fi
else
    say "biber cannot run on this machine ($(ldd --version 2>&1 | head -n 1); biber needs glibc >= 2.23)."
    have bibtex || { say "ERROR: bibtex not found either."; exit 1; }
    BIB_BACKEND=bibtex
    if grep -qs 'bibtex' "$BACKEND_FILE"; then
        say "Project already uses the bibtex backend ($BACKEND_FILE)."
    else
        printf '%s\n' '% Local override created by scripts/install_latex.sh (git-ignored).' \
                      '\newcommand{\bibbackend}{bibtex}' > "$BACKEND_FILE"
        say "Created $BACKEND_FILE: the project now uses the bibtex backend."
        say "Run '(cd doc && latexmk -C RF_PROJECT.tex)' once to drop stale biber build files."
        CHANGED=1
    fi
fi

# ---------------------------------------------------------------- 4. VS Code
if have code; then
    if code --list-extensions 2>/dev/null | grep -qi "^$EXT$"; then
        say "VS Code extension $EXT already installed."
    else
        say "Installing VS Code extension $EXT..."
        if code --install-extension "$EXT"; then CHANGED=1
        else say "WARNING: could not install $EXT automatically."; PENDING=1; fi
    fi
else
    say "Not running inside a VS Code terminal: cannot check the LaTeX Workshop extension."
    PENDING=1
fi

# ------------------------------------------- 5. VS Code: absolute latexmk path
# The VS Code server often starts with a minimal PATH that ignores ~/.profile
# ("spawn latexmk ENOENT"), so point LaTeX Workshop at latexmk explicitly.
# Written (a) to the workspace settings, which VS Code always reads, and
# (b) to the per-user remote settings. Both are machine-specific and git-ignored/outside the repo.
LATEXMK_BIN=$(command -v latexmk)
TEX_BIN_DIR=$(dirname "$LATEXMK_BIN")

write_vscode_tool() {   # $1 = settings.json path
    local file="$1" result
    mkdir -p "$(dirname "$file")"
    result=$(LATEXMK_BIN="$LATEXMK_BIN" TEX_BIN_DIR="$TEX_BIN_DIR" SETTINGS="$file" python3 - <<'PY'
import json, os
path = os.environ["SETTINGS"]
latexmk, bindir = os.environ["LATEXMK_BIN"], os.environ["TEX_BIN_DIR"]
tool = {
    "name": "latexmk",
    "command": latexmk,
    "args": ["-synctex=1", "-interaction=nonstopmode", "-file-line-error",
             "-pdf", "-outdir=%OUTDIR%", "%DOC%"],
    "env": {"PATH": bindir + ":/usr/local/bin:/usr/bin:/bin"},
}
data = {}
if os.path.exists(path) and os.path.getsize(path) > 0:
    try:
        with open(path) as f:
            data = json.load(f)
    except ValueError:
        print("unparsable"); raise SystemExit
old = data.get("latex-workshop.latex.tools", [])
if tool in old:
    print("ok"); raise SystemExit
data["latex-workshop.latex.tools"] = [t for t in old if t.get("name") != "latexmk"] + [tool]
with open(path, "w") as f:
    json.dump(data, f, indent=4)
print("updated")
PY
)
    case "$result" in
        ok)      say "Already set in $file" ;;
        updated) say "Wrote latexmk path to $file"; CHANGED=1 ;;
        *)       say "WARNING: $file has comments/invalid JSON; add the tool manually (see latex_install.md)."
                 PENDING=1 ;;
    esac
}

if have python3; then
    write_vscode_tool "$REPO_ROOT/.vscode/settings.json"
    write_vscode_tool "$HOME/.vscode-server/data/Machine/settings.json"
else
    say "WARNING: python3 not found; add the latexmk tool to VS Code settings manually (see latex_install.md)."
    PENDING=1
fi

# ---------------------------------------------------------------- Summary
echo
latexmk -v | sed -n 2p
if [ "$BIB_BACKEND" = biber ]; then
    biber --version | head -n 1
else
    echo "bibliography backend: bibtex (biber cannot run on this machine)"
fi
echo

if [ "$PENDING" -eq 1 ]; then
    say "Terminal setup is done, but VS Code is not verified."
    say "In VS Code: install '$EXT' on the SSH host (Extensions panel > Install in SSH),"
    say "then F1 > 'Remote-SSH: Kill VS Code Server on Host' and reconnect."
    say "Run this script again from the VS Code terminal to verify."
elif [ "$CHANGED" -eq 1 ]; then
    say "Setup finished. Reconnect VS Code (F1 > 'Remote-SSH: Kill VS Code Server on Host'),"
    say "open RF_PROJECT.tex and click the green Build icon (or Ctrl+Alt+B)."
else
    say "Setup is complete. Nothing to do."
fi
