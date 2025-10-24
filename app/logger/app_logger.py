import logging
import os

from functools import wraps
from logging.handlers import RotatingFileHandler
from flask import request

class AppLogger:
    def __init__(self):
        self.log_dir = "./logs"
        os.makedirs(self.log_dir, exist_ok=True)
        self.log_file_path = os.path.join(self.log_dir, "app.log")
        self.logger = self.start_logger()


    def start_logger(self):
        logger = logging.getLogger("app_logger")
        logger.setLevel(logging.INFO)
        handler = RotatingFileHandler(self.log_file_path, maxBytes=1_000_000, backupCount=5)
        formatter = logging.Formatter(
            "%(levelname)s\t%(asctime)s\n"
                "%(message)s\n\n\n"
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        return logger
    
    def log(self, func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            user_agent = request.headers.get("User-Agent")
            #ip_address = request.remote_addr
            ip_address = request.headers.get("X-Forwarded-For", request.remote_addr)
            method = request.method
            url = request.url

            self.logger.info(
                f"Request: {method} {url}\n"
                f"IP: {ip_address}\n"
                f"User-Agent: {user_agent}"
            )

            return func(*args, **kwargs)
        return wrapper