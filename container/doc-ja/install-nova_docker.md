nova-docker インストール方法
============================

ここでは、nova-docker のインストール手順について解説します。
ホスト構成としては、control-node:1台 及び compute-node:1台の
2台構成を想定します。ネットワーク構成については nova-network
を用います。

インストールの流れは以下のとおりです。

1. nova-docker のインストール
2. devstack のインストール
3. devstack のdeploy

nova-docker のインストール
==========================

https://github.com/stackforge/nova-docker/tree/master/contrib/devstack
を参考にして、下記の手順で OpenStack をインストールします。

```console
(nova-compute)
sudo ip addr add 10.4.128.1/20 dev p9p1:0
sudo iptables -t nat -A POSTROUTING -s 10.4.128.0/20 -j MASQUERADE

(nova-controller)
sudo ip addr add 10.4.128.2/20 dev p9p1:0
```

```console
(nova-compute node SSHでログインするための秘密鍵を登録する)
cp (path to ssh key) .ssh/id_rsa
chmod 600 .ssh/id_rsa
```

```console
sudo apt-get install -y git
sudo mkdir /opt/stack
sudo chown ubuntu /opt/stack

git clone https://git.openstack.org/stackforge/nova-docker /opt/stack/nova-docker
git clone https://git.openstack.org/openstack-dev/devstack /opt/stack/devstack

git clone https://git.openstack.org/openstack/nova /opt/stack/nova

cd /opt/stack/nova-docker
./contrib/devstack/prepare_devstack.sh
```

```console
cd /opt/stack/devstack

vi localrc
```

(control-node localrc)
```bash:localrc
export VIRT_DRIVER=docker
export DEFAULT_IMAGE_NAME=cirros
export NON_STANDARD_REQS=1
export IMAGE_URLS=" "

###IP Configuration
HOST_IP=<< IP_ADDRESS >>
#Credentials
ADMIN_PASSWORD=password
DATABASE_PASSWORD=password
RABBIT_PASSWORD=password
SERVICE_PASSWORD=password
SERVICE_TOKEN=password
#MULTINODE CONFIGURATION
FLAT_INTERFACE=<< i/f name >>
FIXED_RANGE=10.4.128.0/20
FIXED_NETWORK_SIZE=4096
FLOATING_RANGE=<< FLOATING_IP_RANGE >>
MULTI_HOST=1
####Tempest
#enable_service tempest
#Log Output
LOGFILE=/opt/stack/logs/stack.sh.log
VERBOSE=True
LOG_COLOR=False
SCREEN_LOGDIR=/opt/stack/logs
```

(compute-node localrc)
```bash:localrc
export VIRT_DRIVER=docker
export DEFAULT_IMAGE_NAME=cirros
export NON_STANDARD_REQS=1
export IMAGE_URLS=" "

###IP Configuration
HOST_IP=<< HOST_IP >>
#Credentials
ADMIN_PASSWORD=password
DATABASE_PASSWORD=password
RABBIT_PASSWORD=password
SERVICE_PASSWORD=password
SERVICE_TOKEN=password
#MULTINODE CONFIGURATION
FLAT_INTERFACE=<< i/f name >>
FIXED_RANGE=10.4.128.0/20
FIXED_NETWORK_SIZE=4096
FLOATING_RANGE=10.174.247.64/28
MULTI_HOST=1

SERVICE_HOST=<< CONTROL_IP >>
MYSQL_HOST=<< CONTROL_IP >>
RABBIT_HOST=<< CONTROL_IP >>
GLANCE_HOSTPORT=<< CONTROL_IP >>:9292
ENABLED_SERVICES=n-cpu,n-net,n-api,n-vol

#Log Output
LOGFILE=/opt/stack/logs/stack.sh.log
VERBOSE=True
LOG_COLOR=False
SCREEN_LOGDIR=/opt/stack/logs
```

最後に、devstack の deploy script (stack.sh) を各ホストについて
実行します。

```console
sudo vi /etc/apt/apt.conf
(MAASを用いて OSをdeployした場合は、proxy設定をコメントすることで
dockerパッケージのダウンロードを出来るようにしておく)

cd /opt/stack/devstack
sudo apt-get install -y python-pip
sudo pip install docker-py
./stack.sh
```

control-node 上で nova-compute を動かさないようにするには、
下記コマンドを controller-node上で実行します。

```console
nova-manage service disable --host=(host of controller) --service=nova-compute
```

instance 起動テスト
==================
OpenStack の deploy が完了したら、テスト用の image (cirros)
を起動します。

```console
nova keypair-add mykey > ~/mykey.pem
nova boot --flavor m1.small --image cirros --key-name mykey test01
```

Ubuntu14.04 起動テスト
=====================

```console
docker pull ubuntu-upstart
docker images
source openrc admin
docker save ubuntu-upstart | glance image-create --is-public=True --container-format=docker --disk-format=raw --name=ubuntu-upstart
source openrc demo
nova boot --flavor m1.small --image ubuntu-upstart --key-name mykey test02

ssh root@(ip of instance)
password: docker.io

```

Appendix
========

nova ubuntu14.04 upload

```console
wget http://cloud-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img
glance image-create --name "ubuntu" --disk-format=qcow2 --container-format=bare --is-public=True < ubuntu-14.04-server-cloudimg-amd64-disk1.img
```

```console
source openrc admin
nova flavor-create --is-public true t1.32 auto 2048 20 32
nova flavor-create --is-public true t1.16 auto 2048 20 16
nova flavor-create --is-public true t1.8 auto 2048 20 8
nova flavor-create --is-public true t1.4 auto 2048 20 4
nova flavor-create --is-public true t1.2 auto 2048 20 2
nova flavor-create --is-public true t1.1 auto 2048 20 1

keystone tenant-list: tenant_id
nova quota-show --tenant (tenant_id)
nova quota-update --cores 64 (tenant_id)

source openrc demo

ex)
nova boot --flavor t1.32 --image ubuntu --key-name mykey test01
```
