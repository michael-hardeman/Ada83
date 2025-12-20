#!/bin/bash
# Quick sampling test to verify B-test handling

echo "Testing B-test handling with samples..."
echo ""

# Test a few B tests (should be rejected)
echo "B-group tests (negative - should be rejected):"
for f in acats/b22003a.ada acats/b22001h.ada acats/b24201a.ada; do
    if [ -f "$f" ]; then
        n=$(basename "$f" .ada)
        printf "  %-20s " "$n"
        if ./ada83 "$f" >/dev/null 2>&1; then
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
        if ./ada83 "$f" >/dev/null 2>&1; then
            echo -e "\033[32mGOOD\033[0m - compiled successfully"
        else
            echo -e "\033[31mBAD\033[0m - failed to compile"
        fi
    fi
done
