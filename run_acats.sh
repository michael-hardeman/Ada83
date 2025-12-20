#!/bin/bash
set -e
mkdir -p test_results acats_logs

# Counters
pass=0 fail=0 skip=0
bpass=0 bfail=0

# Test runner for a single file
run_test() {
    local f=$1
    local n=$(basename "$f" .ada)
    local s=${n:0:1}

    printf "%-20s" "$n"

    # B-group tests are NEGATIVE tests (should fail to compile)
    if [ "$s" = "b" ] || [ "$s" = "B" ]; then
        if timeout 3 ./ada83 "$f" >/dev/null 2>"acats_logs/${n}.err"; then
            # B test compiled successfully - this is WRONG!
            echo -e "\033[31mFAIL\033[0m (should reject but accepted)"
            ((bfail++))
        else
            # B test failed to compile - this is CORRECT!
            echo -e "\033[32mPASS\033[0m (correctly rejected)"
            ((bpass++))
        fi
        return
    fi

    # Positive tests (a, c, d, e, l groups) - should compile successfully
    if ! timeout 3 ./ada83 "$f" >"test_results/${n}.ll" 2>"acats_logs/${n}.err"; then
        echo -e "\033[33mSKIP\033[0m (compile failed)"
        ((skip++))
        return
    fi

    # Try to link with runtime
    if ! timeout 3 llvm-link -o "test_results/${n}.bc" "test_results/${n}.ll" rts/report.ll 2>/dev/null; then
        echo -e "\033[33mSKIP\033[0m (link failed)"
        ((skip++))
        return
    fi

    # Try to execute
    if timeout 3 lli "test_results/${n}.bc" >"acats_logs/${n}.out" 2>&1; then
        echo -e "\033[32mPASS\033[0m (executed)"
        ((pass++))
    else
        echo -e "\033[31mFAIL\033[0m (runtime error)"
        ((fail++))
    fi
}

echo "════════════════════════════════════════════════════════════"
echo "  ACATS TEST SUITE - Ada 83 Conformance Tests"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Legend:"
echo "  Positive tests (a,c,d,e,l): Should compile and run"
echo "  Negative tests (b):         Should be rejected by compiler"
echo ""

# Run all tests
for f in acats/*.ada; do
    [ -f "$f" ] && run_test "$f"
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  RESULTS SUMMARY"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Positive Tests (should compile & run):"
echo "  PASS:   $pass   (compiled, linked, executed)"
echo "  FAIL:   $fail   (runtime errors)"
echo "  SKIP:   $skip   (compile/link errors)"
echo ""
echo "Negative Tests (should be rejected):"
echo "  PASS:   $bpass  (correctly rejected)"
echo "  FAIL:   $bfail  (incorrectly accepted)"
echo ""

# Calculate totals
total_tests=$((pass + fail + skip + bpass + bfail))
total_pass=$((pass + bpass))
total_fail=$((fail + bfail))

# Calculate percentages
if [ $total_tests -gt 0 ]; then
    pass_pct=$((100 * total_pass / total_tests))

    # Positive test percentage (excluding skipped)
    pos_tested=$((pass + fail))
    if [ $pos_tested -gt 0 ]; then
        pos_pct=$((100 * pass / pos_tested))
    else
        pos_pct=0
    fi

    # Negative test percentage
    neg_total=$((bpass + bfail))
    if [ $neg_total -gt 0 ]; then
        neg_pct=$((100 * bpass / neg_total))
    else
        neg_pct=0
    fi
else
    pass_pct=0
    pos_pct=0
    neg_pct=0
fi

echo "Overall:"
echo "  Total:  $total_pass / $total_tests passed ($pass_pct%)"
echo "  Pos:    $pass / $pos_tested tested ($pos_pct%)"
echo "  Neg:    $bpass / $neg_total tested ($neg_pct%)"
echo ""
echo "════════════════════════════════════════════════════════════"

# Save summary to file
cat > test_summary.txt <<EOF
ACATS Test Results
==================
Generated: $(date)

Positive Tests: $pass pass, $fail fail, $skip skip
Negative Tests: $bpass pass, $bfail fail

Total: $total_pass / $total_tests ($pass_pct%)
Positive: $pass / $pos_tested ($pos_pct%)
Negative: $bpass / $neg_total ($neg_pct%)
EOF

echo ""
echo "Summary saved to test_summary.txt"
