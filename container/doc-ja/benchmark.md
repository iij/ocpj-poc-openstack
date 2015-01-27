benchmark
=========

ベンチマークの方針としては、下記についてそれぞれ比較します。

- nova-controller 1台 + nova-compute 1台構成
  - nova-docker
  - nova

使用する OpenStack は、2015年1月の開発者向けversionを用います。

benchmark内容
=============
比較方法としては、nova-docker及びnovaそれぞれについて CPUベンチマーク
、IOベンチマーク及びNETWORKベンチマークを実施します。

- 測定内容
  - CPU
  - IO
  - NETWORK
  - 消費電力

- 評価パラメタ
  - インスタンスの種別
    - nova
      - VCPU: 32, 16, 8, 4, (2), (1)
        - それぞれ、合計32スレッドになるようにインスタンスを起動する
        - ホストの搭載メモリが32GBのため、VCPU:2,1 の値は取得不可
      - MEM: 2GB固定
    - nova-docker
      - num of instances: 1, 2, ..., 32
        - cpu.shared=1024 全インスタンス同じ値にする

- 測定方法
  - CPU
    - sysbench
  - IO
    - fio
  - NETWORK
    - iperf
  - 消費電力
    - ipmitool

CPUベンチマーク(load)
=====================

```bash:bench-cpu.sh
#!/bin/sh

for i in 1 2 4 8 16 32; do
  sysbench --num-threads=$i --test=cpu --cpu-max-prime=100000 run
done

exit 0
```

IOベンチマーク(fio)
===================

```bash:bench-io.sh
#!/bin/sh

for i in 1 2 4 8 16 32; do

echo "-- num_jobs: $i --------------"

DSIZ=`expr 10000 / $i`

# Write
fio --directory=./ \
  --name fio_test_file --direct=1 --rw=randwrite --bs=16k --size=${DSIZ}M  \
  --numjobs=$i --time_based --runtime=180 --group_reporting --norandommap

# Read
fio --directory=./ \
  --name fio_test_file --direct=1 --rw=randread --bs=16k --size=${DSIZ}M  \
  --numjobs=$i --time_based --runtime=180 --group_reporting --norandommap 

# Cleanup
rm ./fio_test_file*

done

exit 0
```

IPMI測定
========

```bash:power-measure.sh
#!/bin/sh

while true; do
  date_start=`date +%s`
  date_str=`date +%T`
  power_str=`ipmitool -I lanplus -H (hostname) -U (username) -P (password) sdr | grep Power | awk '{print $5}'`
  printf "%s,%s\n" $date_str $power_str
  date_end=`date +%s`
  sleep `expr 10 - $date_end + $date_start`
done

netベンチマーク(iperf)
===================

```bash:bench-net.sh
#!/bin/sh

#
# Server: iperf -s -l 128k
#

for i in 1 2 4 8 16 32; do
  echo "Number of process: $i"
  iperf -c $1 -l 128k -i 1 -t 30
done

exit 0
```

exit 0
```
