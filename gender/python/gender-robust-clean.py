#!/usr/bin/env python

host = '127.0.0.1'
port = 9199
name = 'test'

import jubatus
from jubatus.classifier.types import datum
import msgpackrpc
import time

class Retryable(object):
    def __init__(self, client_class, host, port, timeout = 10):
        self._client_class = client_class
        self._host = host
        self._port = port
        self._timeout = timeout
        self._client = None
        self.reopen()

    def reopen(self):
        if not self._client is None:
            self._client.get_client().close()
        self._client = self._client_class(self._host, self._port)
        self._client.get_client()._timeout = self._timeout

    def __getattr__(self, name):
        return getattr(self._client, name)

    def with_retry(self, retry_max, retry_interval):
        return Retryable.RetryFeature(self, retry_max, retry_interval)

    class RetryFeature(object):
        def __init__(self, client_holder, retry_max, retry_interval):
            self._holder = client_holder
            self._max = retry_max
            self._interval = retry_interval

        def __getattr__(self, name):
            return Retryable.Executer(self._holder, name, self._max, self._interval)

    class Executer(object):
        def __init__(self, holder, name, retry_max, retry_interval):
            self._holder = holder
            self._name = name
            self._max = retry_max
            self._interval = retry_interval

        def __call__(self, *args):
            retry_count = 0
            while True:
                try:
                    body = getattr(self._holder._client, self._name)
                    return body(*args)

                except (msgpackrpc.error.TransportError, msgpackrpc.error.TimeoutError) as e:
                    retry_count += 1
                    if retry_count >= self._max:
                        raise

                    self._holder.reopen()

                    print e
                    time.sleep(self._interval)
                    continue
        
client = Retryable(jubatus.Classifier, host, port, 1)

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

client.with_retry(5, 1).train(name, train_data)

raw_input('now, classify: ')

test_data = [
    datum([('hair', 'short'), ('top', 'T shirt'), ('bottom', 'jeans')], [('height', 1.81)]),
    datum([('hair', 'long'),  ('top', 'shirt'),   ('bottom', 'skirt')], [('height', 1.50)]),
]

results = client.with_retry(5, 1).classify(name, test_data)

for result in results:
    for r in result:
        print r.label, r.score
    print
