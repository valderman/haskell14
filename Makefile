SOURCES=haskell10f-ekblad.tex macros.tex sigplanconf.cls lsthaskell.tex

all: haskell10f-ekblad.ps haskell10f-ekblad.pdf haskell10f-ekblad.zip

haskell10f-ekblad.ps: haskell10f-ekblad.dvi
	dvips -o haskell10f-ekblad.ps haskell10f-ekblad.dvi

haskell10f-ekblad.dvi: $(SOURCES)
	pslatex haskell10f-ekblad.tex

haskell10f-ekblad.pdf: $(SOURCES)
	pdflatex haskell10f-ekblad.tex

haskell10f-ekblad.zip: $(SOURCES)
	mkdir -p haskell10f-ekblad
	cp -f $(SOURCES) haskell10f-ekblad/
	zip -r haskell10f-ekblad haskell10f-ekblad
