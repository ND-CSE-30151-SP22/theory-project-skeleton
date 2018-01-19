#!/bin/bash

ROOT="$(cd "$(dirname $0)" && pwd)"/..
BIN=$ROOT/bin.$(uname | tr A-Z a-z)
SUBMIT=$ROOT/cp2
EXAMPLES=$ROOT/examples
TMPDIR=${TMPDIR:-/tmp}/test-cp2.$$
mkdir -p $TMPDIR
trap "rm -rf $TMPDIR" EXIT
trap "exit 130" INT

assert_equal () {
  if [ "$1" = "$2" ]; then
    echo "PASSED"
  else
    echo "FAILED ($1 != $2)"
  fi
}

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

if [ -x $SUBMIT/parse_re ]; then
  for REGEXP in "(ab|a)*" "(a|b)*aba" "" "a" "a*" "ab" "a|b" "a*b*" "(ab)*" "ab|cd" "(ab)|(cd)" "a*|b*" "(a|b)*" "(a)" "((a))" "()" "|" "(|)"; do
    echo -n 'parse_re "'"$REGEXP"'": '
    assert_equal $($BIN/parse_re "$REGEXP") $($SUBMIT/parse_re "$REGEXP")
  done
else
  echo "parse_re: SKIPPED"
fi

if [ -x $SUBMIT/re_to_nfa ]; then
  for REGEXP in "(ab|a)*" "(a|b)*aba" "" "a" "a*" "ab" "a|b" "a*b*" "(ab)*" "ab|cd" "(ab)|(cd)" "a*|b*" "(a|b)*" "(a)" "((a))" "()" "|" "(|)"; do
      echo -n 're_to_nfa "'"$REGEXP"'": '
      $BIN/compare_nfa <($BIN/re_to_nfa "$REGEXP") <($SUBMIT/re_to_nfa "$REGEXP") > /dev/null
      assert_true
  done
else
  echo "re_to_nfa: SKIPPED"
fi
    

if [ -x $SUBMIT/agrep ]; then
    for W in "" a b aa ab ba bb aaa aab aba abb baa bab bba bbb; do
	echo -n "agrep \"(ab|a)*\" \"$W\": "
	assert_equal $(echo "$W" | $BIN/agrep "(ab|a)*") $(echo "$W" | $SUBMIT/agrep "(ab|a)*")
    done

    for W in "" a b aa ab ba bb aba abaa abab aaba baba aaaba ababa baaba bbaba; do
	echo -n "agrep \"(a|b)*aba\" \"$W\": "
	assert_equal $(echo "$W" | $BIN/agrep "(a|b)*aba") $(echo "$W" | $SUBMIT/agrep "(a|b)*aba")
    done

    for W in "" a; do
	echo -n "agrep \"\" \"$W\": "
	assert_equal $(echo "$W" | $BIN/agrep "") $(echo "$W" | $SUBMIT/agrep "")
    done

    echo "time agrep (this should look linear):"
    RE=
    W=
    for I in $(seq 1 100); do
	RE="(a|)${RE}a"
	W="${W}a"
	if [ $(($I**2/1000)) -gt $((($I-1)**2/1000)) ]; then
	    printf "n=%3d" "$I"
	    echo $W |
		/usr/bin/time -p $SUBMIT/agrep $RE 2>&1 >/dev/null |
		awk '/^(user|sys)/ { t += $2; } END { printf "%*s\n", t*100, "*"; }'
	fi
    done

else
  echo "agrep: SKIPPED"
fi
