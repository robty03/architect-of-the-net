import requests
import boto3

ssm = boto3.client("ssm", region_name="eu-west-1")

def get_api_key():
    response = ssm.get_parameter(
        Name="openrouter_api_key",
        WithDecryption=True
    )

    return response["Parameter"]["Value"]

def analyze_ip(ip, country, city, isp):

    api_key = get_api_key()

    prompt = f"""
Explain this IP address.

IP: {ip}
Country: {country}
City: {city}
ISP: {isp}
"""

    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        },
        json={
            "model": "openai/gpt-3.5-turbo",
            "messages": [{"role": "user", "content": prompt}]
        }
    )

    return response.json()["choices"][0]["message"]["content"]