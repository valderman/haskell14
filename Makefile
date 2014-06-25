all: haskell10f-ekblad.ps haskell10f-ekblad.pdf

haskell10f-ekblad.ps: haskell10f-ekblad.dvi
	dvips -o haskell10f-ekblad.ps haskell10f-ekblad.dvi

haskell10f-ekblad.dvi: haskell10f-ekblad.tex
	pslatex haskell10f-ekblad.tex

haskell10f-ekblad.pdf: haskell10f-ekblad.tex
	pdflatex haskell10f-ekblad.tex
