LATEXCOMPILER = latexmk
LATEXFLAGS = -pdf -pdflatex="pdflatex -interaction=nonstopmode" -use-make

.PHONY: main all clean

all: main

main: main.tex
	$(LATEXCOMPILER) $(LATEXFLAGS) main.tex

clean: 
	$(LATEXCOMPILER) -CA