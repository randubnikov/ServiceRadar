import json
import os
import pymysql
import boto3

def lambda_handler(event, context):
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    alarm_name = sns_message.get('AlarmName', '')
    alarm_state = sns_message.get('NewStateValue', '')
    alarm_reason = sns_message.get('NewStateReason', '')

    service_key = alarm_name.replace("-health-staging", "").replace("-health-production", "")

    conn = pymysql.connect(
        host     = os.environ['DB_HOST'],
        user     = os.environ['DB_USER'],
        password = os.environ['DB_PASSWORD'],
        database = os.environ['DB_NAME']
    )
    cursor = conn.cursor(pymysql.cursors.DictCursor)
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
            Source=os.environ['ALERT_EMAIL'],
            Destination={'ToAddresses': [service['dev_email']]},
            Message={
                'Subject': {'Data': f"🚨 ALERT: {service['name']} is {status}"},
                'Body': {
                    'Text': {
                        'Data': f"""
Service Monitor Alert

Service:  {service['name']}
URL:      {service['url']}
Status:   {status}
Reason:   {alarm_reason}
Developer: {service['dev_name']}

This is an automated alert from your monitoring system.
                        """
                    }
                }
            }
        )
        print(f"Alert sent for {service['name']}: {status}")

    conn.close()
