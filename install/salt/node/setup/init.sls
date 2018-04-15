{% set path = pillar['rbd-path'] %}
env-script:
  file.managed:
    - source: salt://node/install/scripts/node.sh
    - name: {{ path }}/etc/envs/node.sh
    - makedirs: Ture
    - template: jinja
    - mode: 755
    - user: root
    - group: root
  
node-script:
  file.managed:
    - source: salt://node/install/scripts/start.sh
    - name: {{ path }}/node/scripts/start.sh
    - makedirs: Ture
    - template: jinja
    - mode: 755
    - user: root
    - group: root

node-config-mapper.yaml:
  file.managed:
    - source: salt://node/install/config/mapper.yaml
    - name: {{ path }}/node/config/mapper.yml
    - makedirs: Ture
    - template: jinja

/etc/systemd/system/node.service:
  file.managed:
    - source: salt://node/install/systemd/node.service
    - template: jinja
    - user: root
    - group: root

node-uuid-conf:
  file.managed:
    - source: salt://node/install/envs/node_host_uuid.conf
    - name: {{ path }}/etc/node/node_host_uuid.conf
    - makedirs: Ture
    - template: jinja

node:
  service.running:
    - enable: True
    - watch:
      - file: node-script
      - file: node-uuid-conf
  cmd.run:
    - name: systemctl restart node
