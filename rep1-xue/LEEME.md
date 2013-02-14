Cómo probar el clasificador
===========================

0. Asumo que estás usando Debian/Ubuntu

1. Instalar git, python3 y libsvm-tools:

	sudo apt-get install git python3 libsvm-tools
	
2. Bajar el 'Vienna RNA package' (elegir debian, 32- o 64-bit) de
   http://www.tbi.univie.ac.at/~ronny/RNA/index.html#download
   en un terminal, hacer cd a la carpeta donde se bajó el archivo
   y ejecutar
   
    sudo dpkg -i <nombre de archivo>

   por ejemplo,
   
    cd Descargas
	sudo dpkg -i vienna-rna_2.1.1-1_amd64.deb
	
    > nota: este paso es necesario sólo si querés probar el RNAfold
	
3. Clonar el repositorio:

	git clone git@bitbucket.org:maurete/pfc.git

4. Pararse en el directorio prueba1:

	cd pfc/rep1-xue/prueba1
	
5. Probar el script:

	./script.sh
	
Los datos originales se encuentran en la carpeta `original`, para
ver cómo se usa `fautil` y `libsvm` ver el archivo `script.sh`.
