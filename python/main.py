#!/usr/bin/env python
# coding: utf-8

import json, time
from requests.auth import HTTPDigestAuth
import requests, urllib
import argparse
from elasticsearch import Elasticsearch

from database import *

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', '--timewindow', default=60, type=int)
    parser.add_argument('-r', '--repeat', default=1, type=int)
    parser.add_argument('-mh', '--moloch', default='localhost')
    parser.add_argument('-u', '--user', default='admin')
    parser.add_argument('-p', '--password', default='admin')
    parser.add_argument('-es','--elasticsearch', nargs='+', required=False, default=['localhost'])
    parser.add_argument('-if', '--influx', default='localhost')
    return parser.parse_args()

ARGS = parse_arguments()

WINDOW=ARGS.timewindow
REPEAT=ARGS.repeat

HOST=ARGS.moloch
PORT=8005
SSL=False
USER=ARGS.user
PASS=ARGS.password

INFLUX_SERVER=ARGS.influx
MEASUREMENT = 'moloch_spi_queries'

USE_ES=False
ES_HOSTS=ARGS.elasticsearch
ES_INDEX='moloch_queries'
ES_TYPE='expression'

# a1 = src_ip
FIELD_MAP = {
    'a1': 'src_ip',
    'p1': 'src_port'
}

QUERIES = [
    {
        'expression': 'protocols != syslog && vlan != 3611 && protocols == http && (http.user-agent == www.owasp.org || http.user-agent == sqlmap || http.user-agent == dirbust || http.user-agent == libwww)',
        'query_tag': 'http_scanner_default_ua',
        'aggregate_field': 'a1'
    },
    {
        'expression': 'protocols != syslog && vlan != 3611 && protocols = http && http.user-agent != mozilla && http.user-agent != "BreakingPoint/1.x (http://bpointsys.com/)" && (http.user-agent == python || http.user-agent == CPython)',
        'query_tag': 'http_python_ua',
        'aggregate_field': 'a1'
    },
    {
        'expression': '(port.dst == 80 || port.dst == 443 || port.dst == 8080 || port.dst == 9200 || port.dst == 8086) && protocols != http && vlan != 3611 && vlan != 3604 && (port.dst != 443 && protocols != tls) && tags != "acked-unseen-segment-dst" && tags != "out-of-order-src"',
        'query_tag': 'http_port_not_http',
        'aggregate_field': 'a1'
    },
    {
        'expression': '(port.dst != 80 && port.dst != 443 && port.dst != 8080 && port.dst != 9200 && port.dst != 8086) && protocols == http && vlan != 3611',
        'query_tag': 'http_non_std_port',
        'aggregate_field': 'a1'
    },
    {
        'expression': 'protocols != syslog && vlan != 3611 && protocols == http && port.dst == 8291',
        'query_tag': 'connection_to_known_beef_server',
        'aggregate_field': 'a1'
    },
    {
        'expression': 'port.dst == 25 && protocols != smtp && vlan != 3611 && vlan != 3611',
        'query_tag': 'not_smtp_std_port',
        'aggregate_field': 'a1'
    },
    {
        'expression': 'protocols == smtp && (port != 25 || port != 587) && vlan != 3611',
        'query_tag': 'smtp_non_std_port',
        'aggregate_field': 'a1'
    },
    {
        'expression': 'port.dst == 22 && protocols != ssh && vlan != 3611',
        'query_tag': 'not_smtp_std_port',
        'aggregate_field': 'a1'
    },
    {
        'expression': 'protocols == ssh && port != 22 && vlan != 3611)',
        'query_tag': 'smtp_non_std_port',
        'aggregate_field': 'a1'
    },
]

def getPeriod(interval=60):
    now = int(time.time())
    then = int(now - interval)
    return then, now

def getQueries():
    queries = []
    es = Elasticsearch(hosts=ES_HOSTS)
    results = es.search(index=ES_INDEX, q='*')
    doc = es.get(index=ES_INDEX, doc_type=ES_TYPE, id=1)['_source']
    for key, value in results['hits'].items():
        if key == 'hits':
            for expr in value:
                queries.append(expr['_source'])
    return queries

def flushInflux(bulk):
    if bulk and isinstance(bulk, list):
        timestamp = bulk[0]['time']
        try:
            db = influxData(host=INFLUX_SERVER)
            client = db.returnClient()
            client.write_points(
                bulk,
                time_precision='s'
                )
            print "sent %s items to influxdb on %s with timestamp %s" % (
                str(len(bulk)),
                db.getHOST(),
                timestamp
                )
        except Exception as e:
            print "FAIL: %s" % (e)
    else:
        print "No items to send"

def queryMoloch(url, startTime, stopTime, query):
    result = []
    field = query['aggregate_field']
    fields = {
        'startTime': int(startTime),
        'stopTime': int(stopTime),
        'expression': query['expression'],
        'field': field,
        'counts': 1
    }
    spi_request = "%s?%s" % (url, urllib.urlencode(fields))
    spi_ret = requests.get(spi_request, auth=HTTPDigestAuth(USER, PASS)).text
    json = {}
    for line in spi_ret.splitlines():
        data = line.split(',')
        json = {
            "time": int(stopTime),
            "measurement": MEASUREMENT,
            "tags": {
                FIELD_MAP[field]: data[0],
                "query": query['query_tag']
            },
            "fields": {
                "count": int(data[1].strip())
            }
        }
        result.append(json)
    return result

def main():

    url = 'http://%s:%s/unique.txt' % (HOST, PORT)

    if USE_ES:
        queries = getQueries()
    else:
        queries = QUERIES

    startTime = time.time()
    for step in range(REPEAT):
        startTime -= WINDOW
        stopTime = startTime
        bulk = []
        for query in queries:
            bulk.extend(queryMoloch(url=url, startTime=startTime, stopTime=stopTime, query=query))
        flushInflux(bulk)

if __name__ == "__main__":
    main()
