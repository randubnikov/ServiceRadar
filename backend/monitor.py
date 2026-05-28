import os
import pymysql
import boto3
 
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
 
route53 = boto3.client("route53")
for service in services:
    route53.create_health_check(
        CallerReference   = str(service["id"]),
        HealthCheckConfig = {
            "FullyQualifiedDomainName": service["url"],
            "Type":                     "HTTPS",
            "RequestInterval":          30,
            "FailureThreshold":         3,
        }