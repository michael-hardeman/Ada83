# Testing Framework Documentation

## ACATS Test Suite

The Ada Conformity Assessment Test Suite (ACATS) validates Ada compiler conformance. Tests are organized by group:

### Test Groups

#### Positive Tests (Should Compile & Execute)
- **A-group** (144 tests): Language fundamentals, declarations
- **C-group** (2,119 tests): Core language features, largest test set
- **D-group** (50 tests): Representation clauses, pragmas
- **E-group** (54 tests): Distributed systems, annexes
- **L-group** (168 tests): Generic instantiation, elaboration

#### Negative Tests (Should Be Rejected)
- **B-group** (1,515 tests): Invalid code, error detection

**Key Distinction**: B-group tests contain *intentional errors*. A passing B-test means the compiler correctly *rejected* the invalid code.

## Test Validation

### Positive Tests (A, C, D, E, L groups)
```
PASS = Compiled → Linked → Executed successfully
FAIL = Runtime error or incorrect output
SKIP = Compilation or linking error
```

### Negative Tests (B group)
```
PASS = Compiler rejected invalid code (exit code ≠ 0)
FAIL = Compiler accepted invalid code (exit code = 0)
```

## Running Tests

### Full Suite
```bash
./run_acats.sh          # All 4,050 tests (~2-3 minutes)
```

### Sample Verification
```bash
./test_sample.sh        # Quick check of B-test handling
```

### Group-Specific
```bash
# Run only C-group tests
for f in acats/c*.ada; do
    ./ada83 "$f" > "test_results/$(basename $f .ada).ll" 2>&1
done
```

## Output Interpretation

### run_acats.sh Output
```
════════════════════════════════════════════════════════════
  RESULTS SUMMARY
════════════════════════════════════════════════════════════

Positive Tests (should compile & run):
  PASS:   2039   (compiled, linked, executed)
  FAIL:   0      (runtime errors)
  SKIP:   496    (compile/link errors)

Negative Tests (should be rejected):
  PASS:   1364   (correctly rejected)
  FAIL:   151    (incorrectly accepted)

Overall:
  Total:  3403 / 4050 passed (84%)
  Pos:    2039 / 2535 tested (80%)
  Neg:    1364 / 1515 tested (90%)
```

### Metrics Explained

**Positive Test Rate (80.4%)**
- Tests that compile, link, and execute correctly
- Excludes SKIP (compiler doesn't support feature yet)

**Negative Test Rate (90.0%)**
- Invalid code correctly rejected by compiler
- Higher is better (compiler catches more errors)

**Combined Rate (84.0%)**
- Overall conformance: (PASS_pos + PASS_neg) / total_tests
- Industry standard metric for compiler quality

## Test Results Directory

```
test_results/
├── *.ll          # LLVM IR from positive tests
├── *.bc          # Linked bytecode
└── acats_logs/   # Compilation errors, runtime output
```

**Note**: B-group tests generate no .ll files (they fail compilation by design).

## Common Issues

### B-test "Failures"
If B-tests show FAIL, the compiler is *accepting* invalid code:
```bash
# Check which B-tests incorrectly pass
for f in acats/b*.ada; do
    if ./ada83 "$f" >/dev/null 2>&1; then
        echo "WRONG: $(basename $f) compiled but should fail"
    fi
done
```

### Missing Features
High SKIP count indicates unimplemented features:
```bash
# Find most common errors
grep -h "exp.*got" acats_logs/*.err | sort | uniq -c | sort -rn | head -10
```

## Improving Test Pass Rate

### Priority Order
1. **B-group failures** - Fix overly permissive parsing/semantics
2. **C-group skips** - Implement missing language features
3. **Runtime failures** - Fix code generation bugs

### Example: Fixing B-test Failures
```bash
# Find B-test that wrongly compiles
./ada83 acats/b22003a.ada 2>&1

# Should output error like:
# acats/b22003a.ada:19:13: exp ';' got '='

# If it compiles, parser is too lenient
```

## Test Statistics

Current performance by category:
- **100%**: D-group (representation clauses)
- **96.3%**: E-group (distributed features)
- **94.6%**: L-group (generics)
- **90.0%**: B-group (error detection)
- **82.6%**: A-group (fundamentals)
- **78.3%**: C-group (core features)

## Automated Testing

### Continuous Validation
```bash
# Run tests after compiler changes
make clean && make
./run_acats.sh > test_results.log 2>&1

# Compare with baseline
diff baseline_summary.txt test_summary.txt
```

### Regression Detection
```bash
# Save current results
cp test_summary.txt baseline_summary.txt

# After changes, check for regressions
./run_acats.sh
if [ $(grep "Total:" test_summary.txt | cut -d'(' -f2 | cut -d'%' -f1) -lt \
     $(grep "Total:" baseline_summary.txt | cut -d'(' -f2 | cut -d'%' -f1) ]; then
    echo "REGRESSION DETECTED"
    exit 1
fi
```

## Understanding Test Names

Format: `[group][chapter][test_id][variant].ada`

Examples:
- `c45231a.ada` - C-group, chapter 4.5, test 231, variant A
- `b22003a.ada` - B-group (negative), chapter 2.2, test 003, variant A

Chapter mapping (Ada 83 LRM):
- **Chapter 2**: Lexical elements
- **Chapter 3**: Declarations, types
- **Chapter 4**: Names, expressions
- **Chapter 5**: Statements
- **Chapter 6**: Subprograms
- **Chapter 9**: Tasks
- **Chapter 12**: Generics

## Reference

- **ACATS Documentation**: https://www.adaic.org/resources/add_content/standards/05rat/html/Rat-3-4.html
- **Ada 83 LRM**: Reference Manual for the Ada Programming Language (ANSI/MIL-STD-1815A)
- **Test Interpretation**: Negative tests validate error detection, not specific error messages
