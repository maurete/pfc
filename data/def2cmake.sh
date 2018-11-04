#!/bin/bash
# Convert .def file to cmake variable definition
INFILE=${1}
OUTFILE=${INFILE%%.def}.cmake
. ${INFILE}

echo "# Generated with def2make.sh script; do not edit" > ${OUTFILE}
echo "set(NAME ${NAME})" >> ${OUTFILE}
# expand sources with *
AUX0=(${SRC})
echo "set(SRC ${AUX0[@]})" >> ${OUTFILE}
echo "set(CLS ${CLS})" >> ${OUTFILE}
echo "set(ARG_SPECIES ${SPECIES})" >> ${OUTFILE}
echo "set(ARG_MULTILOOP ${MULTILOOP})" >> ${OUTFILE}
echo "set(ARG_DIFF ${SRCDIFF})" >> ${OUTFILE}
echo "set(TARGET_SPECIES ${TEST_SPECIES})" >> ${OUTFILE}
echo "set(TARGET_ENTRIES ${TEST_ENTRIES})" >> ${OUTFILE}
