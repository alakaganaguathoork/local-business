import json
import os
from random import choice
from flask import (
    Flask,
    jsonify,
    redirect,
    Response
)
from logger.app_logger import AppLogger
from monitor.prometheus_monitoring import PrometheusMonitoring
from rapidapi import RadipApi

APP_ENV = "local"
app = Flask(__name__)
logger = AppLogger()
metrics = PrometheusMonitoring()


@app.route("/")
@metrics.request_total
def root_path():
    return redirect("/rapid_api_search", code=302)


@app.route("/test")
@logger.log
@metrics.request_total
def test_path():
    option = choice([True, False])
    if option == True:
        return Response("OK",
                        200,
                        {'Content-Type': 'text/plain'})
    else:
        return Response("ERROR",
                500,
                {'Content-Type': 'text/plain'})


@app.route("/rapid_api_search")
@logger.log
@metrics.request_latency_seconds
def rapid_api_search_path():
    result = RadipApi.test_search()
    return Response(response=jsonify(result),
                    status=200,
                    content_type="application/json")


@app.route("/metrics")
@logger.log
def metrics_path():
    return metrics.return_metrics()

@app.route("/health")
@logger.log
@metrics.request_latency_seconds
def health():
    body = json.dumps({"status": "ok", "message": "Up & running"})
    return Response(response=body, status=200, mimetype="application/json")

def run(enable_debug):
    APP_ENV = os.getenv("APP_ENV")
    HOST = "0.0.0.0"
    PORT=5400
    if APP_ENV == "local":
        print(f"+ + + Current environment is {APP_ENV} + + +")
    app.run(HOST, PORT, enable_debug)