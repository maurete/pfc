cmake_minimum_required(VERSION 2.8)
project(data NONE)
set(DATASETS
  coding-tripletsvm-test
  coding-tripletsvm-train
  mirbase50-tripletsvm-test
  mirbase50-tripletsvm-train
  conserved-hairpin
  cross-species
  coding
  functional-ncrna
  mirbase12
  mirbase12-micropred
  mirbase20
  mirbase21
  mirbase21-diff
  mirbase50
  mirbase82-mipred
  other-ncrna
  updated
  )

# find required commands
find_program(C_RNAFOLD RNAfold DOC "RNAfold program")
find_program(C_BASH bash DOC "Bash shell program")
find_program(C_PYTHON python DOC "Python interpreter")
find_program(C_PERL perl DOC "Perl interpreter (used in tripletSVM tests)")
find_program(C_CAT cat DOC "cat command")
find_program(C_ZCAT zcat DOC "zcat command")

# Check if ${C_RNAFOLD} supports '-noPS' switch
execute_process(COMMAND ${C_RNAFOLD} -noPS RESULT_VARIABLE rnafold_nops_single_dash
  INPUT_FILE /dev/null OUTPUT_QUIET ERROR_QUIET )
if(NOT ${rnafold_nops_single_dash})
  set(RNAFOLD_NOPS "-noPS")
endif(NOT ${rnafold_nops_single_dash})

# Check if ${C_RNAFOLD} supports '--noPS' switch
execute_process(COMMAND ${C_RNAFOLD} --noPS RESULT_VARIABLE rnafold_nops_double_dash
  INPUT_FILE /dev/null OUTPUT_QUIET ERROR_QUIET )
if(NOT ${rnafold_nops_double_dash})
  set(RNAFOLD_NOPS "--noPS")
endif(NOT ${rnafold_nops_double_dash})

# Loop over datasets, generating targets and tests
foreach(dataset IN ITEMS ${DATASETS})
  # generate cmake-definition from bash variables
  execute_process(COMMAND ${C_BASH} def2cmake.sh src/${dataset}.def)
  include(src/${dataset}.cmake)
  file(REMOVE src/${dataset}.cmake)

  # loop over species and generate target list
  set(outfiles)
  foreach(species IN ITEMS ${TARGET_SPECIES})
    set(outfiles ${outfiles} ${dataset}/${species}.c ${dataset}/${species}.3
      ${dataset}/${species}.3x ${dataset}/${species}.f
      ${dataset}/${species}.fa ${dataset}/${species}.s)
  endforeach(species)

  # add dataset target
  add_custom_target(${dataset} ALL DEPENDS ${outfiles})

  # special case for tripletSVM datasets, keep original secondary structure
  set(xue 0)
  string(FIND ${dataset} 3svm tripletsvm)
  string(FIND ${dataset} cross-species cross_species)
  string(FIND ${dataset} conserved-hairpin conserved_hairpin)
  if((${tripletsvm} GREATER -1) OR (${cross_species} GREATER -1) OR (${conserved_hairpin} GREATER -1))
    set(xue 1)
  endif((${tripletsvm} GREATER -1) OR (${cross_species} GREATER -1) OR (${conserved_hairpin} GREATER -1))

  if(${xue})
    # this target builds all .c, .s, .3, .3x, .f, .fa files invoking feats.py
    add_custom_command(
      OUTPUT ${outfiles}
      DEPENDS ${SRC}
      COMMAND mkdir -p ${dataset}
      COMMAND ${C_ZCAT} -f ${SRC} | ${C_PYTHON} feats.py by_species -c "${CLS}"
      ${ARG_SPECIES} -o ${dataset}
      )

  else(${xue})
    # this target builds all .c, .s, .3, .3x, .f, .fa files invoking feats.py
    add_custom_command(
      OUTPUT ${outfiles}
      MAIN_DEPENDENCY ${dataset}/.rnafold
      COMMAND ${C_PYTHON} feats.py by_species ${ARG_MULTILOOP} -c "${CLS}"
      ${ARG_SPECIES} -o ${dataset} ${dataset}/.rnafold
      )

    # this target builds .rnafold file invoking ${C_RNAFOLD} program
    add_custom_command(
      OUTPUT ${dataset}/.rnafold
      MAIN_DEPENDENCY ${dataset}/.fasta-clean
      COMMAND ${C_CAT} ${dataset}/.fasta-clean | ${C_RNAFOLD} ${RNAFOLD_NOPS}
      > ${dataset}/.rnafold
      )

    # this target generates "clean" fasta file removing unsupported sequences
    add_custom_command(OUTPUT ${dataset}/.fasta-clean
      DEPENDS ${SRC}
      COMMAND mkdir -p ${dataset}
      COMMAND ${C_ZCAT} -f ${SRC} | ${C_PYTHON} tests.py rnafold_clean ${ARG_DIFF} >
      ${dataset}/.fasta-clean
      )
  endif(${xue})

  # add test targets
  enable_testing()

  # loop over species
  list(LENGTH TARGET_SPECIES len)
  math(EXPR rng "${len} - 1")
  foreach(idx RANGE 0 ${rng})
    list(GET TARGET_SPECIES ${idx} species)
    list(GET TARGET_ENTRIES ${idx} entries)

    # add test for species
    add_test(
      NAME ${dataset}/${species}:${entries}
      COMMAND ${C_BASH} test_build.sh ${dataset} ${species} ${entries}
      )
  endforeach(idx)

