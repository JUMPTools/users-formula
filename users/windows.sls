# vim: sts=2 ts=2 sw=2 et ai
  {% from "users/map.jinja" import users with context %}

  {% for group, setting in salt['pillar.get']('groups', {}).items() %}
  {%   if setting.absent is defined and setting.absent or setting.get('state', "present") == 'absent' %}
users_group_absent_{{ group }}:
  group.absent:
    - name: {{ group }}
  {% else %}
users_group_present_{{ group }}:
  group.present:
    - name: {{ group }}
    - gid: {{ setting.get('gid', "null") }}
    - system: {{ setting.get('system',"False") }}
    - members: {{ setting.get('members')|json }}
    - addusers: {{ setting.get('addusers')|json }}
    - delusers: {{ setting.get('delusers')|json }}
  {% endif %}
  {% endfor %}



  {% for name, user in pillar.get('users', {}).items()
        if user.absent is not defined or not user.absent %}
  {%- if user == None -%}
  {%- set user = {} -%}
  {%- endif -%}
  {%- set current = salt.user.info(name) -%}
  {%- set home = user.get('windows_home', current.get('windows_home', "c:/Users/%s" % name)) -%}
  {%- set createhome = user.get('createhome', users.get('createhome')) -%}

  {%- if 'prime_group' in user and 'name' in user['prime_group'] %}
  {%- set user_group = user.prime_group.name -%}
  {%- else %}
  {%- set user_group = None %}
  {%- endif %}

  {% for group in user.get('windows_groups', []) %}
users_{{ name }}_{{ group }}_group:
  group.present:
    - name: {{ group }}
    {% if group == 'sudo' %}
    - system: True
  {% endif %}
  {% endfor %}

  {# in case home subfolder doesn't exist, create it before the user exists #}
users_{{ name }}_user:
  user.present:
    - name: {{ name }}
    - home: {{ home }}
    {% if 'uid' in user -%}
    - uid: {{ user['uid'] }}
    {% endif -%}
    {% if 'windows_password' in user -%}
    - password: '{{ user['windows_password'] }}'
    {% endif -%}
    {% if 'enforce_password' in user -%}
    - enforce_password: {{ user['enforce_password'] }}
    {% endif -%}
    {% if 'hash_password' in user -%}
    - hash_password: {{ user['hash_password'] }}
    {% endif -%}
    {% if user.get('system', False) -%}
    - system: True
    {% endif -%}
    {% if 'fullname' in user %}
    - fullname: {{ user['fullname'] }}
    {% endif -%}
    {% if 'roomnumber' in user %}
    - roomnumber: {{ user['roomnumber'] }}
    {% endif %}
    {% if 'workphone' in user %}
    - workphone: {{ user['workphone'] }}
    {% endif %}
    {% if 'homephone' in user %}
    - homephone: {{ user['homephone'] }}
    {% endif %}
    - createhome: {{ createhome }}
    {% if not user.get('unique', True) %}
    - unique: False
    {% endif %}
    {% if 'expire' in user -%}
    - expire: {{ user['expire'] }}
    {% endif -%}
    {% if 'mindays' in user %}
    - mindays: {{ user.get('mindays', None) }}
    {% endif %}
    {% if 'maxdays' in user %}
    - maxdays: {{ user.get('maxdays', None) }}
    {% endif %}
    {% if 'inactdays' in user %}
    - inactdays: {{ user.get('inactdays', None) }}
    {% endif %}
    {% if 'warndays' in user %}
    - warndays: {{ user.get('warndays', None) }}
    {% endif %}
    - remove_groups: {{ user.get('remove_groups', 'False') }}
    {% if user.get('windows_groups', None) %}
    - groups:
        {% for group in user.get('windows_groups', []) -%}
        - {{ group }}
          {% endfor %}
          {% endif %}
    {% if 'optional_groups' in user %}
    - optional_groups:
        {% for optional_group in user['optional_groups'] -%}
        - {{ optional_group }}
          {% endfor %}
          {% endif %}
    {% if user.get('windows_groups', None) %}
    - require:
        {% for group in user.get('windows_groups', []) -%}
        - group: {{ group }}
    {% endfor %}
  {% endif %}


## FORCE RESET PASSWORD
  {% if 'windows_password' in user %}
users_{{ name }}_password:
  module.run:
    - name: user.setpassword
    - m_name: {{ name }}
    - password: '{{ user['windows_password'] }}'

## Disable ResetPassword @ next logon and password expiration
users_{{ name }}_user_settings:
  module.run:
    - name: user.update
    - expiration_date: 'Never'
    - expired: false
    - password_never_expires: true
    - account_disabled: false
    - unlock_account: true
    - m_name: {{ name }}
  {% endif -%}

  {% endfor %}

  {% for name, user in pillar.get('users', {}).items()
        if user.absent is defined and user.absent %}
users_absent_user_{{ name }}:
  {% if 'purge' in user or 'force' in user %}
  user.absent:
    - name: {{ name }}
    {% if 'purge' in user %}
    - purge: {{ user['purge'] }}
    {% endif %}
    {% if 'force' in user %}
    - force: {{ user['force'] }}
  {% endif %}
  {% else %}
  user.absent:
    - name: {{ name }}
  {% endif -%}
users_{{ users.sudoers_dir }}/{{ name }}:
  file.absent:
    - name: {{ users.sudoers_dir }}/{{ name }}
  {% endfor %}

  {% for user in pillar.get('absent_users', []) %}
users_absent_user_2_{{ user }}:
  user.absent:
    - name: {{ user }}
users_2_{{ users.sudoers_dir }}/{{ user }}:
  file.absent:
    - name: {{ users.sudoers_dir }}/{{ user }}
  {% endfor %}

  {% for group in pillar.get('absent_groups', []) %}
users_absent_group_{{ group }}:
  group.absent:
    - name: {{ group }}
  {% endfor %}