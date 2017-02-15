# tf-mkl
Initial effort of compiling tensorflow with Intel MKL

```bash
docker build -t tf-mkl -f Dockerfile --build-arg PROXY_SERVER=... NO_PROXY=... .
docker run --rm -it tf-mkl bash
```
