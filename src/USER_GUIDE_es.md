---
title: 'Guía del usuario'
subtitle: 'Clasificador de secuencias de pre-miRNA'
author:
- Mauro Torrez
lang: spanish
date: 10 de diciembre 2015
documentclass: scrartcl
#biblio-files: '../doc/res/bibliografia'
#biblio-title: Referencias
#bibliography: '../doc/res/bibliografia.bib'
classoption:
- 'parskip=half-'
- DIV=12
- bibliography=oldstyle
- 12pt
header-includes: |
    \usepackage{libertine}
    \usepackage[scale=0.96]{tgheros}
    \usepackage[scaled=0.9]{zi4}
references:
- author:
  - family: Hsu
    given: Chih-Wei
  - family: Chang
    given: Chih-Chung
  - family: Lin
    given: Chih-Jen
  id: hsu
  issued:
    date-parts:
    - - 2003
  abstract: Support vector machine (SVM) is a popular technique for classification.
    However, beginners who are not familiar with SVM often get unsatisfactory results
    since they miss some easy but significant steps. In this guide, we propose a simple
    procedure, which usually gives reasonable results.
  title: A Practical Guide to Support Vector Classification
  type: report
  publisher: Department of Computer Science, National Taiwan University
  keyword: guide libsvm svm tutorial
- volume: '1'
  page: '151'
  ISBN: '978-0-9719777-1-6'
  container-title: Hands-On Pattern Recognition Challenges in Machine Learning
  author:
  - family: Adankon
    given: Mathias M
  - family: Cheriet
    given: Mohamed
  id: adankon
  issued:
    date-parts:
    - - 2009
  title: Unified framework for SVM model selection
  type: article-journal
  publisher: Microtome Publishing
  editor:
  - family: Guyon
    given: Isabelle
  - family: Cawley
    given: Gavin
  - family: Dror
    given: Gideon
  - family: Saffari
    given: Amir
- page: '673-680'
  container-title: Advances in Neural Information Processing Systems 19
  author:
  - family: Keerthi
    given: S. S.
  - family: Sindhwani
    given: Vikas
  - family: Chapelle
    given: Olivier
  id: keerthi
  issued:
    date-parts:
    - - 2007
  title: An Efficient Method for Gradient-Based Adaptation of Hyperparameters in SVM
    Models
  type: chapter
  publisher: MIT Press
  editor:
  - family: Schölkopf
    given: B.
  - family: Platt
    given: J.C.
  - family: Hoffman
    given: T.
- volume: '15'
  page: '2643-2681'
  container-title: Neural Computation
  author:
  - family: Chung
    given: Kai-Min
  - family: Kao
    given: Wei-Chun
  - family: Sun
    given: Chia-Liang
  - family: Wang
    given: Li-Lun
  - family: Lin
    given: Chih-Jen
  id: chung
  issued:
    date-parts:
    - - 2003
  title: Radius margin bounds for support vector machines with the RBF kernel
  type: article-journal
  publisher: MIT Press
  issue: '11'
- author:
  - family: Glasmachers
    given: Tobias
  id: glasmachers
  issued:
    date-parts:
    - - 2008
  title: Gradient Based Optimization of Support Vector Machines
  type: thesis
  genre: PhD thesis
  publisher: Fakultät für Mathematik, Ruhr-Universität Bochum, Germany
- volume: '9'
  page: '993-996'
  container-title: The Journal of Machine Learning Research
  author:
  - family: Igel
    given: Christian
  - family: Heidrich-Meisner
    given: Verena
  - family: Glasmachers
    given: Tobias
  id: shark
  issued:
    date-parts:
    - - 2008
  title: Shark
  type: article-journal
  publisher: JMLR. org
- ISSN: '1471-2105'
  DOI: 10.1186/1471-2105-6-310
  volume: '6'
  page: '310'
  container-title: BMC Bioinformatics
  author:
  - family: Xue
    given: Chenghai
  - family: Li
    given: Fei
  - family: He
    given: Tao
  - family: Liu
    given: Guo-Ping
  - family: Li
    given: Yanda
  - family: Zhang
    given: Xuegong
  id: xue
  issued:
    date-parts:
    - - 2005
  title: Classification of real and pseudo microRNA precursors using local structure-sequence
    features and support vector machine
  type: article-journal
  issue: '1'
...

<div id="content">




