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

existing = route53.list_health_checks()
existing_domains = {
    hc["HealthCheckConfig"]["FullyQualifiedDomainName"]
    for hc in existing["HealthChecks"]
}

for service in services:
    if service["url"] not in existing_domains:
        route53.create_health_check(
            CallerReference   = service["url"],
            HealthCheckConfig = {
                "FullyQualifiedDomainName": service["url"],
                "Type":                     "HTTPS",
                "RequestInterval":          30,
                "FailureThreshold":         3,
            }
        )