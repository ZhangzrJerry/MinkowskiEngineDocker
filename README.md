# Minkowski Engine Docker
A customizable Dockerfile that specify `Ubuntu 20.04`, `CUDA 11.3`, `Python 3.8`, and `PyTorch 1.12.0` for installing [Minkowski Engine](https://github.com/NVIDIA/MinkowskiEngine)

```
docker build -t minkowski .
docker run --gpus all \
  -it \
  minkowski bash
```
