import os
import urllib.request
import urllib.error
import pymysql

def get_conn():
    return pymysql.connect(
        host        = os.getenv("DB_HOST"),
        user        = os.getenv("DB_USER"),
        password    = os.getenv("DB_PASSWORD"),
        database    = os.getenv("DB_NAME"),
        cursorclass = pymysql.cursors.DictCursor
    )

def check_url(url):
    try:
        urllib.request.urlopen(f"https://{url}", timeout=10)
        return "UP", None
    except urllib.error.HTTPError:
        return "UP", None  # server responded, just an HTTP error code
    except Exception as e:
        return "DOWN", str(e)

conn = get_conn()
try:
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM services")
    services = cursor.fetchall()

    print(f"Checking {len(services)} services...")
    for service in services:
        status, error = check_url(service['url'])

        cursor.execute(
            "SELECT status FROM incidents WHERE service_id = %s ORDER BY created_at DESC LIMIT 1",
            (service['id'],)
        )
        last = cursor.fetchone()
        last_status = last['status'] if last else None

        if status != last_status:
            cursor.execute(
                "INSERT INTO incidents (service_id, status, error_message) VALUES (%s, %s, %s)",
                (service['id'], status, error or "OK")
            )
            print(f"  {service['name']}: {last_status} -> {status}")
        else:
            print(f"  {service['name']}: {status} (no change)")

    conn.commit()
finally:
    conn.close()
