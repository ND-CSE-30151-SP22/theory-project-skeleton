#!/bin/bash

ROOT="$(cd "$(dirname $0)" && pwd)"/..
BIN=$ROOT/bin.$(uname | tr A-Z a-z)
SUBMIT=$ROOT/cp1
EXAMPLES=$ROOT/examples
TMPDIR=${TMPDIR:-/tmp}/test-cp1.$$
mkdir -p $TMPDIR
trap "rm -rf $TMPDIR" EXIT
trap "exit 130" INT

assert_true () {
  if [ $? -eq 0 ]; then
    echo PASSED
  else
    echo FAILED
  fi
}

assert_false () {
  if [ $? -eq 1 ]; then
    echo PASSED
  else
    echo FAILED
  fi
}

assert_equal () {
  if [ "$1" = "$2" ]; then
    echo "PASSED"
  else
    echo "FAILED ($1 != $2)"
  fi
}

if [ -x $SUBMIT/run_nfa ]; then
    for W in 010110 010; do
	echo -n "run_nfa sipser-n1.nfa \"$W\": "
	assert_equal $(echo $W | $BIN/run_nfa $EXAMPLES/sipser-n1.nfa) $(echo $W | $SUBMIT/run_nfa $EXAMPLES/sipser-n1.nfa)
    done

    for W in "" 0 00 000 0000 00000 000000; do
	echo -n "run_nfa sipser-n3.nfa \"$W\": "
	assert_equal $(echo $W | $BIN/run_nfa $EXAMPLES/sipser-n3.nfa) $(echo $W | $SUBMIT/run_nfa $EXAMPLES/sipser-n3.nfa)
    done

    for W in "" a baba baa b bb babba; do
	echo -n "run_nfa sipser-n4.nfa \"$W\": "
	assert_equal $(echo $W | $BIN/run_nfa $EXAMPLES/sipser-n4.nfa) $(echo $W | $SUBMIT/run_nfa $EXAMPLES/sipser-n4.nfa)
    done

    echo "time run_nfa (this should look linear):"
    RE=
    W=
    for I in $(seq 1 100); do
	RE="(a|)${RE}a"
	W="${W}a"
	if [ $(($I**2/1000)) -gt $((($I-1)**2/1000)) ]; then
	    printf "n=%3d" "$I"
	    echo $W |
		/usr/bin/time -p $SUBMIT/run_nfa <($BIN/re_to_nfa $RE) 2>&1 >/dev/null |
		awk '/^(user|sys)/ { t += $2; } END { printf "%*s\n", t*100, "*"; }'
	fi
    done

else
  echo "run_nfa: SKIPPED"
fi

for OP in union concat; do
  if [ -x $SUBMIT/${OP}_nfa ]; then
    for NFA1 in $EXAMPLES/sipser-n{1,2,3,4}.nfa; do
      for NFA2 in $EXAMPLES/sipser-n{1,2,3,4}.nfa; do

        echo -n "${OP}_nfa $(basename $NFA1) $(basename $NFA2): "
        $BIN/compare_nfa <($BIN/${OP}_nfa $NFA1 $NFA2) <($SUBMIT/${OP}_nfa $NFA1 $NFA2) >/dev/null
        assert_true
      done
    done
  else
    echo "${OP}_nfa: SKIPPED"
  fi
done

if [ -x $SUBMIT/star_nfa ]; then
  for NFA in $EXAMPLES/sipser-n{1,2,3,4}.nfa; do
    echo -n "star_nfa $(basename $NFA): "
    $BIN/compare_nfa <($BIN/star_nfa $NFA) <($SUBMIT/star_nfa $NFA) >/dev/null
    assert_true
  done
else
  echo "star_nfa: SKIPPED"
fi

