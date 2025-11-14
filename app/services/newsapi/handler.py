from flask import (
    Blueprint,
    request,
    jsonify
)

from logger.app_logger import AppLogger
from pydantic import ValidationError
from monitor.prometheus_monitoring import PrometheusMonitoring
from .news import Everything, NewsApiOrg


blueprint = Blueprint('news', __name__, url_prefix='/news')
logger = AppLogger()
metrics = PrometheusMonitoring()

ALLOWED_QUERY_PARAMS_EVERYTHING = {
    'q',      
    'from',
    'to',
    'language',
    'sort_by',
    'sortBy',
    'page',
    'pageSize',
    'sources',
    'domains',
    'exclude_domains',
    'excludeDomains',
}


@blueprint.route('/everything')
@logger.log
@metrics.request_latency_seconds
def everything_path():
    
    unknown = set(request.args.keys()) - ALLOWED_QUERY_PARAMS_EVERYTHING
    if unknown:
        return (
            jsonify({
                'error': 'Unknow query parameters.',
                'unknown': sorted(unknown),
                'allowed': sorted(ALLOWED_QUERY_PARAMS_EVERYTHING),
            }),
            400
        )
    
    raw = {
        'q': request.args.get('q'),
        'since': request.args.get('since') or request.args.get('from'),
        'to': request.args.get('to'),
        'language': request.args.get('language'),
        'sort_by': request.args.get('sort_by'),
        'page': request.args.get('page', type=int),
        'page_size': request.args.get('page_size', type=int),
        'sources': request.args.get('sources'),
        'domains': request.args.get('domains'),
        'exclude_domains': request.args.get('exclude_domains')
        or request.args.get('excludeDomains'),
    }
    clean_kwargs = {k: v for k, v in raw.items() if v is not None}

        
    try:
        req_model = Everything(**clean_kwargs)
    except ValidationError as e:
        return (
            jsonify(
                {
                    'error': 'Invalid query parameters',
                    'details': e.errors(),
                }
            ),
            422,
        )

    # 4) Call your wrapper

    data = NewsApiOrg() 
    req = data.everything(req=req_model)
    return jsonify(req)