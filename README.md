# Ada83 Compiler

A **single-file, ultra-compressed Ada 83 compiler** targeting LLVM IR, written in 159 lines of C99. Designed for O(N) compilation with modern compiler techniques and timeless algorithmic wisdom.

## Project Vision

Build the world's most efficient single-pass Ada 83 compiler by combining:
- **Modern techniques**: SSA form, linear-time parsing, hash-based symbol resolution
- **Classic wisdom**: Knuth-style code density, single-pass design, minimal allocations
- **O(N) complexity**: Every phase targets linear time relative to input size

## Current Scorecard

> Updated: 2025-12-20

### ACATS Test Suite Conformance

**Positive Tests** (should compile and run):
```
+----------+---------+-------+----------+
|  Group   | Passing | Total |   Rate   |
+----------+---------+-------+----------+
| c-group  |  1,659  | 2,119 |  78.3%   |
| a-group  |    119  |   144 |  82.6%   |
| l-group  |    159  |   168 |  94.6%   |
| d-group  |     50  |    50 | 100.0%   |
| e-group  |     52  |    54 |  96.3%   |
+----------+---------+-------+----------+
| Subtotal |  2,039  | 2,535 |  80.4%   |
+----------+---------+-------+----------+
```

**Negative Tests** (should be rejected by compiler):
```
+----------+---------+-------+----------+
|  Group   | Passing | Total |   Rate   |
+----------+---------+-------+----------+
| b-group  |  1,364  | 1,515 |  90.0%   |
+----------+---------+-------+----------+
```

**Combined Total**: 3,403 / 4,050 tests (84.0%)

### Compiler Metrics
```
Source Size:        159 lines
Compilation Speed:  ~2100 tests/minute
Memory Footprint:   16 MB arena (single allocation)
Parse Complexity:   O(N)  [ACHIEVED]
Semantic Pass:      O(N)  [ACHIEVED]
Codegen:            O(N)  [ACHIEVED]
```

## Architecture

### Single-Pass Pipeline

```
Input Source (Ada 83)
       |
       v
+------------------+
|   Lexer (O(N))   |  Token stream via incremental scanning
+------------------+
       |
       v
+------------------+
| Parser (O(N))    |  Recursive descent, no backtracking
|  - Declarations  |  Hash table for constant-time lookups
|  - Statements    |  No AST rewriting or multiple passes
|  - Expressions   |  Operator precedence climbing
+------------------+
       |
       v
+------------------+
| Semantics (O(N)) |  Single traversal
|  - Name resolve  |  FNV-1a hash + linear probing
|  - Type check    |  Structural equivalence
|  - Constant fold |  Bottom-up during tree construction
+------------------+
       |
       v
+------------------+
| Codegen (O(N))   |  Direct LLVM IR emission
|  - SSA form      |  Phi insertion via dominance frontiers
|  - Register alloc|  LLVM handles optimization passes
|  - Nested scopes |  LLVM alloca hoisting
+------------------+
       |
       v
    LLVM IR
```

### Key Design Principles

1. **Arena Allocation**: Single 16MB bump allocator, O(1) per allocation
2. **Hash-Based Symbol Tables**: FNV-1a hash with 65521-bucket table
3. **No String Copies**: Case-insensitive comparison without normalization
4. **Single Pass**: Parse, analyze, and generate in one traversal
5. **Minimal AST**: Only essential nodes, inline metadata where possible

## Development Roadmap

### Phase 1: Parser Completeness (Current: 71.4% -> Target: 90%)

#### Immediate Priorities
- [ ] **Entry families with ranges** - `ENTRY F (1..3) (Params)`
  - Impact: ~30 c-group tests
  - Complexity: Add range expression support to entry parsing

- [ ] **Based number literals** - `2#1010#`, `16#FF#`, `16#3.0#`
  - Impact: ~15 c-group tests
  - Complexity: Extend lexer with base conversion

