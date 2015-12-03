% pre-miRNA Sequence Classifier User's Guide
% Mauro Torrez
% December 2, 2015

Introduction
------------

This software is a set of Matlab functions with the end goal of
classifying pre-miRNA sequences via machine learning algorithms.

Some of the functionality provided by the software includes

* FASTA file loading and feature extraction
* Problem generation for describing the classification problem
* Automatic model selection and training of SVM and MLP classifiers
* pre-miRNA classification

A description of the program with a focus on the workflow follows.
Further details on the installation and use of the software are
presented in later sections.

### 1. Problem generation

The two main tasks a learning machine does are learning and
predicting. For learning (or training) it needs a set of known labeled
data from which to learn. For predicting, another dataset must be
provided. The task of specifying these datasets, together with feature
extraction, is what we call _problem generation_.

The [`problem_gen`] function is used for the problem generation.

#### Input format

The software reads its input FASTA files, and is able to handle
embedded secondary structure information in dot-bracket notation like
that produced by [RNAfold].

#### Classification problem description

The problem description specifies the datasets that will be used
for the learning and prediction tasks.

For the learning task, a problem must specify at least:

* A positive-class dataset with training entries
* A negative-class dataset with training entries

For the prediction task, a problem must specify at least:

* A dataset for testing
* Scaling information

#### Feature extraction

Feature extraction is the process of converting the entries in input
text files to numerical vectors suitable for inputting to the learning
machine. This process is done automatically after parsing each FASTA
input file.

For every entry present in a FASTA file, the software builds a
66-element *feature vector* that can itself be subdivided into four
subsets:

* *Triplet features*: these features relate to 'triplet' elements as
    in presented in @xue.
* *Triplet-extra features*: these subset comprises auxilliary measures
	obtained from triplet feature calculations.
* *Sequence features*: measures of the sequence, such as base count
    and length.
* *Secondary structure features*: features pertaining the secondary
	structure such as free energy and base pairings.

A detailed description of the generated feature vector is presented in
[Appendix 1](#thefeatvector).

### 2. Model selection

Model selection involves choosing a classifier and tuning its
parameters with the purpose of maximizing classification performance
for the problem at hand.

The function [`model_select`] is used for this purpose.

#### Supported classifiers

The three classifier types supported are

* *SVM-RBF*: An SVM classifier with Radial Basis Function kernel.
* *SVM-Linear*: An SVM classifier with linear (dot-product) kernel.
* *MLP*: Multi-Layer Perceptron with one hidden layer.

#### Performance measures

Various metrics are available for assessing classifier performance,
in most cases, the default performance measure is $G_m$ defined as
the square root of the sensitivity (SE) and specificity (SP).

#### Automatic model selection

Model selection depends on the selected classifier. Available model
selection methods are:

* *MLP model selection (MLP-only)*: This model selection method simply
  consists of testing classification performance of the MLP with
  varying neurons in the hidden layer, and returning the
  best-performing number of neurons.

* *Trivial model selection (SVM-only)*: This method just returns
  default values for the SVM classifier hyperparameters.

* *Grid-search (SVM-only)*: This method performs a grid-search on the
  hyperparameter space (up to two hyperparameters) of the SVM
  classifier and returns the best-perforing ones.

* *Empirical error criterion (SVM-only)*: This method performs a
  gradient search minimizing the expected risk objective function for
  selecting best SVM hyperparameters.

* *Radius Margin Bound (SVM-RBF-only)*: This method performs a search
  by gradient descent in the hyperparameter space minimizing a
  theoretical (loose) bound for the leave-one-out error and returns
  optimal hyperparameter values.

### 3. Classification

The end goal of most learning machines is classification (prediction):
the labelling of new (unseen) data by applying the model generated
during the training process. Once we've got a suitable problem
definition and classifier model, classifying new entries is a very
simple process.

The function [`problem_classify`] is intended for this purpose.



[`problem_gen`]: #problem_gen
[`model_select`]: #model_select
[`problem_classify`]: #problem_classify

-------------------------------------------------------------------------------


Appendix 1: the feature vector {#thefeatvector}
------------------------------

##### 1-32: Triplet features

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

##### 33-36: "Extra" triplet features

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

##### 37-59: Sequence features

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

##### 60-66: Secondary structure features

This subset contains features related to the secondary structure:

60. *MFE*: minimum free energy
61. *MFEI1*: *MFE* divided by *gc_content* * 100
62. *MFEI4*: *MFE* divided by *basepairs*
63. *dP*: *basepairs* divided by sequence length
64. *|A-U|/length*: `A-U` basepairs divided by sequence length
64. *|G-C|/length*: `G-C` basepairs divided by sequence length
64. *|G-U|/length*: `G-U` basepairs divided by sequence length
