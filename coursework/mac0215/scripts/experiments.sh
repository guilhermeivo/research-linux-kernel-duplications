#!/usr/bin/env bash

ROOT=$PWD

# compile tree-sitter

cd experiments/tree-sitter && make

cd $ROOT

cd experiments/ && clang          \
    -I tree-sitter/lib/include   \
    c-parser.c                   \
    tree-sitter-c/src/parser.c   \
    tree-sitter/libtree-sitter.a \
    -o c-parser

./c-parser

# ------

cloc experiments/linux --match-f='.*\.(c|h)$'

git -C experiments/linux shortlog -sne --all | wc -l

# arkanjo benchmark ...
