#!/bin/sh

usage() {
  echo "Usage: deploy_vm.sh <domain_name> [-r ram_size]"
  exit 0
}

if [ $# -eq 0 ]; then
  usage
fi

HOST_NAME=$1
RAM_SIZE=2048
CPU_NUM=2

if [ $# -eq 3 ]; then
  case "$2" in
    -r)
      RAM_SIZE=$3
      ;;
    *)
      usage
      ;;
  esac
fi

MAC_RAND1=`perl -e 'for ($i=0;$i<5;$i++){@m[$i]=int(rand(256));} printf "02:%X:%X:%X:%X:01\n",@m;'`
MAC_RAND2=`perl -e 'for ($i=0;$i<5;$i++){@m[$i]=int(rand(256));} printf "02:%X:%X:%X:%X:02\n",@m;'`

sudo virt-install --connect qemu:///system -n ${HOST_NAME} -r ${RAM_SIZE} \
        --arch=x86_64 --pxe \
        --vcpus=${CPU_NUM} \
        --network=network:management,mac=${MAC_RAND1} \
        --network=network:data,mac=${MAC_RAND2} \
        --boot network \
        --vnc --accelerate \
        --disk=/var/lib/libvirt/images/${HOST_NAME}.img,size=8 \
        --serial pty --console pty --noautoconsole

exit 0
