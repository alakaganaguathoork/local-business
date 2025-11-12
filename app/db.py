from jinja2 import Environment, FileSystemLoader, StrictUndefined
from mysql.connector import connect, MySQLConnection
from mysql.connector.cursor import MySQLCursor
from typing import Optional
from pathlib import Path


class Database:

    def __init__(
            self, 
            *,
            host: str = 'localhost',
            port: int = 3306,
            user: str = 'root', 
            password: Optional[str] = None, 
            database: Optional[str] = None
        ) -> None:

        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.database = database
        self.connection = self._connect()
        self.sqls_dir = self._get_sqls_dir()


    def __enter__(self) -> "Database":
        self._connect()
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        self._close()

    def _connect(self) -> MySQLConnection:
        return connect(host=self.host, port=self.port, user=self.user, password=self.password, database=self.database)
    
    def _close(self) -> None:
        self.connection.close()

    def _get_sqls_dir(self) -> Path:
        path = Path('sql')

        if not path.is_dir():
            raise FileNotFoundError(f"Specified {path} path doesn't exist.")
        
        print(f"PATH: {path}")
        return path

    def cursor(self) -> MySQLCursor:
        return self.connection.cursor()
    
    def render_sql(self, template_name: str, **vars) -> str:
        template_name = f"{template_name}.sql.j2"
        template_path = Path(f"{self.sqls_dir}/{template_name}")
        
        env = Environment(
            loader=FileSystemLoader(str(self.sqls_dir)),
            undefined=StrictUndefined,
            trim_blocks=True,
            lstrip_blocks=True
        )

        return env.get_template(template_path).render(**vars)

    def execute_sql(self, sql) -> MySQLCursor:
        c = self.cursor()
        c.execute(sql)
        return c


with Database(password="root") as db:
    sql = db.render_sql("create_db", name="test")
    db.execute_sql(sql)
    dbs = db.execute_sql("SHOW DATABASES;").fetchall()
    print(dbs)