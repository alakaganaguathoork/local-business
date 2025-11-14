import datetime
import os
import requests
from pydantic import BaseModel, ConfigDict, Field
from typing import Dict, Literal, Optional, List, Any

Date = datetime.date

class Everything(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    # apiKey: Optional[str] = ""
    q: Optional[str] = None
    search_in: Optional[Literal['title', 'description', 'content']] = Field(default='title', alias='searchIn')
    sources: Optional[List[str] | str] = None
    domains: Optional[List[str] | str] = None
    exclude_domains: Optional[List[str] | str] = Field(default=None, alias='excludeDomains')
    since: Optional[str | Date] = Field(default=None, alias="from")
    to: Optional[str | Date] = Field(default_factory=lambda: Date.today())
    language: Optional[str] = 'en'
    sort_by: Optional[Literal['relevancy', 'popularity', 'publishedAt']] = Field(default='relevancy', alias='sortBy')
    page_size: Optional[int] = Field(default=100, alias='pageSize')
    page: Optional[int] = 1

    def to_params(self) -> Dict[str, Any]:
        params: Dict[str, Any] = self.model_dump(by_alias=True, exclude_none=True)
    
        def _join(values) -> str:
            if isinstance(values, list):
                return ','.join(values)
            return values
        
        def _convert_date(value: str | Date) -> str:
            if isinstance(value, str):
                value = Date.strptime(value, '%Y-%m-%d')
            value.isoformat()
            return value

        # Form `list` into a single string
        for key in ('sources', 'domains', 'excludeDomains'):
            if key in params:
                params[key] = _join(params[key])
        
        # format datetimes as ISO8601 if present
        for key in ('from', 'to'):
            if key in params:
                params[key] = _convert_date(params[key])     
        
        return params


class NewsApiOrg:
    def __init__(self):
        self.API_URL = 'https://newsapi.org/v2'
        self.API_KEY = os.getenv('NEWS_API_ORG_KEY')

    def everything(self, req: Everything) -> Dict[str, Any]:
    
        URL = f"{self.API_URL}/everything"
        params = req.to_params()
        params['apiKey'] = self.API_KEY
        print(params)
        response = requests.get(URL,
                                params=params,
                                # headers=headers,
                                timeout=None)

        try:
            return response.json()
        except Exception:
            return {"status": "error", "message": "Invalid JSON from API", "code": response.status_code}
        
# api = NewsApiOrg()
# req = Everything(
    # q = 'Ukraine',
    # since = Date.today() - datetime.timedelta(days=7),
    # to = '2025-11-13'
# )
# 
# data = api.everything(req)
# status = data.get('status')
# print(status, data.get('message')) if status not in 'ok' else print(data.get('totalResults'))
