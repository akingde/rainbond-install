#!/bin/bash

{% if "manage" in grains['id'] %}
eval $(ssh-agent) > /dev/null
eval $(ssh-add) > /dev/null
NODE_OPTS="--log-level=debug --kube-conf={{ pillar['rbd-path'] }}/etc/kubernetes/kubecfg/admin.kubeconfig  --statsd.mapping-config={{ pillar['rbd-path'] }}/etc/rbd-node/mapper.yml --nodeid-file={{ pillar['rbd-path'] }}/etc/rbd-node/node_host_uuid.conf --static-task-path={{ pillar['rbd-path'] }}/etc/rbd-node/tasks/ --etcd=http://127.0.0.1:2379   --hostIP={{ grains['fqdn_ip4'][0] }} --run-mode master --noderule manage,compute"
{% else %}
NODE_OPTS="--log-level=debug --kube-conf={{ pillar['rbd-path'] }}/etc/kubernetes/kubecfg/admin.kubeconfig --statsd.mapping-config={{ pillar['rbd-path'] }}/etc/rbd-node/mapper.yml --nodeid-file={{ pillar['rbd-path'] }}/etc/rbd-node/node_host_uuid.conf --static-task-path={{ pillar['rbd-path'] }}/etc/rbd-node/tasks/ --etcd=http://127.0.0.1:2379  --hostIP={{ grains['fqdn_ip4'][0] }}"
{% endif %}
exec /usr/local/bin/node $NODE_OPTS