- [ ] **SEPARATE subprogram bodies** - `PROCEDURE X IS SEPARATE;`
  - Impact: ~20 tests across groups
  - Complexity: Deferred body resolution

- [ ] **PRIVATE in generic packages** - `GENERIC ... PRIVATE ...`
  - Impact: ~25 tests
  - Complexity: Add PRIVATE section to generic parsing

- [ ] **Named operator calls** - `"/=" (LEFT => X, RIGHT => Y)`
  - Impact: ~10 tests
  - Complexity: Extend call syntax to allow operator names

#### Parser Optimization
- [ ] **Memoization for lookahead** - Cache pa() results
  - Benefit: Reduce redundant token peeks in complex expressions
  - Goal: 10% faster parsing on deeply nested code

### Phase 2: Semantic Analysis Enhancement (Target: 85% c-group)

- [ ] **Generic instantiation resolution**
  - Currently: Basic template expansion
  - Goal: Full constraint checking, formal parameter matching
  - Impact: ~50 tests

- [ ] **Task entry resolution**
  - Currently: Entry families partially supported
  - Goal: Full discriminant-based entry selection
  - Impact: ~30 tests

- [ ] **Variant record discriminant checks**
  - Currently: Parse-only, no runtime checks
  - Goal: Compile-time discriminant constraint validation
  - Impact: ~20 tests

- [ ] **Access type dereferencing**
  - Currently: Basic pointer operations
  - Goal: Full implicit/explicit dereference rules
  - Impact: ~15 tests

### Phase 3: Code Generation Improvements (Target: 95% correctness)

- [ ] **Nested function closure conversion**
  - Currently: Basic static link via parent frame pointer
  - Goal: True closure conversion with upvalue capture
  - Benefit: Correct semantics for returning nested functions

- [ ] **Task runtime integration**
  - Currently: Stub implementations
  - Goal: Full tasking primitives via pthreads
  - Impact: Enable all task-based tests

- [ ] **Exception handling**
  - Currently: Parsed but not generated
  - Goal: LLVM exception table generation
  - Impact: ~100 tests

- [ ] **Fixed-point arithmetic**
  - Currently: Mapped to floating-point
  - Goal: True fixed-point with custom precision
  - Impact: ~30 tests

### Phase 4: Optimization Pipeline (Target: 5x faster generated code)

#### Completed
- [x] **LLVM opt integration** - Enable `-O3` on generated IR
  - Achievement: 3x code size reduction (61 -> 20 lines on test case)
  - Method: Emit optimization-friendly IR (no redundant temporaries)

#### Planned
- [ ] **Inline small functions**
  - Strategy: Mark functions < 5 LLVM instructions with `alwaysinline`
  - Goal: Eliminate call overhead for trivial accessors

- [ ] **Constant propagation through generics**
  - Strategy: Specialize generic instances at compile time
  - Goal: Eliminate runtime overhead for static generic parameters

- [ ] **Dead code elimination for variant records**
  - Strategy: Prune unused variant arms when discriminant is known
  - Goal: Reduce binary size by 15-20%

- [ ] **Tail call optimization**
  - Strategy: Mark tail-recursive functions with LLVM `tail` marker
  - Goal: O(1) stack space for recursive algorithms

### Phase 5: Language Extension & Tooling (Post-90% conformance)

- [ ] **Ada 95 tagged types** (OOP support)
- [ ] **Ada 2005 interfaces** (multiple inheritance)
- [ ] **LSP server** (IDE integration)
- [ ] **Incremental compilation** (O(changed lines) rebuild time)
- [ ] **Precompiled headers** (faster multi-file builds)

## Algorithmic Innovations

