# tf-mkl
Initial effort of compiling tensorflow with Intel MKL

```bash
docker build -t tf-mkl -f Dockerfile --build-arg PROXY_SERVER=... --build-arg NO_PROXY=... .
docker run --rm -it tf-mkl bash
```


For benchmarking:

```bash
cd /
git clone https://github.com/tensorflow/models.git
cd models/tutorials/image/mnist
python convolutional.py
```