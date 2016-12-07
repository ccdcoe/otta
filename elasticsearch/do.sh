#!/bin/bash

IP=localhost

curl -XPOST $IP:9200/moloch_queries -d '{
    "settings" : {
        "number_of_shards" : 1,
        "number_of_replicas" : 3
    }
}'

curl -XPUT $IP:9200/moloch_queries -d '{
  "template" : "moloch_queries*",
  "settings" : {
    "index.refresh_interval" : "60s",
    "index.number_of_shards" : "1",
    "index.number_of_replicas" : "3"
  },
  "mappings" : {
    "_default_" : {
      "_all" : {"enabled" : false, "omit_norms" : true},
      "dynamic_templates" : [ {
        "message_field" : {
          "match" : "message",
          "match_mapping_type" : "string",
          "mapping" : {
            "type" : "string", "index" : "analyzed", "omit_norms" : true,
            "fielddata" : { "format" : "disabled" }
          }
        }
      }, {
        "string_fields" : {
          "match" : "*",
          "match_mapping_type" : "string",
          "mapping" : {
            "type" : "string", "index" : "analyzed", "omit_norms" : true,
            "fielddata" : { "format" : "disabled" },
            "fields" : {
              "raw" : {"type": "string", "index" : "not_analyzed", "ignore_above" : 256}
            }
          }
        }
      } ],
      "properties" : {
        "@timestamp": { "type": "date" },
        "@version": { "type": "string", "index": "not_analyzed" },
        "geoip"  : {
          "dynamic": true,
          "properties" : {
            "ip": { "type": "ip" },
            "location" : { "type" : "geo_point" },
            "latitude" : { "type" : "float" },
            "longitude" : { "type" : "float" }
          }
        }
      }
    }
  }
}'

curl -XPOST $IP:9200/moloch_queries/expression/1 -d  '{
  "expression": "port.dst+%3D%3D+80+%26%26+protocols+!%3D+http",
  "query_tag": "moloch_port_80_not_http"
}'

curl -XPOST $IP:9200/moloch_queries/expression/2 -d  '{
  "expression": "port.dst+%3D%3D+25+%26%26+protocols+3D+smtp",
  "query_tag": "moloch_port_25_not_smtp"
}'

curl -XPOST $IP:9200/moloch_queries/expression/3 -d  '{
  "expression": "port.dst+%3D%3D+443+%26%26+protocols+3D+http",
  "query_tag": "moloch_port_443_not_http"
}'

curl -XPOST $IP:9200/moloch_queries/expression/4 -d  '{
  "expression": "protocols+3D+syslog+%26%26+vlan+3D+3611+%26%26+http.user-agent+3D+mozilla+%26%26+(http.user-agent+%3D%3D+www.owasp.org+||+http.user-agent+%3D%3D+sqlmap+||+http.user-agent+%3D%3D+CPython)",
  "query_tag": "http_scanner_default_ua"
}'