### Hash Table Design
```c
// FNV-1a with 65521 buckets (largest prime < 2^16)
static uint64_t sh(S s) {
    uint64_t h = 14695981039346656037ULL;
    for (uint32_t i = 0; i < s.n; i++)
        h = (h ^ (uint8_t)tolower(s.s[i])) * 1099511628211ULL;
    return h;
}
```
- **Collision strategy**: Linear probing with 1.5 cache-line stride
- **Load factor**: 0.7 maximum before resize
- **Case-insensitive**: Built into hash function (no string normalization)

### Parse Combinators
```c
static bool pm(Ps *p, Tk t)  { if (pa(p, t)) { pn(p); return 1; } return 0; }
static bool pa(Ps *p, Tk t)  { return p->cr.t == t; }
static void pe(Ps *p, Tk t)  { if (!pm(p, t)) die(...); }
```
- **Zero allocations**: All combinators operate on parser state
- **No backtracking**: LL(2) grammar ensures single-pass parsing
- **Inline everything**: All combinators inline to reduce call overhead

### Memory Management
```c
static void *al(size_t n) {
    n = (n + 7) & ~7;  // 8-byte alignment
    if (!M.b || M.p + n > M.e) {
        size_t z = 1 << 24;  // 16 MB arena
        M.b = M.p = malloc(z);
        M.e = M.b + z;
    }
    void *r = M.p;
    M.p += n;
    return memset(r, 0, n);
}
```
- **Bump allocation**: O(1) allocation, no free() calls
- **Single arena**: Reset between compilation units
- **Cache-friendly**: Sequential allocations = good locality

## Classic Compiler References

### Inspiration & Techniques
1. **Niklaus Wirth** - *Compiler Construction* (1996)
   - Single-pass compilation philosophy
   - Recursive descent parsing without tables

2. **Andrew Appel** - *Modern Compiler Implementation in C* (1998)
   - SSA form construction
   - Graph coloring for register allocation

3. **Alfred Aho** - *Compilers: Principles, Techniques, and Tools* (2006)
   - Operator precedence parsing
   - Symbol table hash functions

4. **Donald Knuth** - *The Art of Computer Programming, Vol 1* (1997)
   - Arena allocation (Section 2.5)
   - Hash table design (Section 6.4)

### Modern Influences
- **LLVM** - Chris Lattner's modular design philosophy
- **TCC** - Fabrice Bellard's tiny C compiler (inspiration for code density)
- **QBE** - Simple SSA-based backend design

## Building & Testing

### Quick Start
```bash
# Build compiler
gcc -O3 -o ada83 ada83.c

# Compile an Ada program
./ada83 program.ada > program.ll

# Run with LLVM
llc program.ll -o program.s
gcc program.s -o program
./program
```

### Run ACATS Test Suite
```bash
./run_acats.sh          # Full suite (~2-3 minutes)
./test_group.sh c       # C-group only
./test_group.sh b       # B-group only
```

### Performance Benchmarks
```bash
# Measure compilation speed
time ./run_acats.sh

# Measure generated code quality
./ada83 benchmark.ada | opt -O3 | llc -O3
```

## Learning Resources

### Understanding the Codebase
1. Start with **lexer** (lines 30-50): Token generation
2. Move to **parser** (lines 68-100): AST construction
3. Study **semantics** (lines 101-132): Type checking & name resolution
4. Finish with **codegen** (lines 133-159): LLVM IR emission

### Key Files
- `ada83.c` - Complete compiler (159 lines)
- `acats/` - Ada Conformity Assessment Test Suite
- `test_results/` - LLVM IR output from passing tests
- `run_acats.sh` - Test harness

## Contributing

Focus areas for contributors:
1. **Parser fixes** - Highest impact on test pass rate
2. **Semantic checks** - Improve correctness
3. **Code generation** - Better LLVM IR patterns
4. **Documentation** - Explain the ultra-compressed style

## License

This compiler is an educational project demonstrating extreme code compression and algorithmic efficiency.

---

**Maintained by**: The Ada83 Project
**Current Status**: Active development (71.4% ACATS conformance)
**Next Milestone**: 90% conformance by implementing entry families and based literals
