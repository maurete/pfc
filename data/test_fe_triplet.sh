#!/bin/bash
secondstructure=${1}
original_feats=${2}

RET=0
msg(){ ${VERBOSE:-true} && echo ${@} ; }
assert(){ [[ $? -eq 0 ]] || { [[ -n ${1} ]] && msg ${@} ; RET=$(( RET + 1 )) ; } }

# if original file is fasta, then call Xue's feature extraction utilities
grep -q '^>' ${original_feats} && {
    TEMP1=$(mktemp)
    TEMP2=$(mktemp)
    ./ext_utils/3_step_triplet_coding_for_queries.pl ${original_feats} ${TEMP1}
    assert "Error invoking Xue's triplet coding algorithm"
    ./ext_utils/4_libsvm_format.pl ${TEMP1} ${TEMP2}
    assert "Error invoking Xue's libsvm feature formatting utility"
    rm -f ${TEMP1}
    original_feats=${TEMP2}
}

cat ${secondstructure} | python feats.py triplet | \
    python tests.py triplet -1 - -2 ${original_feats}
assert "Error validating triplet feature extraction!"

exit ${RET}
