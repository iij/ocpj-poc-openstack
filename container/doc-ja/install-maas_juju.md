MAAS Server インストール方法
============================

ここでは、MAAS Server のインストール手順について解説します。
インストールの流れは以下のとおりです。

1. MAAS server をVMにインストール
2. MAAS の設定
3. Juju Bootstrap node のインストール

MAAS server をVMにインストール
==============================

http://maas.ubuntu.com/docs/install.html を参考にして、下記の手順で
MAAS server をインストールします。

```bash:setup-maas.sh
#!/bin/sh

ADMIN_NAME="admin"
ADMIN_EMAIL="admin@example.jp"
ADMIN_PASSWORD="ubuntu"

sudo locale-gen ja_JP.UTF-8
sudo apt-get -y install maas libvirt-bin

sudo maas-region-admin createadmin --username=${ADMIN_NAME} --email=${ADMIN_EMAIL} --password=${ADMIN_PASSWORD}

# Setup CLI
APIKEY=`sudo maas-region-admin apikey --username admin`
maas login root http://127.0.0.1/MAAS/api/1.0 ${APIKEY}

# Import Boot images
maas root node-groups import-boot-images

exit 0
```

```console
$ sudo apt-get update
$ sudo apt-get dist-upgrade
$ ./setup-maas.sh

```

MAAS の設定
===========

MAAS server に web経由でアクセスします。

- http://(hostname)/MAAS
  - username: admin
  - password: ubuntu

Clusters -> Cluster master を選択し、PXEブートに用いるインタフェース(eth0)の設定を
編集します。

- Management
  - Manage DHCP and DNS
- router ip
  - 10.10.10.100
- ip range low
  - 10.10.10.110
- ip range high
  - 10.10.10.130

Settings -> Global Kernel Parameters を選択し、serial console の kernel parameter
を設定します。

- Global Kernel Parameters
  - console=ttyS4 mei.blacklist=yes mei_me.blacklist=yes

- User Preferences for Admin
  - Keys -> SSH keys
    - Add SSH key (maas server で作成した ssh public key を追加する)

- Upstream DNS
  - (上流のDNSサーバを指定)

MAASのDNSを利用するとdeployしたホスト名にFQDNでアクセスできるようになります。
maas server の resolv.conf に反映されるように /etc/network/interfacesの中に
'dns-nameservers 127.0.0.1' を追加しておきます。

次に、MAASの動作テストをします。

```console
$ ipmitool -I lanplus -U (username) -P (password) -H (hostname) power on
```

username, password, hostname はそれぞれ 各ホストのIPMI設定情報に差し替えます。
該当ノードでPXEブートが正しく行なわれると、MAASの初期起動イメージが動作して
MAAS server にノードが登録されます。

ノードが登録されたら、該当ノードの host name 及び IPMIパラメータを
設定します。続いて、Commision node をクリックして commision process
を走らせると、ノードの登録が完了します。

***

VM環境の構築
============
nova-computeノードを除いて、サーバの必要台数を減らすためにVM上にdeployする
環境を構築します。

はじめに、インタフェースを bridge に変更します。

```console
$ vi /etc/network/interfaces
```

```console
$ sudo apt-get install qemu-kvm libvirt-bin virtinst
$ exit ; login
  (再ログイン)
$ ./setup-vmnet.sh
```

***

Juju Bootstrap node のインストール
==================================

***
# Known Issues
## meiドライバの初期化に失敗してシステムが停止してしまうことがある
MAAS の commissionプロセス中で 1/3 程度の確率で発生する模様です。
不具合発生時は下記のような log がコンソールに出力されます。
kernel parameter に meiドライバのブラックリスト登録をしても
不具合は回避されませんでした。
今のところ、enlist/commission/startプロセスでのみ不具合が確認されて
います。ready状態になった後は不具合が発生しない模様です。

```console
[   42.489759] mei_me 0000:00:16.0: wait hw ready failed. status = -110
[   42.493422] mei_me 0000:00:16.0: hw_start failed ret = -110
[   42.494320] mei_me 0000:00:16.0: reset failed
[   42.495226] mei_me 0000:00:16.0: link layer initialization failed.
[   42.496220] mei_me 0000:00:16.0: init hw failure.
```

