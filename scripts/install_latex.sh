#!/usr/bin/env bash
# Installs TeX Live into $HOME/texlive (no root / no apt needed) with every
# package RF_PROJECT needs, and adds it to PATH. See latex_install.md.
#
# Usage: ./scripts/install_latex.sh
set -euo pipefail

TEXDIR="$HOME/texlive"
INSTALLER_DIR="$HOME/texlive-installer"
URL="https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz"
PACKAGES="collection-latexextra collection-langpolish collection-bibtexextra \
collection-pictures collection-fontsrecommended latexmk biber"

# 1. Already installed?
if command -v latexmk >/dev/null && command -v biber >/dev/null && command -v pdflatex >/dev/null; then
    echo "latexmk, biber and pdflatex are already available:"
    command -v latexmk biber pdflatex
    echo "Nothing to do."
    exit 0
fi

if [ -d "$TEXDIR" ]; then
    echo "$TEXDIR already exists. Remove it first or just fix your PATH." >&2
    exit 1
fi

# 2. Download the installer
mkdir -p "$INSTALLER_DIR"
cd "$INSTALLER_DIR"
if command -v wget >/dev/null; then
    wget -N "$URL"
elif command -v curl >/dev/null; then
    curl -LO "$URL"
else
    echo "Need wget or curl." >&2
    exit 1
fi
tar xzf install-tl-unx.tar.gz
cd install-tl-*

# 3. Install TeX Live (takes 10-20 minutes)
perl install-tl --no-interaction --scheme=small \
     --no-doc-install --no-src-install --texdir="$TEXDIR"

# 4. PATH (.bashrc for terminals, .profile for VS Code Remote - SSH)
BIN_DIR=$(echo "$TEXDIR"/bin/*)
LINE="export PATH=\"$BIN_DIR:\$PATH\""
for rc in "$HOME/.bashrc" "$HOME/.profile"; do
    grep -qxF "$LINE" "$rc" 2>/dev/null || echo "$LINE" >> "$rc"
done
export PATH="$BIN_DIR:$PATH"

# 5. Extra packages
# shellcheck disable=SC2086
tlmgr install $PACKAGES

# 6. Verify
latexmk -v | head -n 2
biber --version

echo
echo "Done. Open a new terminal (or run: source ~/.bashrc), then build with:"
echo "  latexmk -pdf RF_PROJECT.tex"
echo "In VS Code: install LaTeX Workshop on the SSH host and reconnect."
