import os
import pymysql

conn = pymysql.connect(
    host     = os.getenv("DB_HOST"),
    user     = os.getenv("DB_USER"),
    password = os.getenv("DB_PASSWORD"),
    database = os.getenv("DB_NAME")
)
cursor = conn.cursor(pymysql.cursors.DictCursor)
cursor.execute("SELECT * FROM services")
services = cursor.fetchall()
conn.close()

print(f"Found {len(services)} services in database")
for service in services:
    print(f"  - {service['name']}: {service['url']}")
