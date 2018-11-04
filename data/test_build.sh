#!/bin/bash
dataset=${1}
species=${2}
entries=${3}

RET=0
msg(){ ${VERBOSE:-true} && echo ${@} ; }
assert(){ [[ $? -eq 0 ]] || { [[ -n ${1} ]] && msg ${@} ; RET=$(( RET + 1 )) ; } }

# Test feature files for species
for ext in c 3 3x f s
do
    lines=$(wc -l ${dataset}/${species}.${ext} | awk '{print $1}')
    [[ ${lines} -eq ${entries} ]]
    assert "${dataset}/${species}.${ext} should have ${entries} lines, but has ${lines}"
done

# .fa should have n*3 lines
lines=$(wc -l ${dataset}/${species}.fa | awk '{print $1}')
[[ ${lines} -eq $((entries * 3)) ]]
assert "${dataset}/${species}.fa should have $((entries * 3 )) lines, but has ${lines}"

# .c should have one class indicator per line
lines=$(wc -w ${dataset}/${species}.c | awk '{print $1}')
[[ ${lines} -eq ${entries} ]]
assert "${dataset}/${species}.${ext} should have ${entries} lines, but has ${lines}"

# .3 should have 32 features per line
lines=$(wc -w ${dataset}/${species}.3 | awk '{print $1}')
[[ ${lines} -eq $((entries * 32)) ]]
assert "${dataset}/${species}.${ext} should have $((entries * 32)) lines, but has ${lines}"

# .3x should have 4 features per line
lines=$(wc -w ${dataset}/${species}.3x | awk '{print $1}')
[[ ${lines} -eq $((entries * 4)) ]]
assert "${dataset}/${species}.3x should have $((entries * 4)) lines, but has ${lines}"

# .f should have 7 features per line
lines=$(wc -w ${dataset}/${species}.f | awk '{print $1}')
[[ ${lines} -eq $((entries * 7)) ]]
assert "${dataset}/${species}.f should have $((entries * 7)) lines, but has ${lines}"

# .f should have 7 features per line
lines=$(wc -w ${dataset}/${species}.s | awk '{print $1}')
[[ ${lines} -eq $((entries * 23)) ]]
assert "${dataset}/${species}.s should have $((entries * 23)) lines, but has ${lines}"

exit ${RET}
