import os
import json
import pymysql

def lambda_handler(event, context):
    message = json.loads(event["Records"][0]["Sns"]["Message"])
    alarm_name  = message["AlarmName"]
    alarm_state = message["NewStateValue"]
    if alarm_state == "ALARM":
        status = "DOWN"
    elif alarm_state == "INSUFFICIENT_DATA":
        status = "SLOW"
    else:
        return {"message": "Service recovered, nothing to save"}
    conn = pymysql.connect(
        host     = os.environ["DB_HOST"],
        user     = os.environ["DB_USER"],
        password = os.environ["DB_PASSWORD"],
        database = os.environ["DB_NAME"]
    )
    cursor = conn.cursor(pymysql.cursors.DictCursor)
    service_key = alarm_name.replace("-health-staging", "").replace("-health-production", "")
    cursor.execute("SELECT * FROM services WHERE LOWER(REPLACE(name, ' ', '-')) = %s", (service_key,))
    service = cursor.fetchone()
    cursor.execute(
        "INSERT INTO incidents (service_id, status, error_message) VALUES (%s, %s, %s)",
        (service["id"], status, f"CloudWatch Alarm: {alarm_name} is {alarm_state}")
    )
    conn.commit()
    conn.close()
    return {"message": f"Incident saved for {alarm_name}"}
