MASTER_IP={% for etcdmem in pillar.etcd.server.members %}http://{{ etcdmem.host}}:2379,{% endfor%}
