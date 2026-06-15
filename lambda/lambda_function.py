import json
import os
import pymysql
import boto3

def get_conn():
    return pymysql.connect(
        host        = os.environ['DB_HOST'],
        user        = os.environ['DB_USER'],
        password    = os.environ['DB_PASSWORD'],
        database    = os.environ['DB_NAME'],
        cursorclass = pymysql.cursors.DictCursor
    )

def handle_api(event):
    path = event.get('rawPath', '/')
    conn = get_conn()
    cursor = conn.cursor()

    if path == '/services':
        cursor.execute("SELECT * FROM services")
        data = cursor.fetchall()

    elif path == '/incidents':
        cursor.execute("""
            SELECT incidents.id, services.name, incidents.status,
                   incidents.error_message,
                   CAST(incidents.created_at AS CHAR) as created_at
            FROM incidents
            JOIN services ON incidents.service_id = services.id
            ORDER BY incidents.created_at DESC
        """)
        data = cursor.fetchall()

    else:
        data = []

    conn.close()

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        },
        'body': json.dumps(data, default=str)
    }

def handle_alarm(event):
    sns_message  = json.loads(event['Records'][0]['Sns']['Message'])
    alarm_name   = sns_message.get('AlarmName', '')
    alarm_state  = sns_message.get('NewStateValue', '')
    alarm_reason = sns_message.get('NewStateReason', '')

    service_key = alarm_name.replace("-health-staging", "").replace("-health-production", "")

    conn   = get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT * FROM services WHERE LOWER(REPLACE(name, ' ', '-')) = %s",
        (service_key,)
    )
    service = cursor.fetchone()

    if service:
        status = "DOWN" if alarm_state == "ALARM" else "UP"
        cursor.execute(
            "INSERT INTO incidents (service_id, status, error_message) VALUES (%s, %s, %s)",
            (service["id"], status, f"CloudWatch Alarm: {alarm_name} is {alarm_state}")
        )
        conn.commit()

        ses = boto3.client('ses', region_name='us-east-1')
        ses.send_email(
            Source      = service['dev_email'],
            Destination = {'ToAddresses': [service['dev_email']]},
            Message     = {
                'Subject': {'Data': f"ALERT: {service['name']} is {status}"},
                'Body':    {'Text': {'Data': f"Service: {service['name']}\nURL: {service['url']}\nStatus: {status}\nReason: {alarm_reason}"}}
            }
        )
        print(f"Alert sent for {service['name']}: {status}")

    conn.close()

def lambda_handler(event, context):
    if 'rawPath' in event:
        return handle_api(event)
    else:
        handle_alarm(event)
