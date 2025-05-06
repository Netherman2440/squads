import psycopg2

class DatabaseService:

    def __init__(self, database_url: str):
        self.connection = psycopg2.connect(database_url)
        self.cursor = self.connection.cursor()

    def close(self):
        self.cursor.close()
        self.connection.close()



    def select_data(self, query, params=None):
        try:
            with self.connection.cursor() as cur:
                cur.execute(query, params)
                return cur.fetchall()
        except psycopg2.Error as e:
            print(f"Error selecting data: {e}")
            raise

    def insert_data(self, query, params=None):
        print(query)
        try:
            with self.connection.cursor() as cur:
                cur.execute(query, params)
                self.connection.commit()
        except psycopg2.Error as e:
            print(f"Error inserting data: {e}")
            raise

    def update_data(self, query, params=None):
        try:
            with self.connection.cursor() as cur:
                cur.execute(query, params)
                self.connection.commit()
        except psycopg2.Error as e:
            print(f"Error updating data: {e}")
            raise

    def delete_data(self, query, params=None):
        try:
            with self.connection.cursor() as cur:
                cur.execute(query, params)
                self.connection.commit()
        except psycopg2.Error as e:
            print(f"Error deleting data: {e}")
            raise
