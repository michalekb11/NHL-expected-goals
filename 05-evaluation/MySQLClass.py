# Libraries
import sqlalchemy

class MySQL:
    """Class to connect and interact with MySQL database"""
    def __init__(self, user='root', password='rootdata', schema='nhl') -> None:
        self.user = user
        self.password = password
        self.schema = schema
        self.engine = None

    def connect(self):
        # Create the engine to connect to the MySQL database
        self.engine = sqlalchemy.create_engine(f'mysql+mysqlconnector://{self.user}:{self.password}@localhost/{self.schema}')
        return

    def execute(self, query):
        with self.engine.begin() as conn: 
            conn.execute(query)
