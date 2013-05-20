#!/usr/bin/env python

host = '127.0.0.1'
port = 9199
name = 'test'

import jubatus
from jubatus.classifier.types import datum
import msgpackrpc
import time

client = jubatus.Classifier(host, port)
client.get_client()._timeout = 1

try:
    train_data = [
        ('male',   datum([('hair', 'short'), ('top', 'sweater'), ('bottom', 'jeans')], [('height', 1.70)])),
        ('female', datum([('hair', 'long'),  ('top', 'shirt'),   ('bottom', 'skirt')], [('height', 1.56)])),
        ('male',   datum([('hair', 'short'), ('top', 'jacket'),  ('bottom', 'chino')], [('height', 1.65)])),
        ('female', datum([('hair', 'short'), ('top', 'T shirt'), ('bottom', 'jeans')], [('height', 1.72)])),
        ('male',   datum([('hair', 'long'),  ('top', 'T shirt'), ('bottom', 'jeans')], [('height', 1.82)])),
        ('female', datum([('hair', 'long'),  ('top', 'jacket'),  ('bottom', 'skirt')], [('height', 1.43)])),
        #    ('male',   datum([('hair', 'short'), ('top', 'jacket'),  ('bottom', 'jeans')], [('height', 1.76)])),
        #    ('female', datum([('hair', 'long'),  ('top', 'sweater'), ('bottom', 'skirt')], [('height', 1.52)])),
        ]

    retry_max = 5
    retry_interval = 3
    retry_count = 0
    while True:
        try:
            client.train(name, train_data)

        except (msgpackrpc.error.TransportError, msgpackrpc.error.TimeoutError) as e:
            retry_count += 1
            if retry_count >= retry_max:
                raise

            client.get_client().close()
            client = jubatus.Classifier(host, port)
            client.get_client()._timeout = 1

            print e
            time.sleep(retry_interval)
            continue
        break

    time.sleep(3)

    test_data = [
        datum([('hair', 'short'), ('top', 'T shirt'), ('bottom', 'jeans')], [('height', 1.81)]),
        datum([('hair', 'long'),  ('top', 'shirt'),   ('bottom', 'skirt')], [('height', 1.50)]),
        ]

    retry_count = 0
    while True:
        try:
            results = client.classify(name, test_data)

        except (msgpackrpc.error.TransportError, msgpackrpc.error.TimeoutError) as e:
            retry_count += 1
            if retry_count >= retry_max:
                raise

            client.get_client().close()
            client = jubatus.Classifier(host, port)
            client.get_client()._timeout = 1

            print e
            time.sleep(retry_interval)
            continue
        break

    for result in results:
        for r in result:
            print r.label, r.score
            print

except msgpackrpc.error.RPCError as e:
    print e

finally:
    client.get_client().close()
