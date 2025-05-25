import psycopg2

class DatabaseService:

    def __init__(self, database_url: str):
        self.connection = psycopg2.connect(database_url)
        self.cursor = self.connection.cursor()

    def close(self):
        self.cursor.close()
        self.connection.close()



    def query(self, query, params=None):
        try:
            with self.connection.cursor() as cur:
                cur.execute(query, params)
                return cur.fetchall()
        except psycopg2.Error as e:
            print(f"Error during query execution,3: {e}")
            