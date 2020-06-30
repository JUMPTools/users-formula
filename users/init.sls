include:
{% if grains['kernel'] == 'Windows' %}
  - .windows
{% else %}
  - .linux
{% endif %}