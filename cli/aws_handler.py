import boto3
from datetime import datetime, timezone
import uuid


dynamodb = boto3.resource("dynamodb", region_name="eu-west-1")
table = dynamodb.Table("ip_spectre_logs")


def save_scan(ip_data, detail_data):
    item = {
        "scan_id": str(uuid.uuid4()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "ip": ip_data.get("ip"),
        "country": detail_data.get("country"),  
        "city": detail_data.get("city"),
        "continent": detail_data.get("continent"),
        "isp": detail_data.get("connection", {}).get("isp"),
        "success": str(detail_data.get("success"))
    }
    table.put_item(Item=item)
    return item


def get_all_scans():
    response = table.scan()
    return response.get("Items", [])


def delete_all_scans():
    items = get_all_scans()
    for item in items:
        table.delete_item(Key={"scan_id": item["scan_id"]})
    return len(items)