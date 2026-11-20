#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)"
cd doc && latexmk -pdf RF_PROJECT.tex
