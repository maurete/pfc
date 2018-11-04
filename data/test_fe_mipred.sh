#!/bin/bash
rnafold_dir=${1}
feats_dir=${2}

RET=0
msg(){ ${VERBOSE:-true} && echo ${@} ; }
assert(){ [[ $? -eq 0 ]] || { [[ -n ${1} ]] && msg ${@} ; RET=$(( RET + 1 )) ; } }

rnafold_files="$(ls ${rnafold_dir})"
for f in ${rnafold_files}
do
    cat ${rnafold_dir}/${f} | python feats.py mipred | \
    python tests.py mipred -1 - -2 ${feats_dir}/${f%%.rnafold}.stats
    assert "Error validating mipred feature extraction for species ${f%%.rnafold}"
done

exit ${RET}
