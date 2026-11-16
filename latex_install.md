# Building RF_PROJECT.pdf on Linux (no root / no apt)

This installs TeX Live into your home directory (`~/texlive`). It needs no `sudo` and no `apt`, so it works on shared university servers. Needs about 2-3 GB of disk space.

**Shortcut:** steps 1-4 are automated by a script. From the repository root run:

```sh
bash scripts/install_latex.sh
```

The script is safe to re-run: it checks what is already in place (TeX Live, PATH, packages, VS Code extension) and fixes only what is missing. It prints `Setup is complete` only when everything is done. Run it from the **VS Code terminal** so it can also install and check the LaTeX Workshop extension.

The manual steps below do the same thing.

## 1. Check whether LaTeX is already installed

```sh
which latexmk biber pdflatex
```

If all three print a path, skip to step 5 (VS Code) or 6 (terminal).

## 2. Download the installer

```sh
mkdir -p ~/texlive-installer && cd ~/texlive-installer
wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
tar xzf install-tl-unx.tar.gz
cd install-tl-*
```

(No `wget`? Use `curl -LO https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz`.)

## 3. Install TeX Live into your home directory

```sh
perl install-tl --no-interaction --scheme=small \
     --no-doc-install --no-src-install --texdir="$HOME/texlive"
```

This takes 10-20 minutes. It prints a lot of output; wait for `Welcome to TeX Live!`.

## 4. Add TeX Live to your PATH and install the needed packages

```sh
echo 'export PATH="$HOME/texlive/bin/x86_64-linux:$PATH"' >> ~/.bashrc
source ~/.bashrc

tlmgr install collection-latexextra collection-langpolish collection-bibtexextra \
              collection-pictures collection-fontsrecommended latexmk biber
```

Check:

```sh
latexmk -v
biber --version
```

Both should print a version number.

## 5. Build in VS Code (Remote - SSH)

Works when VS Code is connected to the Linux machine with the **Remote - SSH** extension. (If VS Code runs locally on Windows, use MiKTeX locally instead; this install isn't used.)

1. Make the PATH visible to VS Code too, since it may not read `~/.bashrc`:

   ```sh
   echo 'export PATH="$HOME/texlive/bin/x86_64-linux:$PATH"' >> ~/.profile
   ```

2. Reconnect: press `F1`, run **Remote-SSH: Kill VS Code Server on Host**, then connect again.
3. Install the **LaTeX Workshop** extension (`James-Yu.latex-workshop`) and choose *Install in SSH: host* when offered.
4. Open `RF_PROJECT.tex` and click the green ▶ **Build LaTeX project** icon in the top right (or `Ctrl+Alt+B`). The default recipe uses `latexmk`, which also runs `biber`.
5. Click **View LaTeX PDF** (magnifier icon) to open the PDF in a VS Code tab. Rebuilding refreshes it.

If you see no build/view icons at all: the icons appear only while a `.tex` file is open in the editor, and only if LaTeX Workshop is installed **on the SSH host** (Extensions panel, check for the *SSH: ...* section). A LaTeX icon in the left activity bar also means it is working.

If the build fails with `latexmk: command not found`, the PATH from step 1 wasn't picked up. Open the **LaTeX Workshop** output panel (View > Output) to see the exact error.

## 6. Build from the terminal instead

`RF_PROJECT.tex` is in the repository root, the parent folder of `scripts/`. From inside the cloned repository (any subfolder) run:

```sh
cd "$(git rev-parse --show-toplevel)"
latexmk -pdf RF_PROJECT.tex
```

The result is `RF_PROJECT.pdf`. latexmk runs pdflatex and biber as many times as needed.

To remove build files:

```sh
latexmk -C RF_PROJECT.tex
```

Build files and the PDF are in `.gitignore`, so don't commit them.

## Troubleshooting

**`File 'xxx.sty' not found`:** find which package provides it and install it.

```sh
tlmgr search --global --file "/xxx.sty"
tlmgr install <package-name>
```

**`tlmgr: command not found`:** the PATH isn't set. Run `source ~/.bashrc`, or check that `~/texlive/bin/x86_64-linux` exists (on a different CPU the folder name differs, e.g. `aarch64-linux`).

**`biber` fails to run:** the `biber` binary needs a recent glibc. Check with `biber --version`; if it errors, tell your admin or build locally on another machine.

**Warning `Font shape 'OT4/pcr/m/it' undefined`:** harmless. Courier has no italic in the Polish font encoding, so upright Courier is used.

## If you do have root (Debian/Ubuntu)

```sh
sudo apt update
sudo apt install texlive-full latexmk biber
```
