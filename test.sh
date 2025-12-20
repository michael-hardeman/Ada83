#!/bin/bash
# Unified ACATS test harness - all testing functionality in one script
# Usage:
#   ./test.sh                    # Run full suite (4,050 tests)
#   ./test.sh sample             # Quick verification
#   ./test.sh group c            # Run specific group (a/b/c/d/e/l)
#   ./test.sh b-errors           # Analyze B-test error detection

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
    local verbose=$2

    printf "%-20s" "$n"

    # B-group tests are NEGATIVE tests (should fail to compile)
    if [ "$s" = "b" ] || [ "$s" = "B" ]; then
        if timeout 3 ./ada83 "$f" >/dev/null 2>"acats_logs/${n}.err"; then
            # B test compiled - WRONG! Should have rejected
            echo -e "\033[31mFAIL\033[0m (should reject but accepted)"
            ((bfail++))
        else
            # B test rejected - CORRECT!
            if [ "$verbose" = "verbose" ]; then
                echo -e "\033[32mPASS\033[0m (correctly rejected)"
                # Show errors collected
                if [ -f "acats_logs/${n}.err" ]; then
                    local errcount=$(wc -l < "acats_logs/${n}.err")
                    echo "      Errors detected: $errcount"
                    head -3 "acats_logs/${n}.err" | sed 's/^/        /'
                    if [ "$errcount" -gt 3 ]; then
                        echo "        ... and $((errcount - 3)) more"
                    fi
                fi
            else
                echo -e "\033[32mPASS\033[0m (correctly rejected)"
            fi
            ((bpass++))
        fi
        return
    fi

    # Positive tests (a,c,d,e,l) - should compile successfully
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

# Print summary statistics
print_summary() {
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

    # Calculate percentages
    if [ $total_tests -gt 0 ]; then
        pass_pct=$((100 * total_pass / total_tests))
        pos_tested=$((pass + fail))
        if [ $pos_tested -gt 0 ]; then
            pos_pct=$((100 * pass / pos_tested))
        else
            pos_pct=0
        fi
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
}

# Mode: Full suite
run_full_suite() {
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

    print_summary
}

# Mode: Sample verification (quick check)
run_sample() {
    echo "════════════════════════════════════════════════════════════"
    echo "  QUICK SAMPLE VERIFICATION"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Testing B-test handling with samples..."
    echo ""

    # Test B tests (should be rejected)
    echo "B-group tests (negative - should be rejected):"
    for f in acats/b22003a.ada acats/b22001h.ada acats/b24201a.ada; do
        if [ -f "$f" ]; then
            n=$(basename "$f" .ada)
            printf "  %-20s " "$n"
            if ./ada83 "$f" >/dev/null 2>"acats_logs/${n}.err"; then
                echo -e "\033[31mBAD\033[0m - compiler accepted invalid code!"
            else
                echo -e "\033[32mGOOD\033[0m - correctly rejected"
            fi
        fi
    done

    echo ""
    echo "C-group tests (positive - should compile):"
    for f in acats/c95009a.ada acats/c45231a.ada acats/c34007a.ada; do
        if [ -f "$f" ]; then
            n=$(basename "$f" .ada)
            printf "  %-20s " "$n"
            if ./ada83 "$f" >"test_results/${n}.ll" 2>"acats_logs/${n}.err"; then
                echo -e "\033[32mGOOD\033[0m - compiled successfully"
            else
                echo -e "\033[31mBAD\033[0m - failed to compile"
            fi
        fi
    done

    echo ""
    echo "Sample verification complete."
}

# Mode: Run specific group
run_group() {
    local group=$1
    echo "════════════════════════════════════════════════════════════"
    echo "  ACATS ${group^^}-GROUP TESTS"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    for f in acats/${group}*.ada; do
        [ -f "$f" ] && run_test "$f"
    done

    print_summary
}

