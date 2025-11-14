import json
from random import choice
from flask import (
    Blueprint,
    jsonify,
    redirect,
    Response
)
from logger.app_logger import AppLogger
from monitor.prometheus_monitoring import PrometheusMonitoring
from .rapidapi import RadipApi


blueprint = Blueprint('business', __name__, url_prefix='/business')
logger = AppLogger()
metrics = PrometheusMonitoring()


@blueprint.route("/")
@metrics.request_total
def root_path():
    return redirect("/rapid_api_search", code=302)


@blueprint.route("/test")
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


@blueprint.route("/rapid_api_search")
@logger.log
@metrics.request_latency_seconds
def rapid_api_search_path():
    result = RadipApi.test_search()
    return Response(response=jsonify(result),
                    status=200,
                    content_type="application/json")

@blueprint.route("/metrics")
@logger.log
def metrics_path():
    return metrics.return_metrics()

@blueprint.route("/health")
@logger.log
@metrics.request_latency_seconds
def health():
    body = json.dumps({"status": "ok", "message": "Up & running"})
    return Response(response=body, status=200, mimetype="application/json")
