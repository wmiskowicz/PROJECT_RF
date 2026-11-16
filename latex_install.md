# LaTeX setup for RF_PROJECT

How to build `RF_PROJECT.pdf` on your own machine.

## 1. Install a TeX distribution

| OS | Distribution |
| --- | --- |
| Windows | [MiKTeX](https://miktex.org/download) (tested with MiKTeX 24.1) |
| Linux / macOS | TeX Live (`texlive-full`) or MacTeX |

You also need **latexmk** and **biber**. Both come with MiKTeX and with a full TeX Live.

## 2. Packages the project needs

Most of them come with a standard install. These two were missing on a fresh MiKTeX:

| Package | Why |
| --- | --- |
| `pdfescape` | needed by `hyperref` |
| `pl` | Polish fonts (`plr10`, ...), needed by `polski` |

### MiKTeX (Windows)

Easiest: let MiKTeX fetch any missing package during the build.

```sh
initexmf --set-config-value=[MPM]AutoInstall=1
```

Or install them by hand and refresh MiKTeX's file index:

```sh
miktex packages install pdfescape
miktex packages install pl
initexmf --update-fndb
initexmf --mkmaps
```

If a package is reported as *already installed* but the build still says `File 'xxx.sty' not found`, run `initexmf --update-fndb`.

### TeX Live (Linux / macOS)

`texlive-full` already has everything. With a smaller install:

```sh
tlmgr install pdfescape pl polski biblatex biber csquotes circuitikz tabularx makecell threeparttable
```

## 3. Build

Run from the repository root:

```sh
latexmk -pdf RF_PROJECT.tex
```

latexmk runs pdflatex and biber as many times as needed. To remove the build files:

```sh
latexmk -C RF_PROJECT.tex
```

Build files and `RF_PROJECT.pdf` are listed in `.gitignore`, so don't commit them.

## 4. Known harmless warning

`Font shape 'OT4/pcr/m/it' undefined`: Courier has no italic in the Polish font encoding, so LaTeX uses upright Courier instead. This can be ignored.
