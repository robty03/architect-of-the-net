import requests


def get_public_ip():
    url = "https://api.ipify.org?format=json"
    response = requests.get(url, timeout=10)
    response.raise_for_status()
    return response.json()


def get_ip_details(ip):
    url = f"https://ipwho.is/{ip}"
    response = requests.get(url, timeout=10)
    response.raise_for_status()
    return response.json()

