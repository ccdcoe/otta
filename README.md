# otta
Automated query engine for aol/moloch. Parse statistical data for known good queries, and publish to influxdb.

## Query engine

Cobbled together in python. Only command line (and therefore crontab) usage is supported.

```
* *    * * *   root    /srv/otta/python//main.py -t 60 -r 1 -mh 1.2.3.4 -u admin -p admin -if 5.6.7.8
```

## Replay

Tool is written to run queries in a loop, with each loop corresponding to a time period. Backwards. Setting `-r` flag as 2 and `-t` as 60 would result in a batch of query for last minute and a another batch for the preceding minute. Aggregate data is written to InfluxDB after results for each batch is collected. Useful if you want to analyze historical PCAP data. For example, `-t 60 -r 60` would analyze last hour with the precision of 1 minute.

## Elasticsearch

Moloch queries can be stored as Elasticsearch documents, as opposed to a list of python dictionaries. Experimental and barely tested. Got it working once, disabled the feature via global variable and then rewrote most of my code.

## Alerting

Current idea is to alert the red team once they get too loud. Using kapacitor tick scripts and sigma function to generate an alert for noisy source IP-s, and to display the data on alerta. WIP.
