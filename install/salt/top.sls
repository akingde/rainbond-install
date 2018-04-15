base:
  "*":
    - init
    - docker
    - misc
    - etcd
    - storage
    - network
    - kubernetes.node
    - node
    - db
    - grbase
    - plugins
    - proxy
    - prometheus
    - expand

  "role:manage":
    - match: grains
    - kubernetes.server
