# nombre de los archivos fuente, sin/con extensión:
fuentes = anteproyecto.tex
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

# 'compilador':
cc = pdflatex -interaction nonstopmode
bib = biber
latex = latex

all:	$(fuentes:%.tex=%.pdf) $(dep)
	rm -f $(fuentes_aux)
	rm -f $(biber_aux)

dvipdf:	$(fuentes:%.tex=%_dvipdf)
	rm -f $(fuentes_aux) 

%.pdf:	%.tex
	$(cc) $<
	$(bib) $(<:%.tex=%)
	$(cc) $<

%.dvi:	%.tex
	$(latex) $<
	$(latex) $<

%_dvipdf: %.dvi
	dvipdf $<
	rm -f $< 

clean:
	rm -f $(fuentes:%.tex=%.pdf) $(fuentes:%.tex=%.dvi)
