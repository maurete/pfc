
Machine Learning-Based pre-miRNA Sequence Classifier
====================================================

This Matlab software is an easy-to-use tool for predicting pre-miRNA
sequences via automatic feature extraction and SVM model selection. It
also provides an interface to
[Web-demo builder](https://bitbucket.org/sinc-lab/webdemobuilder) for
creating a Web interface.

This software is being developed at the
[sinc(i) lab](http://sinc.unl.edu.ar) as a requirement for obtainng an
IT Engineering degree at [FICH-UNL](http://fich.unl.edu.ar/), Santa
Fe, Argentina.

Getting started
----

### Software requirements

For SVM classification, the software requires either
[LIBSVM](http://www.csie.ntu.edu.tw/~cjlin/libsvm/) (recommended) or
Matlab's
[Bioinformatics Toolbox](http://www.mathworks.com/products/bioinfo/).
For MLP classification, support for Matlab's
[Neural Network Toolbox](http://www.mathworks.com/products/neural-network/)
(recommended) and [FANN](http://leenissen.dk/fann/wp/) is available.
[Parallel Computing Toolbox](http://www.mathworks.com/products/parallel-computing/)
is also supported for speeding up the training process.

### Setup

In a Debian GNU/Linux system (stable), follow the steps

1. Install required tools

        sudo aptitude install git build-essential

2. Check out the code

        git clone https://github.com/maurete/pfc.git

3. In Matlab prompt, `cd` to the `src/` folder and run `setup` script

        cd pfc/src setup

   If you get an error building the FANN library, please ignore it:
   FANN support is somewhat experimental and very slow. For now, use
   of Matlab's Neural Network Toolbox is strongly advised. Better FANN
   support might be available in future versions.

4. If you are planning to work with plain (i.e. "unfolded") FASTA
   files, you are strongly advised to install the
   [Vienna RNA Package](http://www.tbi.univie.ac.at/RNA/) for
   extracting secondary structure information. Follow the link for
   downloading and installing instructions for your system.

5. If all went well, you are now ready to start using the software.


Using the software
---

### Matlab command prompt

Once required software is set up, you will be able to invoke the
program functions inside Matlab by doing `cd` to the `src`
directory. The main workflow for using the software is a three-step
process:

1. _Generate classification problem_: use the `problem_gen` function
   for generating the structure describing the classification problem
   at hand, including train and test datasets. Type `help problem_gen`
   in the Matlab prompt for further details on using this function.

2. _Build classifier model_: the function `select_model` lets you
   obtain optimal parameters and train the classifier for the
   specified problem. You can get help on using this function by
   typing `help select_model` in Matlab.

3. _Classify test datasets_: you can perform classification on the
   test dataset for a problem by invoking the function
   `problem_classify` which receives a problem like the one generated
   in step 1 and the model obtained from step 2 as arguments. See the
   built-in help for this function by invoking `help problem_classify`
   within Matlab.

### Web demo interface

Besides the command prompt interface, you can build a basic web
interface for the program with the help of
[Web-demo builder](https://bitbucket.org/sinc-lab/webdemobuilder).
Typing `make` in a shell (not Matlab) prompt inside the `src`
directory will create a .zip file suitable for uploading to a Web-demo
builder instance. Once you uload the file to Web-debo builder, follow
the assistant by selecting `webif` as the main function and setting up
each parameter type and options. More information on what these
parameters mean can be obtained by typing `help webif` in your Matlab
environment.

