### PromQL examples:
Sum of historgram http response size ignoring handler "/metrics":
```
  sum by(handler) (prometheus_http_response_size_bytes_bucket{handler!="/metrics"})
``` 