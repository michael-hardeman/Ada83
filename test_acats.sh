#!/bin/bash
mkdir -p acats_logs
passed=0
failed_compile=0
failed_link=0
failed_runtime=0

echo "Testing ACATS test suite..."
echo "============================"

for test in acats/a*.ada acats/b*.ada acats/c*.ada; do
    testname=$(basename $test .ada)
    
    # Skip if already tested
    if [ -f "acats_logs/${testname}.result" ]; then
        continue
    fi
    
    # Compile
    if ! ./ada83 "$test" -o "test_results/${testname}.ll" 2>&1 > "acats_logs/${testname}.compile.log"; then
        echo "COMPILE_FAIL" > "acats_logs/${testname}.result"
        failed_compile=$((failed_compile + 1))
        continue
    fi
    
    # Link
    if ! llvm-link -o "test_results/${testname}.bc" "test_results/${testname}.ll" test_results/report.ll rts/adart.ll 2>&1 > "acats_logs/${testname}.link.log"; then
        echo "LINK_FAIL" > "acats_logs/${testname}.result"
        failed_link=$((failed_link + 1))
        continue
    fi
    
    # Run
    if timeout 2 lli "test_results/${testname}.bc" 2>&1 > "acats_logs/${testname}.run.log"; then
        echo "PASS" > "acats_logs/${testname}.result"
        passed=$((passed + 1))
    else
        echo "RUNTIME_FAIL" > "acats_logs/${testname}.result"
        failed_runtime=$((failed_runtime + 1))
    fi
    
    # Progress indicator every 10 tests
    total=$((passed + failed_compile + failed_link + failed_runtime))
    if [ $((total % 10)) -eq 0 ]; then
        echo "Tested $total tests..."
    fi
done

echo ""
echo "Results:"
echo "  Passed: $passed"
echo "  Failed (compile): $failed_compile"
echo "  Failed (link): $failed_link"
echo "  Failed (runtime): $failed_runtime"
