import os
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt
from pyfiglet import Figlet

from api_handler import get_public_ip, get_ip_details
from aws_handler import save_scan, get_all_scans, delete_all_scans
from ai_handler import analyze_ip

console = Console()


def clear_screen():
    os.system("cls" if os.name == "nt" else "clear")


def show_banner():
    clear_screen()
    fig = Figlet(font="slant")
    banner = fig.renderText("IP Spectre")
    console.print(f"[cyan]{banner}[/cyan]")
    console.print(Panel.fit("NeoCity Surveillance Terminal", style="bold green"))


def show_menu():
    console.print("\n[bold yellow]Choose an action:[/bold yellow]")
    console.print("1. Detect public IP")
    console.print("2. Analyze IP details")
    console.print("3. Save scan to DynamoDB")
    console.print("4. Show all scans")
    console.print("5. Purge all scans")
    console.print("6. AI analyze IP")
    console.print("7. Exit")


def display_logs(items):
    table = Table(title="Mission Logs")
    table.add_column("scan_id", style="cyan")
    table.add_column("timestamp", style="green")
    table.add_column("ip", style="magenta")
    table.add_column("country", style="yellow")
    table.add_column("city", style="blue")
    table.add_column("isp", style="red")

    for item in items:
        table.add_row(
            item.get("scan_id", ""),
            item.get("timestamp", ""),
            item.get("ip", ""),
            item.get("country", ""),
            item.get("city", ""),
            item.get("isp", ""),
        )

    console.print(table)


def main():
    ip_data = None
    detail_data = None

    while True:
        show_banner()
        show_menu()
        choice = Prompt.ask("\nEnter option")

        if choice == "1":
            ip_data = get_public_ip()
            console.print(f"\n[green]Public IP detected:[/green] {ip_data['ip']}")
            input("\nPress Enter to continue...")

        elif choice == "2":
            if not ip_data:
                console.print("[red]Run option 1 first.[/red]")
            else:
                detail_data = get_ip_details(ip_data["ip"])
                console.print(detail_data)
            input("\nPress Enter to continue...")

        elif choice == "3":
            if not ip_data or not detail_data:
                console.print("[red]Run options 1 and 2 first.[/red]")
            else:
                saved = save_scan(ip_data, detail_data)
                console.print(f"[green]Saved scan:[/green] {saved['scan_id']}")
            input("\nPress Enter to continue...")

        elif choice == "4":
            items = get_all_scans()
            display_logs(items)
            input("\nPress Enter to continue...")

        elif choice == "5":
            deleted = delete_all_scans()
            console.print(f"[bold red]Deleted {deleted} logs.[/bold red]")
            input("\nPress Enter to continue...")
        
        elif choice == "6":
            if not ip_data or not detail_data:
                console.print("[red]Run options 1 and 2 first.[/red]")
            else:
                result = analyze_ip(
                ip_data["ip"],
                detail_data.get("country"),
                detail_data.get("city"),
                detail_data.get("connection", {}).get("isp")
            )

            console.print("\n[bold cyan]AI Analysis:[/bold cyan]")
            console.print(result)

            input("\nPress Enter to continue...")

        elif choice == "7":
            console.print("[bold cyan]Disconnecting from NeoCity...[/bold cyan]")
            break

        else:
            console.print("[red]Invalid option.[/red]")
            input("\nPress Enter to continue...")


if __name__ == "__main__":
    main()