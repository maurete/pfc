# nombre de los archivos fuente
fuentes = propuesta.tex anteproyecto.tex entregable1.tex entregable2.tex \
entregable3.tex cronograma.tex log.tex informe.tex
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
crtf = latex2rtf
bib = biber

all:	$(fuentes:%.tex=%.pdf) $(dep)
	rm -f $(fuentes_aux)
	rm -f $(biber_aux)

rtf:	$(fuentes:%.tex=%.rtf) $(dep)
	rm -f $(fuentes_aux)
	rm -f $(biber_aux)

%.pdf:	%.tex $(dep)
	$(cc) $<
	$(cc) $<
	$(bib) $(<:%.tex=%)
	$(cc) $<

%.rtf:	%.tex $(dep)
	$(cc) $<
	$(bib) $(<:%.tex=%)
	$(crtf) $<

clean:
	rm -f $(fuentes:%.tex=%.pdf)
	rm -f $(fuentes_aux)
	rm -f $(biber_aux)
