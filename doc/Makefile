# nombre de los archivos fuente, sin/con extensión:
fuentes = propuesta.tex
#
texes = $(wildcard '*.tex')
#
dep = conf/comandos.tex conf/config.tex conf/fuentes.tex \
conf/packages.tex conf/preconfig.tex
#
fuentes_aux = $(fuentes:%.tex=%.aux) $(fuentes:%.tex=%.log) \
$(fuentes:%.tex=%.out) $(dep:%.tex=%.aux)

# 'compilador':
cc = pdflatex -interaction nonstopmode
latex = latex

all:	$(fuentes:%.tex=%.pdf) $(dep)
	rm -f $(fuentes_aux) 

dvipdf:	$(fuentes:%.tex=%_dvipdf)
	rm -f $(fuentes_aux) 

%.pdf:	%.tex
	$(cc) $<
	$(cc) $<

%.dvi:	%.tex
	$(latex) $<
	$(latex) $<

%_dvipdf: %.dvi
	dvipdf $<
	rm -f $< 

clean:
	rm -f $(fuentes:%.tex=%.pdf) $(fuentes:%.tex=%.dvi)