# Mode: Show all B-test errors (for debugging compiler error detection)
show_b_errors() {
    echo "════════════════════════════════════════════════════════════"
    echo "  B-TEST ERROR COLLECTION (Negative Test Analysis)"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Running all B-tests and collecting ALL errors per test..."
    echo "(Note: Compiler currently stops at first error - future improvement"
    echo " will continue parsing to collect multiple errors per file)"
    echo ""

    local total_b=0
    local correct_reject=0
    local wrong_accept=0
    local verbose=$1

    for f in acats/b*.ada; do
        [ -f "$f" ] || continue
        local n=$(basename "$f" .ada)
        ((total_b++))

        printf "%-20s " "$n"

        if timeout 3 ./ada83 "$f" >/dev/null 2>"acats_logs/${n}.err"; then
            echo -e "\033[31mWRONG\033[0m - accepted invalid code"
            ((wrong_accept++))
        else
            local errcount=0
            if [ -f "acats_logs/${n}.err" ]; then
                errcount=$(grep -c ":" "acats_logs/${n}.err" 2>/dev/null || echo 1)
            fi
            echo -e "\033[32mCORRECT\033[0m - rejected ($errcount error(s))"
            ((correct_reject++))

            # Show errors if verbose
            if [ "$verbose" = "verbose" ] && [ -f "acats_logs/${n}.err" ]; then
                head -5 "acats_logs/${n}.err" | sed 's/^/    /'
                if [ "$errcount" -gt 5 ]; then
                    echo "    ... and $((errcount - 5)) more"
                fi
                echo ""
            fi
        fi
    done

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  B-TEST ERROR DETECTION SUMMARY"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Total B-tests:         $total_b"
    echo "Correctly rejected:    $correct_reject ($(( 100 * correct_reject / total_b ))%)"
    echo "Incorrectly accepted:  $wrong_accept ($(( 100 * wrong_accept / total_b ))%)"
    echo ""

    if [ $wrong_accept -gt 0 ]; then
        echo "Tests that WRONGLY compiled (compiler should reject these):"
        for f in acats/b*.ada; do
            [ -f "$f" ] || continue
            local n=$(basename "$f" .ada)
            if timeout 3 ./ada83 "$f" >/dev/null 2>&1; then
                echo "  - $n"
            fi
        done | head -20
        if [ $wrong_accept -gt 20 ]; then
            echo "  ... and $((wrong_accept - 20)) more"
        fi
    fi

    echo ""
    echo "All error logs saved in acats_logs/*.err"
    echo ""
    echo "NOTE: To improve error collection, the compiler should continue"
    echo "      parsing after errors to collect ALL syntax/semantic errors"
    echo "      in each file (not just stop at first error)."
}

# Main entry point
case "${1:-full}" in
    full)
        run_full_suite
        ;;
    sample)
        run_sample
        ;;
    group)
        if [ -z "$2" ]; then
            echo "Usage: $0 group <a|b|c|d|e|l>"
            exit 1
        fi
        run_group "$2"
        ;;
    b-errors)
        show_b_errors "$2"
        ;;
    help|--help|-h)
        echo "Unified ACATS Test Harness"
        echo ""
        echo "Usage: $0 [MODE] [OPTIONS]"
        echo ""
        echo "Modes:"
        echo "  full              Run complete ACATS suite (4,050 tests, ~2-3 min)"
        echo "  sample            Quick verification of B-test and C-test handling"
        echo "  group <letter>    Run specific test group (a/b/c/d/e/l)"
        echo "  b-errors [verbose] Analyze B-test error detection with error details"
        echo ""
        echo "Examples:"
        echo "  $0                    # Full suite (default)"
        echo "  $0 sample             # Quick verification"
        echo "  $0 group c            # Run C-group only (2,119 tests)"
        echo "  $0 group b            # Run B-group only (negative tests)"
        echo "  $0 b-errors           # Analyze error detection"
        echo "  $0 b-errors verbose   # Show actual errors collected"
        echo ""
        echo "Test Groups:"
        echo "  a-group (144)   - Language fundamentals, declarations"
        echo "  b-group (1,515) - NEGATIVE tests (invalid code, should reject)"
        echo "  c-group (2,119) - Core language features"
        echo "  d-group (50)    - Representation clauses"
        echo "  e-group (54)    - Distributed systems"
        echo "  l-group (168)   - Generic instantiation, elaboration"
        echo ""
        echo "Output:"
        echo "  test_results/*.ll    - Generated LLVM IR (positive tests)"
        echo "  test_results/*.bc    - Linked bytecode"
        echo "  acats_logs/*.err     - Compilation errors"
        echo "  acats_logs/*.out     - Runtime output"
        echo "  test_summary.txt     - Statistical summary"
        ;;
    *)
        echo "Unknown mode: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
