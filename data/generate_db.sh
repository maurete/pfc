#!/bin/bash

DEF_DIR="src"
C_FOLD="RNAfold -noPS"
C_CDHIT="cdhit"
C_CLEAN="./tests.py rnafold_clean"
C_FEATS="./feats.py by_species"
C_RM="rm -rf"
C_MV="mv -f"
C_MKDIR="mkdir -p"
C_TOUCH="touch"
C_CAT="zcat -f"

rem_current () {
    . ${1}
    [[ -d ${NAME} ]] && {
	echo "Removing directory ${NAME}"; ${C_RM} ${NAME}
    }
}

gen_dataset () {
    . ${1}
    echo "Building ${NAME}"
    ${C_MKDIR} "work/${NAME}"
    ${C_TOUCH} "work/${NAME}.clean"
    ${C_CAT} ${SRC} | ${C_CLEAN} ${SRCDIFF} > work/${NAME}.clean
    # if ${CDHIT}; then
    # 	${C_CDHIT} -i "work/${NAME}.clean" -o "work/${NAME}.nr"
    # 	${C_MV} "work/${NAME}.nr" "work/${NAME}.clean"
    # 	${C_RM} "work/${NAME}.nr.clstr"
    # fi
    ${C_FOLD} < "work/${NAME}.clean" > "work/${NAME}.rnafold"
    ${C_FEATS} ${MULTILOOP} -c "${CLS}" ${SPECIES} \
	       -o "work/${NAME}" "work/${NAME}.rnafold"
    ${C_RM} "work/${NAME}.clean" "work/${NAME}.rnafold"
    ${C_MKDIR} "${NAME}"
    ${C_MV} work/${NAME}/*.[3cfs]* "${NAME}/"
    ${C_RM} "work/${NAME}"
}

for DEFFILE in $(ls ${DEF_DIR}/*.def)
do
    rem_current ${DEFFILE}
done

for DEFFILE in $(ls ${DEF_DIR}/*.def)
do
    gen_dataset ${DEFFILE}
done
