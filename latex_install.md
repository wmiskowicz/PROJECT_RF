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
biber --version      # may fail on old systems, see Troubleshooting (not needed then)
```

latexmk should print a version number. If biber fails with Perl errors, see Troubleshooting: the script switches the project to the bibtex backend.

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

If the build fails with `spawn latexmk ENOENT` or `latexmk: command not found`, the VS Code server doesn't see your PATH. The script fixes this automatically by writing the exact `latexmk` location into `~/.vscode-server/data/Machine/settings.json`. To do it by hand, run `which latexmk`, then open that file (F1 > *Preferences: Open Remote Settings (JSON)*) and add, with your path:

```json
"latex-workshop.latex.tools": [
    {
        "name": "latexmk",
        "command": "/home/USER/texlive/bin/x86_64-linux/latexmk",
        "args": ["-synctex=1", "-interaction=nonstopmode", "-file-line-error",
                 "-pdf", "-outdir=%OUTDIR%", "%DOC%"],
        "env": { "PATH": "/home/USER/texlive/bin/x86_64-linux:/usr/local/bin:/usr/bin:/bin" }
    }
]
```

The `env` PATH matters: latexmk must also find `biber` and `pdflatex`. Press the build button again; no reconnect is needed.

Also check the PATH from step 1 is set. Open the **LaTeX Workshop** output panel (View > Output) to see the exact error.

## 6. Build from the terminal instead

`RF_PROJECT.tex` is in `doc/`, next to which all build products are generated. From inside the cloned repository (any subfolder) run:

```sh
cd "$(git rev-parse --show-toplevel)"
cd doc && latexmk -pdf RF_PROJECT.tex
```

The result is `RF_PROJECT.pdf`. latexmk runs pdflatex and biber as many times as needed.

To remove build files:

```sh
(cd doc && latexmk -C RF_PROJECT.tex)
```

Build files and the PDF are in `.gitignore`, so don't commit them.

## Troubleshooting

**`File 'xxx.sty' not found`:** find which package provides it and install it.

```sh
tlmgr search --global --file "/xxx.sty"
tlmgr install <package-name>
```

**`tlmgr: command not found`:** the PATH isn't set. Run `source ~/.bashrc`, or check that `~/texlive/bin/x86_64-linux` exists (on a different CPU the folder name differs, e.g. `aarch64-linux`).

**`biber --version` prints Perl errors** (e.g. `POSIX::_exit` not predeclared, `POSIX::WNOHANG not allowed`, `IPC/Cmd.pm`, or `GLIBC_2.23 not found`): the prebuilt `biber` needs glibc 2.23 or newer. Check with `ldd --version`; on CentOS 7 (glibc 2.17) it cannot run. The script handles this automatically: it creates a local, git-ignored file `bibbackend.tex` in the repository root, and `RF_PROJECT.tex` then uses the `bibtex` backend instead of `biber`. Other machines are not affected. By hand:

```sh
cat > bibbackend.tex <<'EOF'
\newcommand{\bibbackend}{bibtex}
EOF
(cd doc && latexmk -C RF_PROJECT.tex)      # drop stale biber build files
cd doc && latexmk -pdf RF_PROJECT.tex
```

Delete `bibbackend.tex` to go back to `biber`.

**Warning `Font shape 'OT4/pcr/m/it' undefined`:** harmless. Courier has no italic in the Polish font encoding, so upright Courier is used.

## If you do have root (Debian/Ubuntu)

```sh
sudo apt update
sudo apt install texlive-full latexmk biber
```
