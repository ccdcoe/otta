#!/usr/bin/env python
# coding: utf-8

from influxdb import InfluxDBClient

class influxData(object):
    def __init__(self, host='127.0.0.1'):

        # InfluxDB connection parameters
        self.host           = host
        self.port           = 8086
        self.dbname         = 'telegraf'
        self.dbuser         = None
        self.dbpasswd       = None
        self.useSSL         = False
        self.verifySSL      = False
        self.timeout        = None

    def returnClient(self):
        return InfluxDBClient(
                                self.host,
                                self.port,
                                self.dbuser,
                                self.dbpasswd,
                                self.dbname,
                                self.useSSL,
                                self.verifySSL,
                                self.timeout
                            )
    def getHOST(self):
        return self.host
