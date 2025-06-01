# Minkowski Engine Docker
A customizable Dockerfile that allows you to specify Ubuntu, CUDA, Python, and PyTorch versions for installing MinkowskiEngine

```
docker build -t minkowski .
docker run --gpus all \
  -it \
  minkowski bash
```
