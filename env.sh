source .venv/bin/activate

# mlir path
export LLVM_HOME=$(pwd)/externals/llvm-project/build
export PATH=$LLVM_HOME/bin:$PATH
export TUTORIAL_HOME=$(pwd)/build-ninja
export PATH=$LLVM_HOME/bin:$TUTORIAL_HOME/tools:$PATH
export LD_LIBRARY_PATH=$LLVM_HOME/lib:$LD_LIBRARY_PATH