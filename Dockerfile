FROM python:3.12-alpine

ENV FLASK_DEBUG=1

RUN apk add curl \
            nano

RUN addgroup -S runner \
    && adduser -S runner -G runner

WORKDIR /home/runner/app
COPY app/ /home/runner/app/
RUN chown -R runner:runner /home/runner/app

USER runner

RUN python3 -m venv venv \
    && . venv/bin/activate \
    && pip install --no-cache-dir -r requirements.txt \
    && find . -name '__pycache__' -exec rm -rf {} + \
    && rm -rf venv/lib/python*/site-packages/pip* venv/lib/python*/site-packages/setuptools*

EXPOSE 5400

ENTRYPOINT ["venv/bin/python", "app.py"]