# nombre de los archivos fuente
fuentes = propuesta.tex anteproyecto.tex entregable1.tex entregable2.tex \
cronograma.tex log.tex
#
texes = $(wildcard '*.tex')
#
dep = conf/comandos.tex conf/config.tex conf/fuentes.tex \
conf/packages.tex conf/preconfig.tex
#
fuentes_aux = $(fuentes:%.tex=%.aux) $(fuentes:%.tex=%.log) \
$(fuentes:%.tex=%.out) $(dep:%.tex=%.aux)
biber_aux = $(fuentes:%.tex=%.bbl) $(fuentes:%.tex=%.bcf) \
$(fuentes:%.tex=%.blg) $(fuentes:%.tex=%.run.xml) \
$(fuentes:%.tex=%-blx.bib)

#TOP := $(shell pwd)
#TEXINPUTS := .:$(TOP)/skrapport:

cc = pdflatex -interaction nonstopmode
bib = biber

all:	$(fuentes:%.tex=%.pdf) $(dep)
	rm -f $(fuentes_aux)
	rm -f $(biber_aux)

%.pdf:	%.tex $(dep)
	$(cc) $<
	$(bib) $(<:%.tex=%)
	$(cc) $<

clean:
	rm -f $(fuentes:%.tex=%.pdf)
	rm -f $(fuentes_aux)
	rm -f $(biber_aux)