Introducción {#intro}
============

El presente software consiste en una serie de funciones [Matlab] para
clasificación de secuencias de [pre-miRNA] mediante aprendizaje
automático.

Las funcionalidades principales del software son:

* Generación de una estructura que describe el problema de
  clasificación, incluyendo

	* Carga de datos a partir de archivos FASTA

	* Extracción de (un conjunto fijo de) características

	* Definición de conjuntos de entrenamiento, prueba y validación
      cruzada

* Selección automática del modelo del clasificador, incluyendo

	* Posibilidad de utilizar clasificadores SVM o MLP,

	* Ajuste automático de hiperparámetros

	* Entrenamiento
  
* Clasificación de pre-miRNAs en un conjunto de prueba




Conceptos básicos {#basic}
=================

El software se organiza en torno a las tres funcionalidades
principales: *definición del problema*, *selección automática del
modelo*, y *clasificación de entradas de pre-miRNA*. En adelante, se
describen estas funcionalidades, lo que brinda una mejor comprensión
del flujo de trabajo utilizado en el software.


Definición del problema
-----------------------

La definición del problema refiere a la generación de una estructura
que describe el problema de clasificación. Esta estructura es luego
utilizada en las etapas siguientes, para la selección del modelo
(entrenamiento) del clasificador y/o la clasificación de datos de
prueba.

La función [`problem_gen`] se utiliza para la definición del problema,
y la estructura que ésta genera incluye

* Los datos cargados en forma de *vectores de características*

* Información de clase para los conjuntos de datos

* Una especificación de un conjunto de datos de entrenamiento

* Una especificación de un conjunto de datos de prueba

* Información de particionado para validación cruzada

* Información de escalado (normalización) de los vectores de
  caractrísticas

### Extracción de características

La extracción de características consiste en convertir los datos de
entrada (cadenas de texto) en vectores numéricos capaces de ser
manipulados por la máquina de aprendizaje. Este proceso se efectúa en
forma automática al invocar la función [`problem_gen`]. Una
descripción detallada del *vector de características* de 66 elementos
se encuentra en el [Apéndice](#thefeatvector).


Selección del modelo del clasificador
-------------------------------------

La selección del modelo del clasificador consiste en obtener, para un
clasificador determinado, aquellos hiperparámetros que maximizan
alguna medida de desempeño del clasificador para el conjunto de datos
de entrenamiento sobre el que se trabaja. La función [`select_model`]
se utiliza para la selección del modelo.

### Clasificadores

El software permite la utilización de tres tipos de clasificadores:

* *SVM-RBF*: Un clasificador SVM con núcleo de función de base radial
  (RBF).

* *SVM-Linear*: Un clasificador SVM con núcleo lineal (producto
  interno)

* *MLP*: Perceptrón multicapa (MLP) cun una capa oculta.

### Métodos de selección del modelo

El método de selección del modelo depende del clasificador a
utilizar. Los métodos disponibles en el presente software son: MLP,
trivial, búsqueda en la grilla, criterio del error empírico y cota
radio-margen (RMB).  En la descripción de la función [`select_model`]
se detalla cada uno de estos métodos.


Clasificación
-------------

El objetivo principal de cualquier técnica de aprendizaje automático
es la clasificación de nuevos ejemplos a partir de la aplicación del
modelo obtenido con el proceso de entrenamiento.  Cuando se dispone de
un un modelo de clasificador entrenado y una descripción del problema
con datos de prueba, clasificar estos datos de prueba es un
procedimiento sencillo utilizando la función [`problem_classify`].




Requerimientos del sistema {#sysreqs}
==========================

En esta sección se enumeran los requerimientos del sistema necesarios
para la correcta instalación y utilización del software. Se debe tener
en cuenta que, en un uso típico, muchas de estas dependencias no
resultan necesarias.

## Sistema operativo

El software puede ejecutase en cualquier sistema operativo en el que
el software Matlab se encuentre disonible.

## Matlab

El software fue desarrollado y probado en la versión `R2012b` de
[Matlab].  Pueden ser necesarios algunos ajustes menores en el código
para hacer funcionar el software en otras versiones de Matlab.

## Entorno de compilación estándar

Para compilar la dependencia recomendada LIBSVM, se deberá contar con
un entorno de compilación C++. Para un entorno GNU/Linux se recomienda
[GNU Compiler Collection], versión 4.x.  En caso de utilizar la
distribución binaria (únicamente para GNU/Linux 64 bits), esta
dependencia no resulta necesaria.

Para generar el achivo .zip de la interfaz web es necesario el
programa [GNU Make].

## LIBSVM

La biblioteca [LIBSVM] se recomienda para clasificación SVM, y es
requerida por el método RMB de selección de modelo.  Si este método
resulta prescindible, la alternativa del [Bioinformatics Toolbox] de
Mathworks puede ser utilizada sin problemas.

## Bioinformatics Toolbox

El [Bioinformatics Toolbox] de Mathworks se puede utilizar como
alternativa para clasificación SVM.

## Neural Network Toolbox

El [Neural Network Toolbox] de Mathworks es la alternativa recomendada
para el clasificador MLP.

## FANN {#fann}

La biblioteca [FANN] puede utilizarse para clasificación MLP, sin
embargo, el soporte aún es experimental, y en general no se recomienda
su utilización.

## Parallel Computing Toolbox

El [Parallel Computing Toolbox] de Mathworks se aprovecha
automáticamente para mejorar el rendimiento siempre que se encuentre
disponible.

## Vienna RNA Package

El [Vienna RNA Package] se recomienda para poder trabajar con archivos
FASTA 'planos' (esto es, sin información de estructura secundaria).
Cuando este software no está disponible, se utiliza la función
`rnafold` del [Bioinformatics Toolbox] para el plegado de la
estructura secundaria, la cual resulta mucho más lenta que aquella
provista por el [Vienna RNA Package].


[Matlab]:http://www.mathworks.com/products/matlab/
[pre-miRNA]:https://es.wikipedia.org/wiki/Micro_ARN
[LIBSVM]:http://www.csie.ntu.edu.tw/~cjlin/libsvm/
[Bioinformatics Toolbox]:http://www.mathworks.com/products/bioinfo/
[Neural Network Toolbox]:http://www.mathworks.com/products/neural-network/
[FANN]:http://leenissen.dk/fann/wp/
[Parallel Computing Toolbox]:http://www.mathworks.com/products/parallel-computing/
[Vienna RNA Package]:http://www.tbi.univie.ac.at/RNA/

[`problem_gen`]:#problemgen
[`select_model`]:#selectmodel
[`problem_classify`]:#problemclassify




Instalación {#install}
===========

Si bien el software en sí no requiere compilación para ser utilizado,
ciertas dependencias externas sí lo requieren.


Descarga directa
----------------

En la [página del proyecto] en GitHub se publica un archivo con las
dependencias pre-compiladas para un sistema GNU/Linux de 64 bits.  En
este caso, la instalación se reduce a descargar y extraer el archivo y
utilizar las funciones dentro de Matlab como de costumbre.

[página del proyecto]: https://github.com/maurete/pfc


Compilación de las dependencias {#compdep}
-------------------------------

El proceso de compilación de las dependencias debería ser sencillo en la
mayoría de las distribuciones GNU/Linux. Las instrucciones provistas
en esta sección se aplican a un sistema Debian GNU/Linux estable: los
comandos exactos en su plataforma pueden ser diferentes.

1. Asegurarse que el sistema
   [cumple con los requerimientos](#sysreqs).

1. Instalar las herramientas necesarias

        sudo aptitude install git libsvm build-essential

2. Opcionalmente descargar e instalar el [Vienna RNA Package],
   siguiendo las instrucciones en la página enlazada (recomendado).

3. Descargar el código fuente del proyecto

        git clone https://github.com/maurete/pfc.git

4. En la consola de Matlab, cambiar directorio a `src/` y ejecutar la
   función `setup`

		cd pfc/src
		setup

	Si se obtiene un mensaje de error de compilación de la dependencia
	FANN, éste puede ser ignorado: el
	[soporte de la biblioteca FANN](#fann) es aún experimental y
	lento.

5. (Opcional) Construir el archivo .zip para la utilización con
   [Web-demo builder]: en una terminal, dentro del directorio `src`,
   ejecutar

		make

6. Si no hubo problemas, el software está listo para su utilización
   en la carpeta `src`.
	

Verificación de la instalación
------------------------------

Dentro de Matlab, en el directorio `src`, puede verificar
la instalación invocando la función

	setup


Generación de la interfaz web {#webifsetup}
-----------------------------

La generación de la interfaz web para [Web-demo builder] es opcional y
consta de dos partes: cargar la información del programa y configurar
los parámetros de la interfaz.

### Cargar la información del programa

El primer paso es acceder en su navegador a una instancia de
[Web-demo builder], donde encontrará un formulario tal como se muestra
en la [Figura 1](#fig:screen1).

<div id="fig:screen1">
![Página inicial de Web-demo builder\label{fig:screen1}](screen1.png)

</div>

En este formulario debe completar todos los campos de la descripción general,
y cargar el código del programa en la sección "Source code":

* En el campo "Type", elija la opción "Matlab".

* En el campo "File" debe elegir el archivo `.zip` generado en la sección
  anterior [Compilación de las dependencias](#compdep).

Una vez completos todos los campos, se debe presionar el botón
"Upload" para continuar a la configuración de los parámetros.

### Configurar los parámetros de la interfaz

La pantalla de configuración de los parámetros de la interfaz se muestra
en la [Figura 2](#fig:screen2).

<div id="fig:screen2">
![Configuración de parámetros\label{fig:screen2}](screen2b.png)

</div>

Los valores a completar en cada uno de los campos se describen a
continuación.

* *Main function*:

	* *Script file*: `webif.m`
	* *Function*: `webif`

* *Input 1:classifier*

	* *Description*: `Clasificador`
	* *Type*: `Select`
	* *Options*:

			SVM-RBF
			SVM-linear
			MLP

	* *Sample file*: (vacío)

* *Input 2:featureset*

	* *Description*: `Características`
	* *Type*: `Select`
	* *Options*:

			Sequence and secondary structure (8)
			Secondary structure (5)
			Sequence (4)

	* *Sample file*: (vacío)

* *Input 3:method*

	* *Description*: `Método sel. modelo`
	* *Type*: `Select`
	* *Options*:

			Trivial
			Gridsearch
			Empirical error
			RMB
			MLP

	* *Sample file*: (vacío)

* *Input 4:positives*

	* *Description*: `Datos positivos (fasta)`
	* *Type*: `File`
	* *Options*: (vacío)
	* *Sample file*: Opcionalmente, cargar un archivo FASTA con
	  pre-miRNAs de clase positiva y presionar "Upload"

* *Input 5:negatives*

	* *Description*: `Datos negativos (fasta)`
	* *Type*: `File`
	* *Options*: (vacío)
	* *Sample file*: Opcionalmente, cargar un archivo FASTA con pseudo
	  pre-miRNAs y presionar "Upload"

* *Input 6:pre_trained_model*

	* *Description*: `Modelo entrenado`
	* *Type*: `File`
	* *Options*: (vacío)
	* *Sample file*: Opcionalmente, cargar un archivo de modelo tal como
	  lo genera la misma interfaz web y presionar "Upload"

* *Input 7:test_set*

	* *Description*: `Conjunto de prueba`
	* *Type*: `File`
	* *Options*: (vacío)
	* *Sample file*: Opcionalmente, cargar un archivo FASTA con entradas
	  de (pseudo) pre-miRNAs y presionar "Upload"

* *Input 8:test_set_class*

	* *Description*: `Clase conj. prueba`
	* *Type*: `Select`
	* *Options*:

			+1
			-1
			nan

	* *Sample file*: (vacío)

* *Output 1:out*

	* *Description*: `Salida`
	* *Type*: `File`




Uso en línea de comandos {#cmdline}
========================

El flujo de trabajo para la utilización del software en la línea de
comandos de Matlab se ordena según las funcionalidades principales:

1. Generación de la estructura que describe el problema de
   clasificación, mediante la función [`problem_gen`].
   
2. Selección del modelo del clasificador mediante la función
   [`select_model`].
   
3. Clasificación de conjuntos de datos de prueba con el uso de la
   función [`problem_classify`].


La función `problem_gen` {#problemgen}
------------------------

### Sinopsis

	PROBLEMA = problem_gen(DATA_SPEC [,OPCIONES] )

### Descripción

Generar una descripción del problema de clasificación PROBLEMA de
acuerdo a la especificación provista en DATA_SPEC.

#### DATA_SPEC

DATA_SPEC es un arreglo *cell* con entradas en secuencia

	{ ORIGEN, CLASE, RATIO , ... }

donde

* ORIGEN es el nombre de un archivo en formato FASTA.

* CLASE es un entero con la etiqueta correspondiente a todos los
  elementos contenidos en el archivo ORIGEN. Toda vez que los
  elementos de ORIGEN se utilicen para entrenamiento del clasificador
  (selección del modelo), CLASE debe tomar ya sea el valor `-1`,
  indicando clase negativa, o `+1` para la clase positiva.  Si el
  archivo ORIGEN contiene únicamente entradas del conjunto de prueba,
  se permiten además los valores `0` or `nan` para indicar clase
  desconocida.

* RATIO es la proporción de elementos en ORIGEN que se considerarán
  para entrenamiento y prueba:

	* Si es un escalar, indica la proporción de elementos que se
	  utilizarán para entrenamiento. Por ejemplo, un valor de $0.85$
	  implica que el $85\%$ de elementos de ORIGEN pasarán a formar
	  parte del conjunto de datos de entrenamiento, y el $15\%$
	  restante se utilizará para el armado del conjunto de datos de
	  prueba. Un valor de $1$ indica que se utilizarán todos los
	  elementos en ORIGEN para entrenamiento, y el valor $0$ implica
	  que todos los elementos en ORIGEN se incorporarán al conjunto de
	  datos de prueba.

	* Si RATIO es un vector con 2 componentes, el primer componente
	  indica el *número de elementos* de ORIGEN que se utilizarán para
	  el conjunto de entrenamiento, mientras que el segundo componente
	  indica el número de elementos a incorporar al conjunto de
	  prueba. De este modo, un valor de $[123, 456]$ indica que se
	  deberán utilizar 123 elementos de ORIGEN para el conjunto de
	  entrenamiento, y otros 465 para componer el conjunto de prueba.

#### OPCIONES

OPCIONES es una secuencia ordenada de opciones (con sus respectivos
argumentos), separadas por comas.  Las opciones posibles son:

* `'CVPartitions', <ENTERO>`: establece el número de particiones de
  entrenamiento/validación a generar para el entrenamiento de
  validación cruzada. Por defecto, se generan 10 particiones.

* `'CVRatio', <DECIMAL>`: es la proporción de elementos de
  entrenamiento y validación en cada partición de validación
  cruzada. Como ejemplo, un valor de 0.8 indica que cada partición
  utilizará el 80% de los elementos del conjunto de entrenamiento para
  entrenamiento, y el 20% restante para validación. Si se omite esta
  opción, se utiliza el valor por defecto de $1/N$, donde $N$ es el
  número de particiones de validación cruzada.

* `'Balanced'` o `'MLP'`: indica que la clase minoritaria deberá ser
  sobremuestreada (repitiendo elementos), de modo de evitar un sesgo
  hacia la clase mayoritaria. Este sesgo se presenta al utilizar
  clasificadores MLP. Por defecto, no se efectúa ningún sobremuestreo
  sobre el conjunto de datos original.
  
* `'Symmetric'`: indica que los vectores de características se deberán
  normalizar al rango $[-1,1]$ en logar del rango por defecto $0,1$.
  Este parámetro tiene efecto sólo cuando no se provee información de
  escalado adiional.
  
* `'NoVerbose'`: Evita la impresión de información a la salida estándar.
  Por omisión, una vez generado el problema se imprime información del
  mismo a la salida estandar.

* `'Scaling', <ARREGLO-2-X-66>`: provee información de escalado
  calculada previamente para aplicar al problema. La primer fila del
  arreglo contiene el factor por el cual se multiplicará cada elemento
  del vector de características, mientras que la segunda fila indica
  un desfasaje respecto al origen que será añadido a cada elemento del
  vector de características.  Cuando no se provee información de
  escalado, los vectores de características son normalizados
  automáticamente al rango preestablecido $[0,1]$ (o $[-1,1]$ si se
  especifica la opción `'Symmetric'`).
  
* `<ENTERO>`: se utiliza como semilla aleatoria para la generación del
  problema.

* `<STRUCT PROBLEMA0>`: se utiliza para extraer la información de
  escalado a partir del problema pasado como argumento.

#### Consideraciones

Al momento de generar un problema de clasificación, se deben tener en cuenta
las siguientes consideraciones:

* *Conjunto de datos de entrenamiento*: si se pretende utilizar el
  PROBLEMA generado para entrenamiento del clasificador (selección del
  modelo), se deberán incorporar elementos tanto de clase positiva
  como de clase negativa al conjunto de datos de entrenamiento.

* *Conjunto de datos de prueba*: si se desea utilizar PROBLEMA para
  clasificación, éste deberá contener entradas de cualquier clase,
  incluso desconocida, en el conjunto de datos de prueba.

* *Datos de escalado*: la información de escalado se calcula
  automáticamente a partir de los conjuntos de datos provistos. Si se
  desea clasificar elementos del PROBLEMA con un modelo obtenido
  entrenando sobre otro problema PROBLEMA0, se deberá proveer la
  información de escalado de PROBLEMA0 para evitar problemas de
  clasificación debido al escalado automático.

#### Estructura de salida

La estructura PROBLEMA devuelta por el método contiene los campos:

* `.traindata`: El conjunto de datos de entrenamiento, representado en
  una matriz donde cada fila se corresponde con un vactor de
  características para cada elemento.

* `.trainlabels`: Un vector columna con la etiqueta de clase para cada
  fila en `.traindata`.

* `.trainids`: Información de trazabilidad para cada entrada del
  conjunto de prueba. La tercer columna contiene el índice del archivo
  al que pertenece la entrada, que se corresponde con el elemento del
  mismo índice en `.sources`, mientras que la primer columna indica la
  línea de comienzo de la entrada en el archivo FASTA respectivo.

* `.partitions`: Contiene índices que definen cada partición de
  validación cruzada.

* `.randseed`: La semilla utilizada para aleatorización de los
  elementos en la generación del problema.

* `.scaling`: Información de escalado del vector de características.

* `.testdata`: El conjunto de datos de prueba, en una matriz análoga
  a `.traindata`.

* `.testlabels`: Vector con etiquetas de clase para el conjunto de prueba.

* `.testids`: Información de trazabilidad para los elementos del conjunto de
  prueba, análoga a aquella en `.trainids`.

* `.sources`: Un arreglo *cell* con los nombres de los archivos leídos.
  El orden de los elementos de `.sources` determina el identificador
  de archivo que se indica en la tercera columna de `.trainids` y `.testids`.

### Ejemplo

La invocación

	PROBLEMA = problem_gen( { 'mirbase82.fa', 1, [200 123], ...
	                          'hsa2.fa', 1, [20 40], ...
	                          'coding.fa', -1, [400 8094] }, ...
                              'Balanced', 'CVPartitions', 8, ...
							  12345, PROBLEMA0 )
							 
Crea una estructura PROBLEMA con las siguientes características:

* El conjunto de entrenamiento se compone de:

	* 400 elementos de clase positiva, sobremuestreados aleatoriamente
	  de 220 elementos en los archivos `mirbase82.fa` y `hsa2.fa`
	  
	* 400 elementos de clase negativa, sin repetición, leídos del
	  archivo `coding.fa`.

* Se definen 8 particiones de validación cruzada, cada una de las
  cuales utilizará un $12.5\%$ de los elementos del conjunto de
  entrenamiento para validación.

* Se utiliza la semilla $12345$ para aleatorizar los datos.

* Los vectores de características se escalan y desplazan a partir de la
  información de escalado presente en el problema PROBLEMA0.

* El conjunto de datos de prueba está compuesto por $163$ elementos de
  clase positiva extraídos de `mirbase82.fa`, y $8094$ elementos de clase
  negativa extraídos del archivo `coding.fa`.


La función `select_model` {#selectmodel}
-------------------------

### Sinopsis

	MODELO = select_model( PROBLEMA, CARACTS, CLASIF, MÉTODO [, OPCIONES] )

### Descripción

Efectuar MÉTODO de selección de modelo para un clasificador CLASIF con
los datos de entrenamiento en PROBLEMA y un (sub-)conjunto de
características CARACTS, y devolver el modelo obtenido.

La *selección del modelo* refiere a la obtención de valores óptimos
para los hiperparámetros del clasificador, y luego entrenar el
clasificador con estos hiperparametros óptimos, devolviendo un
*modelo* entrenado que servirá para clasificar nuevos ejemplos.

#### Problema de clasificación

El argumento PROBLEMA es una estructura tal como aquella retornada por
la función [`problem_gen`], la cual *debe* contener entradas de ambas
clases (positiva y negativa) en el conjunto de datos de entrenamiento.

#### Características {#feats}

El argumento CARACTS es un número entre $1$ y $15$ que selecciona la
combinación de características a considerar para el entrenamiento.
Los valores recomendados para CARACTS son

* $5$: Considerar únicamente las características de estructura
  secundaria.

* $8$: Considerar tanto las características de estructura secundaria
  como las de la secuencia.

La utilización de otros valores de CARACTS puede introducir efectos no
deseados sobre el conjunto de datos, debido a la inclusión de las
características de triplete, que son calculables únicamente para
entradas de (pseudo-)pre-miRNAs con bucle único. Para detalles
sobre la composición del vector de características, consultar
el [Apéndice 1](#thefeatvector).

#### Clasificadores {#classifier}

El argumento CLASIF es una cadena de texto que especifica el
clasificador que se desea utilizar. Los valores posibles son:

* `'MLP'`: Perceptrón multicapa con una capa oculta. El hiperparámetro
	a optimizar en la selección del modelo es el número de neuronas en
	la capa oculta.

* `'SVM-RBF'`: Clasificador SVM con núcleo de función de base radial
	(RBF).  Los hiperparámetros a optimizar son la constantede
	tolerancia a errores $C$ y la amplitud $\gamma$ de la función de
	base radial.
	
* `SVM-linear`: Clasificador SVM con núcleo lineal (de producto
	interno).  El hiperparámetro a optimizar en este caso es la
	contante $C$.

#### Método de selección del modelo {#method}

El argumento MÉTODO es una cadena de texto que especifica el método
a utilizar para selección del modelo, y depende del clasificador
especificado. Los valores posibles son:

* `'MLP'`: El método MLP es el único metodo disponible para el
	clasificador MLP. Entrena el clasificador para diferentes valores
	de neuronas en la capa oculta y devuelve aquel que obtiene el
	mayor rendimiento al clasificar el conjunto de validación.

* `'Trivial'`: El método trivial se puede utilizar con los
	clasificadores`'SVM-RBF'` y `'SVM-linear'`, y retorna un modelo
	entrenado con los valores de hiperparámetros $\log(C)=0$ y
	$\log(\gamma)=-\log(2L)$ siendo $L$ el número de características
	consideradas para entrenamiento.

* `Gridsearch`: El método de búsqueda en la grilla se puede utilizar
	con ambos tipos de clasificadores SVM. La idea detrás de este
	método es considerar la combinación de hiperparámetros
	$(C,\gamma)$ como puntos en el plano. Mediante entrenamiento y
	evaluación del rendimiento del clasificador sobre una serie de
	puntos espaciados regularmente (la "grilla"), se refina
	(interpola) la grilla en las cercanías de los puntos donde se
	obtiene el mayor rendimiento.

	Este método es una implementación de la técnica propuesta en @hsu.

* `'Empirical'`: El método del *criterio del error empírico* se puede
	utilizar con ambos tipos de clasificadores SVM y obtiene los
	valores óptimos de los hiperparámetros minimizando la función
	objetivo del *riesgo empírico* mediante descenso por gradiente.
	La función de riesgo empírico es una probabilidad posterior de
	error de clasificación obtenida ajustando un modelo probabilístico
	sobre la salida del clasificador luego del entrenamiento.

	Este método está basado en aquel presentado en @adankon, e
	incorpora un metodo de cálculo de la derivada de las salidas de la
	SVM como aquel presentado en @keerthi, descripto en @glasmachers e
	implementado en @shark.
	
* `RMB`: El método de la *cota radio-margen* (*Radius-Margin Bound,
	RMB*) se puede utilizar únicamente con el clasificador
	`'SVM-RBF'`. El funcionamiento de este método se basa en minimizar
	el radio de la hiperesfera que contiene el conjunto de los
	vectores de soporte, lo que a partir de una derivación teórica
	implica minimizar la cota del error *dejar-uno-fuera* y por lo
	tanto el error de clasificación en general. Este método tiene la
	particularidad de ser muy rápido y obtener valores razonablemente
	buenos para los hiperparámetros.

	Este método es una implementación del méto propuesto en @chung.

#### Opciones

Se pueden incluir las siguientes OPCIONES como una secuencia ordenada
de parámetros (con sus argumentos), separada por comas:
 
* `'Verbose', <LOGICAL>`: especifica si imprimir o no información a la
  salida estándar. Valor por defecto: `true`.

* `'SVMLib', <STRING>`: donde `<STRING>` es uno de los valores
  `'libsvm'` o `'matlab'`, especifica la biblioteca a utilizar para
  clasificación SVM. Valor por defecto: `'libsvm'`.
  
* `'GridSearchCriterion', <STRING>`: especifica el criterio a utilizar
  como medida de desempeño del clasificador para el método de búsqueda
  en la grilla. Los valores posibles son `'se'` (sensibilidad), `'sp'`
  (especificidad), o `'gm'` (media geométrica de la sensibilidad y la
  especificidad. Valor por defecto: `'gm'`.

* `'GridSearchStrategy', <STRING>`: especifica la estrategia de
  refinamiento para el método de búsqueda en la grilla. Los valores
  posibles son `'zoom'`, `'threshold'` y `'nbest'`. Valor por defecto:
  `'threshold'`.

* `'GridSearchIterations', <REAL>`: establece el número de etapas de
  refinamiento para el método de búsqueda en la grilla. Valor por
  defecto: $3$.

* `'MLPCriterion', <STRING>`: especifica el criterio a utilizar como
  medida de desempeño del clasificador para el método MLP.  Análoga a
  la opción `'GridSearchCriterion'`para búsqueda en la grilla.  Valor
  por defecto: `'gm'`.

* `'MLPBackPropagation', <STRING>`: establece el método de propagación
  hacia atrás a utilizar para entrenamiento del clasificador
  MLP. Valor por defecto: `'rprop'`.

* `'MLPNRepeats', <REAL>`: establece el número de clasificadores a
  entrenar por el método MLP, para evitar condicionantes de la
  inicialización aleatoria de la red neuronal. Valor por defecto: $5$.

### Salida

La salida de la función es una estructura de Matlab MODELO que
contiene el clasificador entrenado con los hiperparámetros óptimos, y
que puede ser utilizada como entrada a [`problem_classify`] para
clasificar nuevos problemas. Los campos contenidos en esta estructura
son:

* `.model`: el modelo del clasificador entrenado,

* `.trainfunc`: la función de entrenamiento del clasificador,

* `.trainfuncargs`: argumentos de la función de entrenamiento,

* `.classfunc`: la función de clasificación a invocar para clasificar
  nuevos elementos, y

* `.features`: índices de las características consideradas al realizar
  el entrenamiento.

### Ejemplo

La invocación

	MODELO = select_model( PROBLEMA, 5, 'mlp', 'mlp', ...
	                       'MLPCriterion', 'se', ...
						   'MLPBackPropagation', 'trainscg')

Realiza selección de modelo para un clasificador MLP entrenando con
los datos de entrenamiento presentes en PROBLEMA, considerando las
características de estructura secundaria, utilizando la sensibilidad
como medida de desempeño a maximizar, y utilizando la función de
propagación hacia atrás `trainscg` para entrenamiento del MLP.


	MODELO = select_model( PROBLEMA, 8, 'svm-rbf', 'rmb' )

Realiza selección de modelo para un clasificador SVM con núcleo RBF
mediante el método RMB, entrenando con los datos de entrenamiento
presentes en PROBLEMA, y considerando las características de secuencia
y de estructura secundaria.

La función `problem_classify` {#problemclassify}
-----------------------------

### Sinopsis 

	RES = problem_classify(PROBLEMA,MODELO)

### Descripción

Clasificar los elementos del conjunto de prueba presente en PROBLEMA
aplicando el MODELO del clasificador entrenado.

PROBLEMA es una estructura que describe el problema de clasificación tal como la
devuelta por la función [`problem_gen`], y debe contener entradas en el conjunto
de datos de prueba.

MODELO es un modelo de clasificador obtenido utilizando la función
[`select_model`].

### Salida

RES es una estructura de Matlab con los siguientes campos:

* `.se`: sensibilidad (tasa de acierto en la clasificación de elemetos
  de clase positiva)

* `.sp`: especificidad (tasa de acierto en la clasificación de
  elemetos de clase negativa)

* `.gm`: media geométrica de la sensibilidad y la especificidad

* `.predict`: predicciones de clase para cada elemento presente en el
  campo `.testdata` de la estructura PROBLEMA.

Notar que, si el conjunto de datos de prueba en PROBLEMA no contiene
información de clase válida, los valores de `.se`, `.sp` y `.gm` serán
igualmente inválidos.




Utilización de la interfaz web {#webif}
==============================

El software brinda la posibilidad de utilización a través de una
interfaz web básica, generada con ayuda de la herramienta
[Web-demo builder]. Las instrucciones para la generación de esta
interfaz están disponibles en la sección [Instalación](#webifsetup).

La interfaz web permite tanto la generación del modelo (entrenamiento)
como la clasificación o predicción de un conjunto de datos de prueba.
Además permite efectuar ambas operaciones de entrenamiento y prueba de
una sola vez. En todos los casos, el procedimiento consiste en
completar los campos necesarios, presionar el botón "Enviar" (Submit),
y una vez finalizado el proceso acceder al enlace que se muestra en el
campo "Salida" para verificar los resultados.

Una captura de la interfaz web se muestra en la [Figura 3](#fig:screen3).
Se ha cargado una instancia de demostración en el servidor provisto
por los autores de Web-demo builder, disponible en
[este enlace](http://ec2-52-5-194-68.compute-1.amazonaws.com/scripts/57769864/webif/).

<div id="fig:screen3">
![Interfaz web del software generada con Web-demo builder
\label{fig:screen3}](screen3.png)

</div>

Generación del modelo (entrenamiento) {#webtrain}
-------------------------------------

Para la generación del modelo del clasificador, se deben
elegir los parámetros de entrenamiento y cargar conjuntos de datos
tanto positivos como negativos.

### Clasificador

El campo "Clasificador" permite elegir entre los tres clasificadores
disponibles: SVM-RBF, SVM-linear o MLP. Estos clasificadores se
describen en la sección [Clasificadores](#classifier).

### Características

Las características a considerar se seleccionan en el campo
"Caracerísticas". Las [opciones posibles](#feats) son:

* Secuencia y estructura secundaria (8)
* Estructura secundaria (5)
* Secuencia (4)

### Método de selección del modelo

En este campo se permite elegir entre los diferentes
[métodos de selección del modelo](#method) disponibles:

* Trivial
* Error empírico
* RMB
* Búsqueda en la grilla (gridsearch)
* MLP

Las mismas consideraciones que se enumeran en la descripción de la
función [`select_model`] son aplicables a la elección de
clasificador y método de selección del modelo.

### Datos positivos

Para generación del modelo se debe cargar un conjunto de datos
positivos, conteniendo pre-miRNAs reales, en formato FASTA,
seleccionando el archivo a cargar y luego presionando el botón
"Upload". Para un mejor rendimiento, se recomienda que el archivo
FASTA contenga información de plegado de la estructura secundaria tal
como se obtiene al utilizar RNAFold.

### Datos negativos

Para generación del modelo se debe cargar un conjunto de datos
negativos, conteniendo pseudo pre-miRNAs, en formato FASTA,
seleccionando el archivo a cargar y luego presionando el botón
"Upload". Para un mejor rendimiento, se recomienda que el archivo
FASTA contenga información de plegado de la estructura secundaria tal
como se obtiene al utilizar RNAFold.

### Ejecución del programa y archivo de salida.

Una vez completados los pasos anteriores se debe presionar el botón
"Enviar" (Submit) y esperar hasta la finalización del método.
Una vez finalizado el proceso, en el enlace "Salida" se accede a un
reporte de la ejecución del programa.

Si el proceso fue exitoso, el reporte se presenta en formato HTML, y
este archivo contiene internamente el modelo del clasificador
entrenado para utilización futura.

> Descargando el reporte de generación del modelo, puede utilizarlo
> más adelante para clasificar nuevos datos cargándolo como un
> "Modelo entrenado"

Si, en cambio, se encuentra un error en la ejecución del programa, se
presenta un archivo de texto plano con extensión `.log`. En este caso,
se recomienda leer este archivo para intentar encontrar cuál ha sido
el punto de falla.


Clasificación de un conjunto de prueba {#webtest}
--------------------------------------

Para la clasificación de un conjunto de datos de prueba se
requiere, además del archivo FASTA con los datos de prueba,
un modelo del clasificador entrenado. Este modelo puede ser

* Generado al mismo tiempo cargando los campos especificados en la
  [sección anterior](#webtrain), o bien

* Cargando un archivo de modelo entrenado obtenido al realizar
  previamente una generación del modelo.

### Modelo entrenado

El modelo entrenado es simplemente el archivo de reporte HTML
obtenido al efectuar la generación del modelo. Se debe elegir el archivo
presionando el botón "Choose file", y luego presionar el botón "Upload".

Alternativamente, puede omitir cargar un modelo entrenado y generar el
modelo "al vuelo" completando los campos "Clasificador",
"Características" y "Metodo sel. modelo" y cargando los archivos de
datos positivos y negativos. Este procedimiento se explica en detalle en
la [sección anterior](#webtrain).

### Conjunto de prueba

Se debe cargar un conjunto de datos de prueba seleccionando el
archivo FASTA a cargar y luego presionando el botón
"Upload". Para un mejor rendimiento, se recomienda que el archivo
FASTA contenga información de plegado de la estructura secundaria tal
como se obtiene al utilizar [RNAFold].

### Clase del conjunto de prueba

Opcionalmente, puede elegir la clase del conjunto de prueba.
Esto no tiene otra utilidad que el cálculo de una "tasa de acierto"
que se muestra en el reporte de salida. Si no se conoce la clase de los
elementos del conjunto de prueba, se recomienda elegir la opción `nan`.

### Obtención del reporte de salida

Presionando el botón "Enviar" (Submit) el programa procede a la
predicción de la clase de los elementos del conjunto de prueba
y los muestra en un reporte en formato HTML.

Si ocurre un error en el proceso, se muestra en cambio un reporte
en formato de texto plano con la salida del programa.



[Web-demo builder]: https://bitbucket.org/sinc-lab/webdemobuilder




Apéndice
========


El vector de características {#thefeatvector}
----------------------------

Para cada entrada en el conjunto de datos se calcula
un *vector de características*, que puede subdividirse en cuatro
grupos de características, según los atributos de la entrada que
representan.

Los cuatro grupos de características son: *triplete*,
*triplete-extra*, *secuencia*, y *estructura secundaria*.  En
adelante, se describe el vector de características elemento a
elemento, organizados según estos grupos de características.

### 1-32: Características de triplete

Este grupo de características se calcula tal como se propone en el
trabajo original @xue, y cuenta la ocurrencia de cada uno de las 32
combinaciones de tripletes sobre los nucleótidos que se ubican a lo
largo del 'tallo' en las entradas de bucle único.  Por definición,
*estas características no están definidas para entradas con estructura
secundaria de múltiples lazos*.

Para más detalles en el significado de estas características,
se refiere al lector al trabajo original @xue.

1. número de tripletes `A...` 
1. número de tripletes `A..(` 
1. número de tripletes `A.(.` 
1. número de tripletes `A.((` 
1. número de tripletes `A(..` 
1. número de tripletes `A(.(` 
1. número de tripletes `A((.` 
1. número de tripletes `A(((` 
1. número de tripletes `G...` 
1. número de tripletes `G..(` 
1. número de tripletes `G.(.` 
1. número de tripletes `G.((` 
1. número de tripletes `G(..` 
1. número de tripletes `G(.(` 
1. número de tripletes `G((.` 
1. número de tripletes `G(((` 
1. número de tripletes `C...` 
1. número de tripletes `C..(` 
1. número de tripletes `C.(.` 
1. número de tripletes `C.((` 
1. número de tripletes `C(..` 
1. número de tripletes `C(.(` 
1. número de tripletes `C((.` 
1. número de tripletes `C(((` 
1. número de tripletes `U...` 
1. número de tripletes `U..(` 
1. número de tripletes `U.(.` 
1. número de tripletes `U.((` 
1. número de tripletes `U(..` 
1. número de tripletes `U(.(` 
1. número de tripletes `U((.` 
1. número de tripletes `U(((` 

### 33-36: Características de tripletes "extra"

Este grupo de características se compone de cuatro medidas
que resultan del cálculo de las características de tripletes:

33. *length3*: longitud en nucleótidos del 'tallo' de la entrada.
34. *basepairs*: número de pares de bases.
35. *length3/basepairs*: mide la complementariedad entre ambos
	'brazos' de la estructura de horquilla, variando a partir de 2
	cuando la complementariedad es perfecta e incrementando su valor
	conforme la complementariedad disminuye.)  measures
	complementarity between the two
36. *gc_content*: número de `G`s y `C`s en el tallo, dividido por
    *length3*.

### 37-59: Características de la secuencia

Este grupo contiene medidas de la secuencia:

37. longitud de la secuencia
38. número de bases `A` 
38. número de bases `G` 
38. número de bases `C` 
38. número de bases `U` 
42. número de bases `G` más número de bases `C` 
43. número de bases `A` más número de bases `U` 
44. número de dinucleótidos `AA` 
44. número de dinucleótidos `AC` 
44. número de dinucleótidos `AG` 
44. número de dinucleótidos `AU` 
44. número de dinucleótidos `CA` 
44. número de dinucleótidos `CC` 
44. número de dinucleótidos `CG` 
44. número de dinucleótidos `CU` 
44. número de dinucleótidos `GA` 
44. número de dinucleótidos `GC` 
44. número de dinucleótidos `GG` 
44. número de dinucleótidos `GU` 
44. número de dinucleótidos `UA` 
44. número de dinucleótidos `UC` 
44. número de dinucleótidos `UG` 
44. número de dinucleótidos `UU` 

### 60-66: Características de la estructura secundaria

Este grupo contiene características de la estructura secundaria de la
entrada:

60. *MFE*: mínima energía libre
61. *MFEI1*: *MFE* dividido por *gc_content* * 100
62. *MFEI4*: *MFE* dividido por *basepairs*
63. *dP*: *basepairs* dividido por la longitud de la secuencia (37)
64. *|A-U|/length*: pares de bases `A-U` dividido por la longitud de
    la secuencia (37)
64. *|G-C|/length*: pares de bases `G-C` dividido por la longitud de
    la secuencia (37)
64. *|G-U|/length*: pares de bases `G-U` dividido por la longitud de
    la secuencia (37)


</div>

# Referencias
