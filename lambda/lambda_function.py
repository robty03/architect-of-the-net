import json
import ipaddress


def lambda_handler(event, context):
    query_params = event.get("queryStringParameters") or {}
    ip = query_params.get("ip")

    if not ip:
        return {
            "statusCode": 400,
            "body": json.dumps({
                "error": "Missing 'ip' query parameter"
            })
        }

    try:
        ipaddress.ip_address(ip)
        return {
            "statusCode": 200,
            "body": json.dumps({
                "ip": ip,
                "valid": True,
                "message": "Valid IP address"
            })
        }
    except ValueError:
        return {
            "statusCode": 400,
            "body": json.dumps({
                "ip": ip,
                "valid": False,
                "message": "Invalid IP address"
            })
        }