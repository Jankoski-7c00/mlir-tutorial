# Repository Guidelines

## Project Structure & Module Organization

This local repository is developed with CMake. Core C++ and TableGen code lives under `lib/`, grouped by concern: `lib/Dialect/` for dialect definitions such as `Poly` and `Noisy`, `lib/Transform/` for passes, `lib/Conversion/` for lowering, and `lib/Analysis/` for analyses. The `tools/` directory builds `tutorial-opt`, the main command-line driver used by tests. MLIR regression tests live in `tests/` as `.mlir` files with `RUN:` and `FileCheck` directives. Vendored LLVM/MLIR sources are under `externals/llvm-project`; avoid editing them unless intentionally updating the dependency.

## Build, Test, and Development Commands

- `./cmake_build.sh`: configure and build the LLVM/MLIR dependency with Ninja.
- `./cmake_test.sh`: configure this project, build tutorial targets, and run `check-mlir-tutorial`.
- `cmake --build build-ninja --target tutorial-opt`: rebuild only the tutorial driver after CMake configuration.
- `cmake --build build-ninja --target check-mlir-tutorial`: run the MLIR tutorial regression tests.
- `cmake --build build-ninja --target MLIRMulToAddPasses`: rebuild one pass library while iterating.

Use Ninja-backed CMake builds in `build-ninja/`. Keep `LLVM_DIR` and `MLIR_DIR` pointed at `externals/llvm-project/build/lib/cmake/{llvm,mlir}` when configuring manually.

## Coding Style & Naming Conventions

Use LLVM/MLIR C++ style: two-space indentation, `UpperCamelCase` for classes and MLIR operation/type definitions, `lowerCamelCase` for functions and local variables, and `kConstantName` only where LLVM style expects constants. Keep generated include patterns consistent with nearby files, for example `#include "lib/Dialect/Poly/PolyOps.cpp.inc"` after required MLIR headers. Name pass, dialect, and conversion files after the feature they implement, such as `MulToAdd.cpp` or `PolyToStandard.cpp`.

## Testing Guidelines

Add or update `.mlir` tests in `tests/` for every dialect, pass, conversion, or verifier behavior change. Prefer focused tests with explicit `// RUN:` lines and `// CHECK:` assertions using `tutorial-opt` and `FileCheck`. Name tests after the behavior under test, for example `poly_canonicalize.mlir` or `noisy_reduce_noise.mlir`. Run `cmake --build build-ninja --target check-mlir-tutorial` before submitting changes.

## Commit & Pull Request Guidelines

Recent history uses short, imperative or descriptive commit subjects, often scoped when useful, such as `cmake: update llvm submodule commit` or `Bump LLVM Version`. Keep commits focused and mention CMake scope when relevant. Pull requests should describe the user-visible or tutorial-facing change, list tests run, and link related issues or articles. Include screenshots only for documentation or rendered-output changes.

## Agent-Specific Instructions

Do not rewrite vendored files or generated `.inc` outputs directly. When adding MLIR functionality, update the relevant `CMakeLists.txt` files so dialects, passes, conversions, generated headers, and tests remain wired into the local build.
