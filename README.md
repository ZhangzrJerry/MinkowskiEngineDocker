# Minkowski Engine Docker
A customizable Dockerfile that allows you to specify Ubuntu, CUDA, Python, and PyTorch versions for installing [Minkowski Engine](https://github.com/NVIDIA/MinkowskiEngine)

```
docker build -t minkowski \
  --build-arg UBUNTU_VERSION=20.04 \          # Options: 18.04, 20.04
  --build-arg CUDA_VERSION=11.3.1 \           # Options: 11.3.1, 11.6.2, 10.2
  --build-arg CUDNN_VERSION=8 \               # Typically 7 or 8
  --build-arg PYTORCH_CUDA=cu113 \            # Must match CUDA_VERSION (e.g., cu113, cu102)
  .

docker run --gpus all \
  -it \
  minkowski bash
```

### Notes:

After test, running Minkowski Engine on `RTX 4060` with `CUDA 11.3.1` caused runtime error.
Try `--cpu_only` instead of `--force_cuda` in such a case.
