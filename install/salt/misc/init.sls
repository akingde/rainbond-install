include:
{% if "manage" in grains['host'] %}
  - misc.onenode
{% endif %}
  - misc.prepare