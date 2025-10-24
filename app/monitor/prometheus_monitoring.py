import functools
from flask import request
from prometheus_client import (
    Counter, 
    Histogram,
    CollectorRegistry,
    generate_latest,
    CONTENT_TYPE_LATEST
)

class PrometheusMonitoring:

    def __init__(self):
        self.registry = CollectorRegistry()
        self.REQUEST_COUNT = Counter(
            name='local_http_requests_total',
            documentation='Total HTTP requests',
            labelnames=['method', 'endpoint', 'status'],
            registry=self.registry
        )
        self.REQUEST_LATENCY = Histogram(
            'local_http_request_duration_seconds',
            'HTTP request latency',
            ['method', 'endpoint'],
            registry=self.registry
        )
        

    def return_metrics(self):
        return generate_latest(self.registry), 200, {'Content-Type': CONTENT_TYPE_LATEST}
    

    def request_total(self, func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            method = request.method
            endpoint = request.path
            response = func(*args, **kwargs)
            status = str(response.status_code)
            # registry = self.registry
            self.REQUEST_COUNT.labels(method=method, endpoint=endpoint, status=status).inc()
            return func(*args, **kwargs)
        return wrapper
    

    def request_latency_seconds(self, func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            method = request.method
            endpoint = request.path
            # registy = self.registry
            with self.REQUEST_LATENCY.labels(method=method, endpoint=endpoint).time():
                return func(*args, **kwargs)
        return wrapper