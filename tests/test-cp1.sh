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

if [ -x $SUBMIT/nfa_path ]; then
    for W in 010110 111; do
	echo -n "nfa_path sipser-n1.nfa \"$W\": "
	diff <($BIN/nfa_path $EXAMPLES/sipser-n1.nfa "$W" | head -1) <($SUBMIT/nfa_path $EXAMPLES/sipser-n1.nfa "$W" | head -1)
	assert_true
    done

    for W in "" 0 1 00 01 10 11 000 001 010 011 100 101 110; do
	echo -n "nfa_path sipser-n1.nfa \"$W\": "
	diff <($BIN/nfa_path $EXAMPLES/sipser-n1.nfa "$W") <($SUBMIT/nfa_path $EXAMPLES/sipser-n1.nfa "$W")
	assert_true
    done

    for W in "" 000000; do
	echo -n "nfa_path sipser-n3.nfa \"$W\": "
	diff <($BIN/nfa_path $EXAMPLES/sipser-n3.nfa "$W" | head -1) <($SUBMIT/nfa_path $EXAMPLES/sipser-n3.nfa "$W" | head -1)
	assert_true
    done

    for W in 0 00 000 0000 00000; do
	echo -n "nfa_path sipser-n3.nfa \"$W\": "
	diff <($BIN/nfa_path $EXAMPLES/sipser-n3.nfa "$W") <($SUBMIT/nfa_path $EXAMPLES/sipser-n3.nfa "$W")
	assert_true
    done

    for W in "" a baba baa b bb babba; do
	echo -n "nfa_path sipser-n4.nfa \"$W\": "
	diff <($BIN/nfa_path $EXAMPLES/sipser-n4.nfa "$W") <($SUBMIT/nfa_path $EXAMPLES/sipser-n4.nfa "$W")
	assert_true
    done

    for W in "" a; do
	echo -n "nfa_path cycle.nfa \"$W\": "
	diff <($BIN/nfa_path $EXAMPLES/cycle.nfa "$W" | head -1) <($SUBMIT/nfa_path $EXAMPLES/cycle.nfa "$W" | head -1)
	assert_true
    done

    for W in "" a aa aaa aaaa aaaaa aaaaaa aaaaaaa aaaaaaaa aaaaaaaa aaaaaaaaaa aaaaaaaaaaa; do
	echo -n "nfa_path n10.nfa \"$W\": "
	diff <($BIN/nfa_path $EXAMPLES/n10.nfa "$W" | head -1) <($SUBMIT/nfa_path $EXAMPLES/n10.nfa "$W" | head -1)
	assert_true
    done

    echo "time nfa_path (this should look linear):"
    RE=
    W=
    for I in $(seq 1 100); do
	RE="(a|)${RE}a"
	W="${W}a"
	if [ $(($I**2/1000)) -gt $((($I-1)**2/1000)) ]; then
	    printf "n=%3d" "$I"
	    /usr/bin/time -p $SUBMIT/nfa_path <($BIN/re_to_nfa $RE) "$W" 2>&1 >/dev/null |
		awk '/^(user|sys)/ { t += $2; } END { printf "%*s\n", t*100, "*"; }'
	fi
    done

else
  echo "nfa_path: SKIPPED"
fi
