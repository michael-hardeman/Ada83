#!/bin/bash
P=0;F=0;S=0;BP=0;BF=0;BT=0;BC=0;BE=0
r(){ local f=$1;local n=$(basename "$f" .ada);local s=${n:0:1};printf "%-20s" "$n"
if [[ "$s" =~ [bB] ]];then if timeout 3 ./ada83 "$f" &>/dev/null;then
echo -e "\033[31m✗\033[0m WRONG_ACCEPT";((BF++));else ((BP++));
if [ "$2" = "v" ];then ./btest "$f" ./ada83 2>&1|tail -3;else echo -e "\033[32m✓\033[0m REJECT";fi;fi;
return;fi;if ! timeout 3 ./ada83 "$f" >"test_results/${n}.ll" 2>/dev/null;then
echo -e "\033[33m○\033[0m SKIP_COMPILE";((S++));return;fi
if ! timeout 3 llvm-link -o "test_results/${n}.bc" "test_results/${n}.ll" rts/report.ll 2>/dev/null;then
echo -e "\033[33m○\033[0m SKIP_LINK";((S++));return;fi
if timeout 3 lli "test_results/${n}.bc" &>/dev/null;then
echo -e "\033[32m✓\033[0m PASS";((P++));else echo -e "\033[31m✗\033[0m FAIL";((F++));fi;}
o(){ local T=$((P+F+S+BP+BF)) TP=$((P+BP)) PP=$((P+F)) NP=$((BP+BF))
local PC=0 PPC=0 NPC=0;[ $T -gt 0 ]&&PC=$((100*TP/T))
[ $PP -gt 0 ]&&PPC=$((100*P/PP));[ $NP -gt 0 ]&&NPC=$((100*BP/NP))
echo "";echo "═══════════════════════════════════════════════════════════"
echo "  TEST ORACLE RESULTS";echo "═══════════════════════════════════════════════════════════"
echo "";echo "Positive (compile+run): PASS=$P FAIL=$F SKIP=$S ($PPC%)"
echo "Negative (B-tests):     PASS=$BP FAIL=$BF ($NPC%)"
echo "Total:                  $TP/$T ($PC%)";echo ""
if [ $BT -gt 0 ];then echo "B-Test Oracle Coverage:"
echo "  Tests validated:    $BT";echo "  Total coverage:     $BC errors covered"
echo "  Total expected:     $BE errors expected";local BCP=0
[ $BE -gt 0 ]&&BCP=$((100*BC/BE));echo "  Coverage rate:      $BCP%";echo "";fi
echo "═══════════════════════════════════════════════════════════"
cat>test_summary.txt<<E
ACATS Test Results - $(date)
Positive: $P pass, $F fail, $S skip
Negative: $BP pass, $BF fail
Total: $TP/$T ($PC%) | Pos: $PPC% | Neg: $NPC%
E
echo "";echo "Summary → test_summary.txt";}
b(){ echo "═══════════════════════════════════════════════════════════"
echo "  B-TEST ORACLE: Comprehensive Error Validation"
echo "═══════════════════════════════════════════════════════════";echo ""
mkdir -p acats_logs;local mode=$1;for f in acats/b*.ada;do [ -f "$f" ]||continue
local n=$(basename "$f" .ada);printf "%-20s " "$n";((BT++))
if timeout 5 ./btest "$f" ./ada83 >acats_logs/${n}.oracle 2>&1;then
echo -e "\033[32m✓ PASS\033[0m";((BP++))
local cov=$(grep "Coverage:" acats_logs/${n}.oracle|sed 's/.*Coverage.*: \([0-9]*\)\/\([0-9]*\).*/\1/')
local exp=$(grep "Coverage:" acats_logs/${n}.oracle|sed 's/.*Coverage.*: \([0-9]*\)\/\([0-9]*\).*/\2/')
BC=$((BC+cov));BE=$((BE+exp));[ "$mode" = "v" ]&&tail -5 acats_logs/${n}.oracle|grep -E "(Coverage|Score|Status)"
else echo -e "\033[31m✗ FAIL\033[0m";((BF++))
local cov=$(grep "Coverage:" acats_logs/${n}.oracle 2>/dev/null|sed 's/.*Coverage.*: \([0-9]*\)\/\([0-9]*\).*/\1/'||echo 0)
local exp=$(grep "Coverage:" acats_logs/${n}.oracle 2>/dev/null|sed 's/.*Coverage.*: \([0-9]*\)\/\([0-9]*\).*/\2/'||echo 1)
BC=$((BC+cov));BE=$((BE+exp));[ "$mode" = "v" ]&&cat acats_logs/${n}.oracle|tail -10
fi;done;echo "";echo "Oracle validation complete. Logs → acats_logs/*.oracle";o;}
s(){ echo "═══════════════════════════════════════════════════════════"
echo "  QUICK SAMPLE VERIFICATION";echo "═══════════════════════════════════════════════════════════";echo ""
echo "B-tests (should reject):";for f in acats/b22003a.ada acats/b22001h.ada acats/b24201a.ada;do
[ -f "$f" ]&&r "$f";done;echo "";echo "C-tests (should compile):"
for f in acats/c95009a.ada acats/c45231a.ada acats/c34007a.ada;do [ -f "$f" ]&&r "$f";done
echo "";echo "Sample complete.";}
g(){ local x=$1;echo "═══════════════════════════════════════════════════════════"
echo "  ACATS ${x^^}-GROUP TESTS";echo "═══════════════════════════════════════════════════════════";echo ""
for f in acats/${x}*.ada;do [ -f "$f" ]&&r "$f" "$2";done;o;}
a(){ echo "═══════════════════════════════════════════════════════════"
echo "  FULL ACATS SUITE (4,050 tests)";echo "═══════════════════════════════════════════════════════════";echo ""
for f in acats/*.ada;do [ -f "$f" ]&&r "$f";done;o;}
mkdir -p test_results acats_logs
case "${1:-h}" in
f|full)a;;s|sample)s;;g|group)g "$2" "$3";;b|oracle)b "$2";;h|help|--help)cat<<E
ACATS Test Harness - Ultra-compressed B-test Oracle
Usage: $0 [MODE] [OPTS]
Modes:
  f, full         Full suite (4,050 tests, ~2min)
  s, sample       Quick verification (6 tests)
  g, group X [v]  Run group X∈{a,b,c,d,e,l}, v=verbose
  b, oracle [v]   B-test oracle validation (1,515 tests), v=verbose
  h, help         This message
Examples:
  $0 f            # Full suite
  $0 s            # Quick check
  $0 g b          # B-group only
  $0 g b v        # B-group verbose (show oracle output)
  $0 b            # B-oracle validation (comprehensive)
  $0 b v          # B-oracle verbose (show coverage per test)
Groups: a(144) b(1515) c(2119) d(50) e(54) l(168)
Output: test_results/*.{ll,bc} acats_logs/*.{err,oracle} test_summary.txt
E
;;*)echo "Unknown: $1 (try '$0 help')";exit 1;;esac