endforeach(dataset)

# test triplet extraction (cross-species)
foreach(species IN ITEMS ath cbr cel dme dps dre ebv gga mmu osa rno)
  add_test(
    NAME triplet_features_cross_species_${species}
    COMMAND ${C_BASH} test_fe_triplet.sh
    src/triplet/7_test_dataset/${species}.secondstructure
    src/triplet/8_predict_format_for_libsvm/predict_${species}_non_homology.txt
    )
endforeach(species)

# test triplet extraction (coding test set)
add_test(
  NAME triplet_features_coding_test
  COMMAND ${C_BASH} test_fe_triplet.sh
  src/triplet/7_test_dataset/test_cds_1000.txt
  src/triplet/8_predict_format_for_libsvm/predict_cds_1000.txt
  )

# test triplet extraction (updated)
add_test(
  NAME triplet_features_updated
  COMMAND ${C_BASH} test_fe_triplet.sh
  src/triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt
  src/triplet/8_predict_format_for_libsvm/predict_format_39_hsa_miRNAs_one_stemloop.txt
  )

# test triplet extraction (conserved-hairpin)
add_test(
  NAME triplet_features_conserved_hairpin
  COMMAND ${C_BASH} test_fe_triplet.sh
  src/triplet/7_test_dataset/genome_chr19.txt
  src/triplet/8_predict_format_for_libsvm/predict_genome_chr19.txt
  )

# test triplet extraction (human test set)
add_test(
  NAME triplet_features_human_test
  COMMAND ${C_BASH} test_fe_triplet.sh
  src/triplet/7_test_dataset/test_hsa_30.txt
  src/triplet/8_predict_format_for_libsvm/predict_real_30.txt
  )

# test triplet extraction (coding train set)
add_test(
  NAME triplet_features_coding_train
  COMMAND ${C_BASH} test_fe_triplet.sh
  src/triplet/5_training_dataset/train_cds_168.txt
  src/triplet/5_training_dataset/train_cds_168.txt
  )

# test triplet extraction (human train set)
add_test(
  NAME triplet_features_human_train
  COMMAND ${C_BASH} test_fe_triplet.sh
  src/triplet/5_training_dataset/train_hsa_163.txt
  src/triplet/5_training_dataset/train_hsa_163.txt
  )

# test mipred feature extraction (mirbase 8.2)
add_test(
  NAME mipred_features_mirbase82
  COMMAND ${C_BASH} test_fe_mipred.sh
  src/mipred/miRNAs8.2h/rnafold
  src/mipred/miRNAs8.2h
  )

# test mipred feature extraction (mRNAs)
add_test(
  NAME mipred_features_mrnas
  COMMAND ${C_BASH} test_fe_mipred.sh
  src/mipred/mRNAs/rnafold
  src/mipred/mRNAs
  )

# test mipred feature extraction (coding)
add_test(
  NAME mipred_features_coding
  COMMAND ${C_BASH} test_fe_mipred.sh
  src/mipred/pseudoMiRNAs/rnafold
  src/mipred/pseudoMiRNAs
  )

# test mipred feature extraction (functional-ncrna)
add_test(
  NAME mipred_features_functional_nrrna
  COMMAND ${C_BASH} test_fe_mipred.sh
  src/mipred/Rfam7.0/rnafold
  src/mipred/Rfam7.0
  )

# test micropred feature extraction (mirbase)
add_test(
  NAME micropred_features_mirbase
  COMMAND ${C_BASH} test_fe_micropred.sh
  src/micropred/691-pre-miRNAs.rnafold
  src/micropred/pre-miRNAs-48-features.csv
  )

# test micropred feature extraction (coding)
add_test(
  NAME micropred_features_coding
  COMMAND ${C_BASH} test_fe_micropred.sh
  src/micropred/8494-pseudo-hairpins.rnafold
  src/micropred/pseudo-hairpins-48-features.csv
  )

# test micropred feature extraction (other-ncrna)
add_test(
  NAME micropred_features_other_ncrna
  COMMAND ${C_BASH} test_fe_micropred.sh
  src/micropred/754-other-ncRNAs-fix.rnafold
  src/micropred/other-ncRNAs-48-features.csv
  )
