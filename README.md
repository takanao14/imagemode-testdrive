# Image Mode hand's on

Image Modeをmacos上で試すためのサンプル

ImageModeでは、ブートしたのちに、bootcコマンドでコンテナレジストリからブートOSを含んだイメージをプルして起動できるところが面白いと思うので、試すためには、
- コンテナレジストリ
- podman
が必要となる。

また、Bootable Imageを試したいので、
- VirtualBox
もインストールしておく

このドキュメントでは、コンテナレジストリはcontainer(apple)を使い、ローカル環境で試す構成としている

## 事前準備

### Install container

```bash
# containerのインストール
brew install container
# container有効化
container system start
container system status
```

### Install Podman
```bash
brew install --cask podman-desktop
brew install podman
```

### Install Virtualbox
```bash
brew istall -cask virtualbox
```

## レジストリ起動
ここでは、distribution( https://distribution.github.io/distribution/ )を使ってコンテナレジストリを作る
```bash
bash start-registry.sh
```

## コンテナビルド
イメージモードでブートしたイメージの切り替えをしたいので、ImageModeのコンテナを2個作る

```bash
# ローカルのdisributionをコンテナレジストリとする
REGISTRY_IPADDR=$(container inspect registry | jq -jr '.[].networks[].address | split("/")[0]')
FEDORA40=$REGISTRY_IPADDR:5000/imagemode:40
FEDORA42=$REGISTRY_IPADDR:5000/imagemode:42

# build fedora40
podman build -f container/Dockerfile.40 -t $FEDORA40
podman push $FEDORA40

# build fedora42
podman build -f container/Dockerfile.42 -t $FEDORA42
podman push $FEDORA42
```

## Image Mode CD作成
```bash
rm -rf output
mkdir -p output
sudo podman run \
    --rm \
    -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v $(pwd)/imagemode-conf/config.json:/config.json \
    -v $(pwd)/output:/output \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type anaconda-iso \
    --rootfs xfs \
    --log-level info \
    $FEDORA40
```

# CD imageからブートする
./output/bootiso/install.iso でブートをすると、最初に見つかったストレージにImageModeの内容がインストールされる

## boot後の確認




## 参考containerコマンドの使い方

```bash
# help
container help
container run -d --rm --name nginx mirror.gcr.io/nginx
container ls
ifconfig -l
ifconfig bridge100
```

コンテナはそれぞれ異なるIPアドレスを持ち、リソースも個別に制御できる

```bash
container run -d --rm --name alpine1 --cpu 2 --memory 1024m mirror.gcr.io/alpine
container run -d --rm --name alpine2 --cpu 4 --memory 2048m mirror.gcr.io/alpine
container ls
```
