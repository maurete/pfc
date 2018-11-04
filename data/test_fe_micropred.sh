#!/bin/bash
rnafold_file=${1}
feats_file=${2}

RET=0
msg(){ ${VERBOSE:-true} && echo ${@} ; }
assert(){ [[ $? -eq 0 ]] || { [[ -n ${1} ]] && msg ${@} ; RET=$(( RET + 1 )) ; } }

cat ${rnafold_file} | python feats.py micropred | \
    python tests.py --verbose --verbose --verbose micropred -1 - -2 ${feats_file}
assert "Error validating micropred feature extraction!"

exit ${RET}
