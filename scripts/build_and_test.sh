#!/usr/bin/env bash
# Build cudass (cudss_bindings + sparse_to_dense) and run the full test suite.
#
# Prereqs: CUDA (module load cuda/... or CUDA_HOME), nvidia-cudss-cu12 (pip; same as README/setup),
# PyTorch with CUDA, Cython.
#
# Optional: MODULE_LOAD_CMD="module load cuda/12.2" . scripts/build_and_test.sh
# Optional: CUDA_VISIBLE_DEVICES=0,1 for test_solve_b_device_mismatch (2 GPUs); on single-GPU
#           hosts that test is skipped. If unset, the script sets CUDA_VISIBLE_DEVICES=0,1 for pytest.

set -e
cd "$(dirname "$0")/.."

if [[ -n "${MODULE_LOAD_CMD:-}" ]]; then
  eval "${MODULE_LOAD_CMD}"
fi

echo "=== pip install -e . (builds cudss_bindings + sparse_to_dense) ==="
pip install -e .

echo "=== pytest tests/ -v ==="
# Expose 2+ GPUs so test_solve_b_device_mismatch runs. Use 0,1 unless
# CUDA_VISIBLE_DEVICES already lists multiple (e.g. 2,3).
if [[ "${CUDA_VISIBLE_DEVICES:-}" != *,* ]]; then
  export CUDA_VISIBLE_DEVICES=0,1
fi
python -m pytest tests/ -v

echo "=== Verify built extensions ==="
python -c "
from cudass.cuda.kernels import sparse_to_dense
import torch
idx = torch.tensor([[0, 1], [0, 1]], device='cuda', dtype=torch.int64)
val = torch.tensor([1.0, 2.0], device='cuda', dtype=torch.float64)
out = sparse_to_dense(idx, val, 2, 2)
assert out[0, 0] == 1.0 and out[1, 1] == 2.0, out
print('sparse_to_dense: OK')
"
python -c "
import cudass.cuda.bindings.cudss_bindings as cudss
h = cudss.create_handle()
cudss.destroy_handle(h)
print('cudss_bindings: OK')
" 2>/dev/null || echo "cudss_bindings: not built or cudss runtime unavailable (fallback to cusolver_dn)"
