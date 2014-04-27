#!/bin/bash

chkconfig salt-minion off
chkconfig salt-master off
service salt-master stop
service salt-minion stop
rm -rf /etc/salt/minion_id /etc/salt/minion.d /etc/salt/pki
yum install -y python-pip
pip install cherrypy
pip install -U halite
useradd -M -N -l admin
echo "admin" | passwd admin --stdin

cat <<EOF >> /etc/salt/master
# halite configuration
external_auth:
  pam:
    admin:
      - .*
      - '@runner'
      - '@wheel'

halite:
  level: 'debug'
  server: 'cherrypy'
  host: '0.0.0.0'
  port: '8080'
  cors: False
  tls: False

EOF

cat <<EOF >> /usr/bin/salt-auto_accept_true
#!/bin/bash
sed -i.bak "s/#*auto_accept:.*/auto_accept: True/g" /etc/salt/master
echo "You need to restart salt-master to make effective the change"
EOF
chmod +x /usr/bin/salt-auto_accept_true

cat <<EOF >> /usr/bin/salt-auto_accept_false
#!/bin/bash
sed -i.bak "s/#*auto_accept:.*/#auto_accept: False/g" /etc/salt/master
echo "You need to restart salt-master to make effective the change"
EOF
chmod +x /usr/bin/salt-auto_accept_false

