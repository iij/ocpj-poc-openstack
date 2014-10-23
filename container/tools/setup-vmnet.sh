#!/bin/sh

PATH_NET1_XML=/tmp/virbr0.xml
PATH_NET2_XML=/tmp/virbr1.xml
NET1_NAME="management"
NET2_NAME="data"

cat <<EOF > ${PATH_NET1_XML}
<network>
  <name>${NET1_NAME}</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
  </ip>
</network>
EOF

cat <<EOF > ${PATH_NET2_XML}
<network>
<name>${NET2_NAME}</name>
<bridge name="virbr1" stp='on' delay='0'/>
</network>
EOF

virsh net-destroy default
virsh net-undefine default

virsh net-define ${PATH_NET1_XML}
virsh net-start ${NET1_NAME}
virsh net-autostart ${NET1_NAME}

virsh net-define ${PATH_NET2_XML}
virsh net-start ${NET2_NAME}
virsh net-autostart ${NET2_NAME}

exit 0
