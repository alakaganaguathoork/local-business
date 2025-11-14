from flask import Flask
from services.newsapi import handler as news
from services.rapidapi import handler as business
import os


def create_app() -> Flask:
    app = Flask(import_name=__name__)
    app.register_blueprint(news.blueprint)
    app.register_blueprint(business.blueprint)
    print(app.url_defaults)
    return app

def run(enable_debug):
    APP_ENV = os.getenv('APP_ENV', 'local')
    HOST = "0.0.0.0"
    PORT=5400
    print(f"+ + + Current environment is {APP_ENV} + + +")
    app = create_app()
    app.run(HOST, PORT, enable_debug)

if __name__ == '__main__':
    run(True)