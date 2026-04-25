# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

This project uses CMake locally (Bazel is not installed in this environment).

**First-time setup:**
```bash
source env.sh                       # Set up PATH for LLVM tools and tutorial-opt
./cmake_build.sh               # Build LLVM/MLIR dependency (one-time, ~30 min)
```

**Everyday development:**
```bash
./cmake_test.sh                          # Full configure + build + test
cmake --build build-ninja --target tutorial-opt     # Rebuild driver only (fast)
cmake --build build-ninja --target check-mlir-tutorial  # Run tests only
```

**Rebuilding individual pass libraries (faster than full rebuild):**
```bash
cmake --build build-ninja --target MLIRMulToAddPasses
cmake --build build-ninja --target MLIRAffineFullUnrollPasses
cmake --build build-ninja --target MLIRNoisyPasses
```

**Bazel (alternative, not used locally):**
```bash
bazel build ...:all
bazel test ...:all
```

## Architecture

This is a tutorial codebase for the [MLIR compiler framework](https://mlir.llvm.org/). It implements two custom dialects and a series of progressively more sophisticated passes.

### Custom Dialects

- **`poly`** (`lib/Dialect/Poly/`) — single-variable polynomials over integers. Operations: `add`, `sub`, `mul`, `eval`, `from_tensor`, `to_tensor`, `constant`. Has canonicalization patterns, folders, and a verifier.
- **`noisy`** (`lib/Dialect/Noisy/`) — noisy integers that simulate cryptography by tracking noise growth. Operations: `add`, `sub`, `mul`, `encode`, `decode`, `reduce_noise`. Implements `InferIntRangeInterface` for integer range dataflow analysis.

### Passes

- **Transform passes** (`lib/Transform/`):
  - `AffineFullUnroll` — manually walks IR to unroll affine loops
  - `MulToAdd` — greedy rewrite engine: replaces `mul` with `add` chains (power-of-two and peel patterns)
  - `MulToAddPdll` — same transforms using PDLL (Pattern Definition Language) instead of C++ patterns
  - `ReduceNoiseOptimizer` — solves an integer linear program (via or-tools SCIP) to optimally insert `reduce_noise` ops, then runs integer range dataflow analysis to verify correctness
- **Conversion pass** (`lib/Conversion/PolyToStandard/`) — full dialect conversion lowering `poly` ops to `arith`/`tensor`/`scf`. Includes `PolyToStandardTypeConverter` that converts `PolynomialType` to `RankedTensorType`.
- **Analysis** (`lib/Analysis/ReduceNoiseAnalysis/`) — ILP-based analysis consumed by `ReduceNoiseOptimizer`

### TableGen → Generated Code Flow

Dialects, types, ops, and passes are defined in `.td` files. `mlir-tblgen` produces `.h.inc` and `.cpp.inc` files at build time. C++ files include these with macros:

```cpp
#define GEN_PASS_DEF_PASSNAME
#include "lib/Transform/.../Passes.h.inc"
```

Never edit generated `.inc` files directly. When adding new ops, types, or passes, update both the `.td` files and the corresponding `BUILD` / `CMakeLists.txt` files.

### Test Infrastructure

Tests are `.mlir` files in `tests/` using `// RUN:` lines and `FileCheck` assertions, run via `lit`. The driver is `tools/tutorial-opt.cpp` (patterned after `mlir-opt`), which registers all dialects and passes and provides a `poly-to-llvm` pipeline that lowers through LLVM IR.

After `source env.sh`, `tutorial-opt` is on PATH. To run a single test:
```bash
cmake --build build-ninja --target tutorial-opt && \
  python3 -m lit tests/poly_canonicalize.mlir
```

The `poly-to-llvm` pipeline chains: PolyToStandard → canonicalize → linalg/tensor lowering → one-shot bufferization → buffer deallocation → convert linalg to loops → SCF to CF → CF/Arith/Func/MemRef to LLVM → cleanup passes.

### Dependency

LLVM/MLIR is vendored at `externals/llvm-project`. CMake points at `externals/llvm-project/build` via `LLVM_DIR`/`MLIR_DIR`; the shell scripts set these paths. Bazel fetches it via `new_git_repository` in `extensions.bzl` (commit pinned). Do not edit vendored files unless intentionally updating the LLVM commit.
