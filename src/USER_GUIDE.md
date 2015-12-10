% pre-miRNA Sequence Classifier User's Guide
% Mauro Torrez
% December 2, 2015

<div id="content">

Overview {#overview}
--------

This software is a set of Matlab functions with the end goal of
classifying pre-miRNA sequences via machine learning algorithms.

The software provides functionality for

* FASTA file loading
* Feature extraction (with fixed set of features)
* Generating the classification problem structure
* Automatic model selection for SVM and MLP classifiers
* Classification of pre-miRNAs

Basic concepts {#intro}
--------------

The main workflow for using the software is a three-step
process

1. Loading data and describing of the classificaion problem,
2. Choosing which classifier to use and performing model selection, and
3. Classifying pre-miRNA entries of a test dataset.

In the following we explain these concepts, which should give the user
an understanding of the organization of the software.

### 1. Problem generation

Problem generation refers to generating a description of the
classification problem at hand that can be understood by the program.
The classification problem description includes

* The processed (feature vector-coded) data read from input files
* Class label information for entries
* A description of the training dataset, if present
* A description of the testing dataset, if present
* Cross-validation partitioning information
* Scaling (normalization) information

The [`problem_gen`] function is used for the problem generation.

#### Input format

The software reads FASTA files as data sources, and is able to handle
embedded secondary structure information in dot-bracket notation like
that produced by [RNAfold].

#### Feature extraction

Feature extraction is the process of converting the entries in input
text files to numerical vectors suitable for processing by the
learning machine. This process is done automatically after parsing
each FASTA input file. For every entry present in a FASTA file, the
software builds a [66-element fixed feature vector](#thefeatvector).

### 2. Automatic model selection

Model selection involves choosing a classifier and tuning its
parameters with the purpose of maximizing classification performance
for the problem at hand.

The function [`select_model`] is used for this purpose.

#### Supported classifiers

The three classifier types supported are

* *SVM-RBF*: An SVM classifier with Radial Basis Function kernel.
* *SVM-Linear*: An SVM classifier with linear (dot-product) kernel.
* *MLP*: Multi-Layer Perceptron with one hidden layer.

#### Performance measures

Various metrics are available for assessing classifier performance, in
most cases, the default performance measure is $G_m$ defined as the
square root of the product of the sensitivity (SE) and specificity
(SP).

#### Model selection methods

Model selection depends on the selected classifier. Available model
selection methods are:

* *MLP model selection* for use with an MLP classifier,
* *Trivial model selection* which returns default SVM hyperparameters,
* *Grid-search* on the SVM hyperparameter space,
* *Empirical error criterion* minimizing the expected SVM
  cross-validation risk by gradient descent, and
* *Radius Margin Bound*, which optimizes the SVM-RBF hyperparameters
  by minimizing a theoretical bound for the leave-one-out error.

### 3. Classification

The end goal of most learning machines is classification (prediction):
the labelling of new (unseen) data by applying the model generated
during the training process. Once we've got a suitable problem
definition and classifier model, classifying new entries is a very
simple process.

The function [`problem_classify`] is intended for this purpose.


[`problem_gen`]: #problem_gen
[`select_model`]: #select_model
[`problem_classify`]: #problem_classify


Installation {#installation}
------------

### Precompiled binaries

Packages including precompiled binary dependencies for 64-bit GNU/Linux
systems can be obtained from the Github [Project page], in this case,
installation reduces to simply downloading and unpacking the .zip file
and using the functions within Matlab as usual.

[Project page]: https://github.com/maurete/pfc

### Build from source

The following instructions for building from source are provided for a
Debian GNU/Linux system, stable distribution. Actual commands in your
environment might vary.

0. Ensure your environment [meets the requirements](#sysreqs).

1. Install required tools

        sudo aptitude install git libsvm build-essential

2. Optionally download and install the [Vienna RNA Package] by
   following the instructions provided in the linked page.

3. Check out the project code

        git clone https://github.com/maurete/pfc.git

4. In Matlab prompt, `cd` to the `src/` folder and run `setup` script

        cd pfc/src setup

    If you get an error building the FANN library, you can simply
    ignore it, FANN support is somewhat experimental and very slow.

5. For building the .zip for uploading to the [Web-demo builder],
   open a terminal, then inside the `src` directory type

		make

6. If all went well, you are now ready to start using the software.


Command-line usage {#usage}
------------------

The main workflow for using the software in the Matlab command
line is a three-step process:

1. _Generate classification problem_: use the `problem_gen` function
   for generating the structure describing the classification problem
   at hand, including train and test datasets.
   
2. _Build classifier model_: the function `select_model` lets you
   obtain optimal parameters and train the classifier for the
   specified problem.
   
3. _Classify test datasets_: you can perform classification on the
   test dataset for a problem by invoking the function
   `problem_classify` which receives a problem like the one generated
   in step 1 and the model obtained from step 2 as arguments.

### The `problem_gen` function {#problem_gen}

#### Synopsis

	PROBLEM = problem_gen(DATA_SPEC [,OPTIONS] )

#### Description

Generate a classification PROBLEM according to DATA_SPEC.

DATA_SPEC is a cell array with elements in a sequence

	{ SOURCE, CLASS, RATIO , ... }

where

* SOURCE is a string with the filename of a FASTA-formatted file

* CLASS is an integer with the class label for all entries in SOURCE.
  When SOURCE is to be used for training, the value of CLASS must be
  either `-1` for indicating negative class and `+1` for positive class.
  If SOURCE contains test-only data, it can also be set to values
  `0` or `nan`.

* RATIO is the proportion of elements in SOURCE that should be
  considered for training and testing:

	* When RATIO is a single scalar value, it means the proportion
	  of elements that will be used for training. For example, a value
	  of 0.85 means 85% of entries in SOURCE will be used for training
	  and the other 15% will be used for testing. A value of 1 implies
	  all elements in SOURCE should be used for training, and a value
	  of 0 means all entries should be used for testing only.

	* When RATIO is a two-component vector, the first component
	  selects the *number of entries* of SOURCE that will be used for
	  training, and the second component specifies the number of entries
	  of SOURCE that will belong in the test dataset. For example,
	  a value of [123 456] means 123 elements should be used for training
	  and 456 for testing.

The problem description specifies the datasets that will be used
for the learning and prediction tasks.
For the learning task, a problem must specify at least:

* A positive-class dataset with training entries
* A negative-class dataset with training entries

Likewise, for the prediction task, a problem must specify at least:

* A dataset for testing
* Scaling information


OPTIONS is either a cell array or a comma-separated sequence of
options and its arguments. Possible values for options are:

* 'CVPartitions', <INTEGER>: sets the number of train/validation
  partitions to generate for cross-validation training.

* 'CVRatio', <FLOAT>: the ratio of validation elements in each cross-
  validation partition, for example, a value of 0.8 means each partition will
  consist of 80% of entries for training and 20% for testing.
  
* 'Balanced' or 'MLP': tells the program to oversample the minority class
  in order to avoid majority-class bias in MLP training. By default,
  no oversampling is performed.
  
* 'Symmetric': indicates that feature vectors should be normalized
  to the [-1,1] range instead of the default [0,1].

* 'NoVerbose': suppresses standard output. By default, problem
  information is printed to standard output after generation.

* 'Scaling', <2-BY-66-ARRAY>: sets feature vector scaling information,
  according to the array. The first row of the array contains the factor
  by which each feature vector component will be multiplied, and the second row
  sets the offset to be added to each feature vector component after
  being multiplied by the factor.

	When no scaling information is provided, feature vectors are
	normalized to the range [0,1] (or [-1,1]). The goal of providing scaling
	information as input is to let a classifier trained on a different problem
	to be able to classify the current problem also.
  
* <SCALAR INTEGER>: sets the random seed for shuffling the data.
  
* <PROBLEM STRUCT>: extracts the scaling information from the provided
  problem structure.

#### Return value

The returned PROBLEM is a Matlab struct with fields

.traindata: the training set in a matrix where eah row is a feature vector
for a single entry

.trainlabels: column vector with the class label for each row in .traindata

.trainids: indexing information for tracing the source entry in every row

.partitions: indexes defining each cross-validation partition

.randseed: the random seed used for randomizing data

.scaling: feature vector scaling information

.testdata: the testing set matrix

.testlabels: the class label for each row in .testdata

.testids: source tracing information for every entry in .testdata

#### Example

	PROBLEM = problem_gen( { 'mirbase82.fa', 1, [200 123], ...
	                         'hsa2.fa', 1, [20 40], ...
	                         'coding.fa', -1, [400 8094] }, ...
                             'Balanced', 'CVPartitions', 8, ...
							 12345, OTHER_PROBLEM )
							 
Generates a problem structure where

* The training set is composed of 400 positive-class elements oversampled
  randomly from the 220 training elements in mirbase82.fa and hsa2.fa, and
  400 negative-class elements from coding.fa,

* There are 8 cross-validation partitions, each of which will use
  12.5% of elements for validation,

* The random seed 12345 is used for shuffling data,

* The feature vectors are scaled and offset with the scaling information
  present in the OTHER_PROBLEM struct,

* The testing set is composed of 163 positive-class entries from mirbase82.fa
  and hsa2.fa, and 8094 negative-class entries from coding.fa.


### The `select_model` function {#select_model}

#### Synopsis

	MODEL = select_model( PROBLEM, FEATS, CLASSIFIER, METHOD [, OPTIONS] )

#### Description

For a given CLASSIFIER, perform METHOD of model selection by training
with PROBLEM data and feature set FEATS.

"Model selection" refers to the obtention of optimal values for the
classifier hyperparameters, and then training the classifier with
these optimal hyperparameters, returning a trained *model* capable of
further classifying new examples.

The PROBLEM argument is the name of a problem struct as returned by
the `problem_gen` function. Note also that PROBLEM *must* contain
training data for both positive and negative classes.

The FEATS argument is an index number from 1 to 15 which sets the
features considered for building the feature vector. Typical
(and recommended) values for this argument are

* `5`: Build the feature vector with secondary structure-related features
	only, resulting in a 7-component feature vector.

* `8`: Build the feature vector with secondary structure and sequence
	features, resulting in a 20-component feature vector.

##### Classifiers

The CLASSIFIER argument is a string for selecting which classifier wil
be used for building the trained model. Possible values are:

*   `MLP`: A multi-layer perceptron with one hidden layer. The number of
    neurons in the hidden layer is the 'hyperparameter' to optimize.

*   `SVM-RBF`: An SVM classifier with Radial-Basis Function (RBF) kernel.
	Hyperparameters are the box-constraint $C$ and the $\gamma$ RBF spread
	parameter.
	
*   `SVM-linear`: SVM classifier with linear (dot-product) kernel.
	The hyperparameter to this classifier is the $C$ box-constraint value.

##### Model selection methods

Available model selection methods are:

*   `MLP`: The MLP method is the only method available for
	an MLP classifier. It obtains the optimal number of neurons in
	the hidden layer by training and then evaluating classification
	performance for different number of neurons and returning the
	best-performing one.

*   `Trivial`: Can be used with both SVM-RBF and SVM-linear classifiers
	and simply returns the value $\log(C)=0$ and
	$\log(\gamma)=-log(2L)$ in the SVM-RBF case, with $L$ being the
	length of the feature vector (i.e.  the number of features)

*   `Gridsearch`: Applicable to both SVM classifiers, the main idea
    behind this method is to consider $(C,\gamma)$ hyperparameters as
    points in a plane. It works by training and evaluating classifier
    performance in a set of regularly-spaced points ('grid'), and then
    'refining' (interpolating) the grid in the vicinity of those
    points where the best performance measures were found.

	This method is an implementation of the method proposed in @hsu.

*   `Empirical`: The *Empirical Error Criterion* method, available to both
	SVM classifiers, finds optimal parameters by minimizing the *Empirical
	Risk* objective function via gradient descent. The empirical risk
	function is a posterior probability obtained by fitting a probabilistic
	model after SVM training.

	This method is inspired on that presented in @adankon, and incorporates
	the method for obtaining the derivative of the SVM outputs presented
	in @keerthi, described in @glasmachers and implemented in @shark.

*   `RMB`: The *Radius-Margin Bound* method is available for SVM-RBF only, and
    its main idea is that, by minimizing the radius of the hypersphere
	that contains the whole set of support vectors, a bound for the
	leave-one-out error is also reduced, and thus classification error in general.
	Particularly, it is pretty fast and generally yields good hyperparameter
	values.

	This method is an implementation of the one presented in @chung.

##### Options

Extra options cand be (optionally) supplied as a sequence of parameter
or parameter-value options. Possible options are
 
* 'Verbose', <LOGICAL>: sets verbose flag on or off (default=true),

* 'SVMLib', <STRING> : either 'libsvm' or 'matlab' for selecting the
         SVM toolbox to be used (default='libsvm'),

* 'GridSearchCriterion', <STRING> : sets the performance criteria to be
         optimized by the grid search method (default='gm'),

* 'GridSearchStrategy', <STRING> : sets the grid refinement strategy to be
         used by the grid search method (default='threshold'),

* 'GridSearchIterations', <REAL> : sets the # of grid refinement
         iterations to be performed by the grid search method (default=3),

* 'MLPCriterion', <STRING> : sets the performance criteria to be
         optimized by the mlp model selection method,

* 'MLPBackPropagation', <STRING> : sets the back propagation method to be
         used by the mlp model selection method,

* 'MLPNRepeats', <REAL> : sets the number of networks to be trained by the
         mlp model selection method.


#### Return value

#### Example


### The `problem_classify` function {#problem_classify}

#### Synopsis 

    problem_classify Classify test datasets on PROBLEM with MODEL

#### Description

    OUT = problem_classify(PROBLEM,MODEL) Performs classification of the test
	dataset present in PROBLEM by running the classification function in MODEL.
	PROBLEM is a problem as returned by PROBLEM_GEN, and MODEL is a model struct
	as returned by any of the SELECT_MODEL* functions.

#### Return value

OUT is a structure with the following fields:

       .se:      sensitivity (valid only when test labels are supplied)
       .sp:      specificity (valid only when test labels are supplied)
       .gm:      sqrt(se*sp) (valid only when test labels are supplied)
       .predict: class prediction elements in the 'testdata' field of PROBLEM.

#### Example

aaaa

Web interface {#webif}
-------------

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

### Building the web interface with webdemo-builder


### using the web interface



-------------------------------------------------------------------------------


Appendix 1: the feature vector {#thefeatvector}
------------------------------

For every entry in a data set, a fixed-length feature vector is
computed.  This feature vector can be sub-divided into four feature
groups: *triplet*, *triplet-extra*, *sequence* and *secondary
structure* features.  In the following, every element of the feature
vector is described, organized by these groups.

#### 1-32: Triplet features

This subset is computed as in @xue and contains the triplet count for
each of the 32 triplet combinations along the 'stem' part of the
'hairpin' (single-looped) entry. *These features are undefined for
multiple-loop entries*.

For details on these feature set, please refer to @xue.

1.  `A...` triplet count
1.  `A..(` triplet count
1.  `A.(.` triplet count
1.  `A.((` triplet count
1.  `A(..` triplet count
1.  `A(.(` triplet count
1.  `A((.` triplet count
1.  `A(((` triplet count
1.  `G...` triplet count
1.  `G..(` triplet count
1.  `G.(.` triplet count
1.  `G.((` triplet count
1.  `G(..` triplet count
1.  `G(.(` triplet count
1.  `G((.` triplet count
1.  `G(((` triplet count
1.  `C...` triplet count
1.  `C..(` triplet count
1.  `C.(.` triplet count
1.  `C.((` triplet count
1.  `C(..` triplet count
1.  `C(.(` triplet count
1.  `C((.` triplet count
1.  `C(((` triplet count
1.  `U...` triplet count
1.  `U..(` triplet count
1.  `U.(.` triplet count
1.  `U.((` triplet count
1.  `U(..` triplet count
1.  `U(.(` triplet count
1.  `U((.` triplet count
1.  `U(((` triplet count

#### 33-36: "Extra" triplet features

This subset consists of four auxilliary values that arise from
computing triplet features:

33. *length3*: length of the 'stem' part of the single-looped
	pre-miRNA-like entry.
34. *basepairs*: number of base pairs for the entry
35. *length3/basepairs*: measures complementarity between the two
	'arms' of the stem, varying from 2 in the case of perfect
	complementarity and increasing with decreasing complementarity.
36. *gc_content*: number of `G`'s and `C`'s in the stem divided by
*length3*.

#### 37-59: Sequence features

This subset contains sequence measures:

37. sequence length
38. `A` base count
38. `G` base count
38. `C` base count
38. `U` base count
42. `G` base count plus `C` base count
43. `A` base count plus `U` base count
44. `AA` dinucleotide count
44. `AC` dinucleotide count
44. `AG` dinucleotide count
44. `AU` dinucleotide count
44. `CA` dinucleotide count
44. `CC` dinucleotide count
44. `CG` dinucleotide count
44. `CU` dinucleotide count
44. `GA` dinucleotide count
44. `GC` dinucleotide count
44. `GG` dinucleotide count
44. `GU` dinucleotide count
44. `UA` dinucleotide count
44. `UC` dinucleotide count
44. `UG` dinucleotide count
44. `UU` dinucleotide count

#### 60-66: Secondary structure features

This subset contains features related to the secondary structure:

60. *MFE*: minimum free energy
61. *MFEI1*: *MFE* divided by *gc_content* * 100
62. *MFEI4*: *MFE* divided by *basepairs*
63. *dP*: *basepairs* divided by sequence length
64. *|A-U|/length*: `A-U` basepairs divided by sequence length
64. *|G-C|/length*: `G-C` basepairs divided by sequence length
64. *|G-U|/length*: `G-U` basepairs divided by sequence length



System requirements {#sysreqs}
-------------------

In this section all dependencies required for building the software
from source with the full suite of features are listed, in a typical
usage scenario, many of these dependencies are not strictly necessary.

### Operating system

This software can be run on any operating system where MATLAB is available.

### Matlab

This software has been developed and tested on [Matlab] version
R2012b.  Some minor changes might be needed in order for the software
to work in other versions.

### Binary compilation toolchain

Precompiled binaries are only provided for 64-bit GNU/Linux
systems. For any other operating system, a working compilation
toolchain is recommended for building the [LIBSVM] interface.

In a GNU/Linux environment, the [GNU Compiler Collection], version
4.x is recommended. For building the web interface zip file,
[GNU Make] is required.

### LIBSVM

[LIBSVM] is recommended for SVM classification, and required for using
the [RMB] model selection method. If you don't plan on using said
model selection method, you should be fine using Matlab's
[Bioinformatics Toolbox] instead.

### Matlab's Bioinformatics Toolbox

Matlab's own [Bioinformatics Toolbox] can be used with the software
instead of [LIBSVM] when the use of the [RMB] model selection method
is not required.

### Matlab's Neural Network Toolbox

The [Neural Network Toolbox] is the recommended software package for
MLP classification. As an alternative, experimental [FANN] support is
available, though not thoroughly tested.

### FANN

The [FANN] library can be used for MLP classification, though support
for this library is still quite experimental, slow, and overall not
recommended.

### Matlab's Parallel Computing Toolbox

When the [Parallel Computing Toolbox] is available, it will be
used automatically for speeding up the training/model selection
methods.

### Vienna RNA Package

The [Vienna RNA Package] is strongly recommended if you are planning
to work with 'plain' (i.e., not RNAFold'ed) FASTA files. When this
package is unavailable, the much slower `rnafold` function from
Matlab's [Bioinformatics Toolbox] will be used for sequence folding.

[LIBSVM]: http://www.csie.ntu.edu.tw/~cjlin/libsvm/
[Bioinformatics Toolbox]: http://www.mathworks.com/products/bioinfo/
[Neural Network Toolbox]: http://www.mathworks.com/products/neural-network/
[FANN]: http://leenissen.dk/fann/wp/
[Parallel Computing Toolbox]: http://www.mathworks.com/products/parallel-computing/
[Matlab]: http://www.mathworks.com/products/matlab/
[Vienna RNA Package]: http://www.tbi.univie.ac.at/RNA/




</div>

