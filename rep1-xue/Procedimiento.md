Replicar procedimiento de: Xue et al. - TripletSVM
==================================================

1.  Descargo los datos usados en el paper desde el
    [Archivo de Internet][wbm1], ya que no están más disponibles en la
    página original: [datos][wbm2], [código fuente][wbm3].

2.  Instalo el "Vienna RNA Package", se consigue en [esta página][vie1]
    en la sección "Downloads". Uso RNAfold para calcular la estructura
    secundaria de las secuencias.

3.  Tomo el archivo hairpin.fa e intento encontrar los parámetros de
    plegado para RNAfold, tentativamente, invoco el comando como
    sigue:
   
        RNAfold --noPS < hairpin.fa > hairpin.secondstructure

    > Veo que el plegado obtenido es diferente al del paper.
    > Tomo los plegados del paper original para seguir trabajando
	   
4.  Implemento el script `strip-multiple.py` que elimina los hairpins
    con más de un loop. Comparando con los resultados de Xue, funciona
    bien.
   
5.  Uso los pseudo-pre-miRNAs de la carpeta 4 bajados en el punto 1
	como datos de entrenamiento negativos.

6.  Implemento el generador de datos para el SVM según se describe en
    el paper:

    1. Calcular ocurrencia de cada triplet nucleotido - estructura

	2. Contar la frecuencia de cada combinación (32)

	3. Normalizar las magnitudes al rango (0,1) (esto lo hace libsvm
       automáticamente?)

7.  Unifico los scripts en python en el programa 'fautil'. Agrego
	función para generar particiones.

8.  Creo scripts automáticos para probar todo en las carpetas prueba


[wbm1]: http://web.archive.org/web/20120210235054/http://bioinfo.au.tsinghua.edu.cn/software/mirnasvm/
[wbm2]: http://web.archive.org/web/20120210235054/http://bioinfo.au.tsinghua.edu.cn/software/mirnasvm/materials_for_duplicating_results_in_paper.tar.gz
[wbm3]: http://web.archive.org/web/20120210235054/http://bioinfo.au.tsinghua.edu.cn/software/mirnasvm/triplet-svm-classifier.tar.gz
[vie1]: http://www.tbi.univie.ac.at/~ronny/RNA/index.html
