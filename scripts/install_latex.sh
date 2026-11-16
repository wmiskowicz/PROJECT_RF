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

# ---------------------------------------------------------------- Summary
echo
latexmk -v | sed -n 2p
biber --version
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
