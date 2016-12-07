{% set os = grains.get('os')|lower %}

influxdb:
  pkg.installed:
    - require:
      - pkgrepo: tick_repo
  service.running:
    - name: influxdb
    - enable: True
    - watch:
      - file: /etc/influxdb/influxdb.conf

/etc/influxdb/influxdb.conf:
  file.managed:
    - mode: 644
    - source: salt://influxdb/influxdb.jinja
    - template: jinja

create_telegraf_db:
  cmd.run:
    - name: influx -execute "CREATE DATABASE telegraf"
    - unless: influx -execute "SHOW DATABASES" | grep telegraf

grafana:
  pkgrepo.managed:
    - humanname: Grafana repository
    {% if grains['oscodename'] == 'trusty' %}
    - name: deb https://packagecloud.io/grafana/stable/debian/ wheezy main
    {% elif grains['oscodename'] == 'xenial' %}
    - name: deb https://packagecloud.io/grafana/stable/debian/ jessie main
    {% else %}
    - name: deb https://packagecloud.io/grafana/stable/{{ os }}/ {{ grains['oscodename']}} main
    {% endif %}
    - file: /etc/apt/sources.list.d/grafana.list
    - key_url: https://packagecloud.io/gpg.key
    - clean_file: true
  pkg.latest:
    - name: grafana
    - refresh: True
  service.running:
    - name: grafana-server
    - enable: True
    - watch:
      - file: /etc/grafana/grafana.ini

/etc/grafana/grafana.ini:
  file.managed:
    - mode: 644
    - source: salt://influxdb/grafana.jinja
    - template: jinja

