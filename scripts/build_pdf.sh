#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)"
latexmk -pdf ./RF_PROJECT.tex
