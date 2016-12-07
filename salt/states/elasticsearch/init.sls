include:
  - java

es_repo:
  pkgrepo.managed:
    - humanname: Elasticsearch repository
    - name: deb http://packages.elastic.co/elasticsearch/2.x/debian stable main
    - key_url: https://packages.elastic.co/GPG-KEY-elasticsearch 
    - file: /etc/apt/sources.list.d/elasticsearch.list
    - clean_file: True

elasticsearch:
  pkg.installed:
    - require:
      - pkgrepo: es_repo
  service.running:
    - name: elasticsearch
    - enable: True
    - watch:
      - file: /etc/elasticsearch/elasticsearch.yml
      - file: /etc/default/elasticsearch

/etc/default/elasticsearch:
  file.managed:
    - mode: 644
    - source: salt://elasticsearch/default.jinja
    - template: jinja

/etc/elasticsearch/elasticsearch.yml:
  file.managed:
    - mode: 644
    - source: salt://elasticsearch/elasticsearch.jinja
    - template: jinja

{% if 'gw-es' in grains['host'] %}
elasticsearch-head-install:
  cmd.run:
    - name: '/usr/share/elasticsearch/bin/plugin install mobz/elasticsearch-head'
    - unless: '/usr/share/elasticsearch/bin/plugin list | grep head'
{% endif %}
