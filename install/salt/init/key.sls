{% set path = pillar['rbd-path'] %}

{% if grains['id']  == 'manage01' %}
key_build:
  cmd.run:
    - name: ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
    - unless: test -f ~/.ssh/id_rsa.pub

key_rsa:
  cmd.run:
    - name: cp -a ~/.ssh/id_rsa /srv/salt/init/files
    - unless: test -f /srv/salt/init/files/id_rsa
    - require:
      - cmd: key_build

key_pub:
  cmd.run:
    - name: cp -a ~/.ssh/id_rsa.pub /srv/salt/init/files
    - unless: test -f /srv/salt/init/files/id_rsa.pub
    - require:
      - cmd: key_build

{% else %}

key_cp:
  file.managed:
    - source: salt://init/files/id_rsa.pub
    - name: /tmp/id_rsa.pub
    - user: root
    - group: root
    - mode: 600
    - makedirs: Ture
    - unless: test -f /tmp/id_rsa.pub
  cmd.run:
    - name: cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys
{% endif %}

{% if "manage" in grains['id']%}
key_rsa_ssh:
  file.managed:
    - source: salt://init/files/id_rsa
    - name: {{ path }}/etc/rbd-chaos/ssh/id_rsa
    - user: root
    - group: root
    - mode: 600
    - makedirs: Ture

key_rsa_buider:
  file.managed:
    - source: salt://init/files/id_rsa
    - name: {{ path }}/etc/rbd-chaos/ssh/builder_rsa
    - user: root
    - group: root
    - mode: 600
    - makedirs: Ture

key_pub_ssh:
  file.managed:
    - source: salt://init/files/id_rsa.pub
    - name: {{ path }}/etc/rbd-chaos/ssh/id_rsa.pub
    - user: root
    - group: root
    - mode: 600
    - makedirs: Ture

key_pub_builder:
  file.managed:
    - source: salt://init/files/id_rsa.pub
    - name: {{ path }}/etc/rbd-chaos/ssh/builder_rsa.pub
    - user: root
    - group: root
    - mode: 600
    - makedirs: Ture

key_config:
  file.managed:
    - source: salt://init/files/config
    - name: {{ path }}/etc/rbd-chaos/ssh/config
    - user: root
    - group: root
    - mode: 600
    - makedirs: Ture
{% endif %}
