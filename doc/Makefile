# nombre de los archivos fuente
fuentes = propuesta.tex anteproyecto.tex entregable1.tex entregable2.tex \
entregable3.tex cronograma.tex log.tex informe.tex
#
# dependencias
dep = conf/comandos.tex conf/config.tex conf/fuentes.tex \
conf/packages.tex conf/preconfig.tex
#
fuentes_aux = $(fuentes:%.tex=%.aux) $(fuentes:%.tex=%.log) \
$(fuentes:%.tex=%.out) $(fuentes:%.tex=%.toc) $(dep:%.tex=%.aux)
biber_aux = $(fuentes:%.tex=%.bbl) $(fuentes:%.tex=%.bcf) \
$(fuentes:%.tex=%.blg) $(fuentes:%.tex=%.run.xml) \
$(fuentes:%.tex=%-blx.bib)

# usar rubber para compilar pdf
cc   = rubber --pdf
#
cpdf = pdflatex -interaction nonstopmode
crtf = latex2rtf
cbib = biber
crm  = rm -f

# construir pdfs y borrar archivos basura
all:	$(fuentes:%.tex=%.pdf) $(dep)
	@ $(crm) $(fuentes_aux)
	@ $(crm) $(biber_aux)

# generar pdf con rubber
%.pdf:	%.tex $(dep)
# Si la compilacion del archivo falla, borrar el .bcf de biber
	$(cc) $< || ( $(crm) $(<:%.tex=%.bcf); exit 1 )

# generar pdf usando pdflatex plano
%.pdf-old:	%.tex $(dep)
	$(cpdf) $<
	@ $(cpdf) $<
	$(cbib) $(<:%.tex=%)
	@ $(cpdf) $<

# generar rtfs
rtf:	$(fuentes:%.tex=%.rtf) $(dep)
	@ $(crm) $(fuentes_aux)
	@ $(crm) $(biber_aux)

# generar rtf
%.rtf:	%.tex $(dep)
	$(cpdf) $<
	$(cbib) $(<:%.tex=%)
	@ $(crtf) $<

# borrar todos los compilados y auxiliares
clean:
	@ $(crm) $(fuentes:%.tex=%.pdf)
	@ $(crm) $(fuentes_aux)
	@ $(crm) $(biber_aux)
