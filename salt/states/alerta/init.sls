{% set manage_service = False %}
{% set server_config = '/etc/alertad.conf' %}

include:
  - mongodb

alerta_build_pkgs:
  pkg.installed:
    - pkgs:
      - python-dev
      - python-pip
      - bcrypt
      - python-bcrypt
      - libffi-dev

{% for package in ['bcrypt', 'click', 'Werkzeug', 'itsdangerous'] %}
{{package}}:
  pip.installed
{% endfor %}

alerta-server:
  pip.installed:
    - require:
      - alerta_build_pkgs

{{server_config}}:
  file.managed:
    - source: salt://alerta/server.jinja
    - template: jinja
    - mode: 0644

{% if grains['init'] == 'upstart' %}
/etc/init/alertad.conf:
  file.managed:
    - source: salt://alerta/upstart/alertad.jinja
    - mode: 644
    - template: jinja
alerta_server_add_init:
  cmd.run:
    - name: initctl reload-configuration
    - unless: initctl list | grep alertad
{% set manage_service = True %}
{% elif grains['init'] == 'systemd' %}
/etc/systemd/system/alertad.service:
  file.managed:
    - source: salt://moloch/systemd/alertad.jinja
    - mode: 644
    - template: jinja
alerta_server_add_init:
  cmd.run:
    - name: systemctl daemon-reload
    - unless: systemctl list-units | grep alertad
{% set manage_service = True %}
{% endif %}

{% if manage_service == True %}
alertad:
  service.running:
    - enable: True
    - watch:
      - {{server_config}}
{% endif %}

nginx:
  pkg.installed:
    - name: nginx
  service.running:
    - enable: True
    - watch: 
      - file: /etc/nginx/sites-enabled/*
      - file: /etc/nginx/sites-available/*
      - pkg: nginx

/etc/nginx/sites-enabled/default:
  file.absent

alerta_webui:
  git.latest:
    - name: https://github.com/alerta/angular-alerta-webui
    - target: /srv/www/{{grains['fqdn']}}
    - require:
      - pkg: basic.packages

/srv/www/{{grains['fqdn']}}/app/config.js:
  file.managed:
    - source: salt://alerta/nginx/config.js
    - mode: 640
    - user: www-data

/etc/nginx/sites-available/{{grains['fqdn']}}:
  file.managed:
    - source: salt://alerta/nginx/site.jinja
    - template: jinja
    - mode: 644

/etc/nginx/sites-enabled/{{grains['fqdn']}}:
  file.symlink:
    - target: /etc/nginx/sites-available/{{grains['fqdn']}}
