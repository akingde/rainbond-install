kubelet-script:
  file.managed:
    - source: salt://kubernetes/node/install/scripts/start-kubelet.sh
    - name: {{ pillar['rbd-path'] }}/scripts/start-kubelet.sh
    - makedirs: Ture
    - template: jinja
    - mode: 755
    - user: root
    - group: root

kubelet-env:
  file.managed:
    - source: salt://kubernetes/node/install/envs/kubelet.sh
    - name: {{ pillar['rbd-path'] }}/envs/kubelet.sh
    - makedirs: Ture
    - template: jinja
    - mode: 755
    - user: root
    - group: root

k8s-custom-conf:
  file.managed:
    - source: salt://kubernetes/node/install/custom.conf
    - name: {{ pillar['rbd-path'] }}/etc/kubernetes/custom.conf
    - makedirs: Ture
    - template: jinja

kubelet-ssl-rsync:
  file.recurse:
    - source: salt://kubernetes/server/install/ssl
    - name: {{ pillar['rbd-path'] }}/etc/kubernetes/ssl

kubelet-cfg-rsync:
  file.recurse:
    - source: salt://kubernetes/server/install/kubecfg
    - name: {{ pillar['rbd-path'] }}/etc/kubernetes/kubecfg

kubelet-cni:
  file.recurse:
    - source: salt://kubernetes/node/install/cni
    - name: {{ pillar['rbd-path'] }}/etc/cni/
    - template: jinja
    - makedirs: Ture

kubelet-cni-bin:
  file.recurse:
    - source: salt://misc/file/cni/bin
    - name: {{ pillar['rbd-path'] }}/bin
    - file_mode: '0755'
    - user: root
    - group: root
    - makedirs: Ture

/etc/systemd/system/kubelet.service:
  file.managed:
    - source: salt://kubernetes/node/install/systemd/kubelet.service
    - template: jinja

/usr/local/bin/kubelet:
  file.managed:
    - source: salt://misc/file/bin/kubelet
    - mode: 755

{% if grains['id'] == 'manage01' %}

pull-pause-img:
  cmd.run:
    - name: docker pull rainbond/pause-amd64:3.0
    - unless: docker inspect rainbond/pause-amd64:3.0

rename-pause-img:
  cmd.run: 
    - name: docker tag rainbond/pause-amd64:3.0 goodrain.me/pause-amd64:3.0
    - unless: docker inspect goodrain.me/pause-amd64:3.0
    - require:
      - cmd: pull-pause-img
{% else %}
pull-pause-img:
  cmd.run:
    - name: docker pull goodrain.me/pause-amd64:3.0
    - unless: docker inspect goodrain.me/pause-amd64:3.0
{% endif %}

kubelet:
  service.running:
    - enable: True
    - watch:
      - file: kubelet-env
      - file: k8s-custom-conf
      - file: kubelet-cni
      - file: kubelet-ssl-rsync
      - file: kubelet-cfg-rsync
      - file: kubelet-script
{% if grains['id'] == 'manage01' %}
      - cmd: rename-pause-img
{% endif %}
    - require:
      - file: kubelet-env
      - file: k8s-custom-conf
      - file: kubelet-cni
      - file: kubelet-ssl-rsync
      - file: kubelet-cfg-rsync
      - cmd: pull-pause-img
{% if grains['id'] == 'manage01' %}
      - cmd: rename-pause-img
{% endif %}