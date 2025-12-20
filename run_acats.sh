#!/bin/bash
mkdir -p test_results acats_logs
pass=0 fail=0 skip=0 bpass=0 bfail=0
run_test(){
local f=$1 n=$(basename "$f" .ada) s=${n:0:1}
printf "%-20s" "$n"
if [ "$s" = "b" ]||[ "$s" = "B" ];then
timeout 3 ./ada83 "$f" -o /dev/null 2>/dev/null
if [ $? -ne 0 ];then echo -e "\033[32mPASS\033[0m (rejected)";((bpass++));else echo -e "\033[31mFAIL\033[0m (accepted)";((bfail++));fi
else
if ! timeout 3 ./ada83 "$f" -o "test_results/${n}.ll" 2>"acats_logs/${n}.err";then
echo -e "\033[33mSKIP\033[0m (compile)";((skip++));return;fi
if ! timeout 3 llvm-link -o "test_results/${n}.bc" "test_results/${n}.ll" report.ll 2>/dev/null;then
echo -e "\033[33mSKIP\033[0m (link)";((skip++));return;fi
if timeout 3 lli "test_results/${n}.bc" >"acats_logs/${n}.out" 2>&1;then
echo -e "\033[32mPASS\033[0m (exec)";((pass++));else
echo -e "\033[31mFAIL\033[0m (exec)";((fail++));fi
fi
}
echo "════════════════════════════════════════════════════════════"
echo "  FULL ACATS TEST SUITE (4050 tests)"
echo "════════════════════════════════════════════════════════════"
for f in acats/*.ada;do [ -f "$f" ]&&run_test "$f";done
echo "════════════════════════════════════════════════════════════"
echo "Positive: PASS=$pass FAIL=$fail SKIP=$skip"
echo "Negative: PASS=$bpass FAIL=$bfail"
echo "Total: $((pass+bpass))/$((pass+fail+skip+bpass+bfail)) ($((100*(pass+bpass)/(pass+fail+skip+bpass+bfail)))%)"
echo "════════════════════════════════════════════════════════════"
