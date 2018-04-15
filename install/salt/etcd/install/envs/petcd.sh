MASTER_IP=http://{% for etcdmem in pillar.etcd.server.members %}{{ etcdmem.host}}:2379{% endfor%}
