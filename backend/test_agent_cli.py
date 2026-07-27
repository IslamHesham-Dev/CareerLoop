import getpass
import requests

BASE_URL = "http://127.0.0.1:8000/v1"

def main():
    print("=== CareerLoop Terminal Agent Tester ===")
    username = input("GIU Username: ")
    password = getpass.getpass("GIU Password: ")

    print("\nLogging in...")
    try:
        resp = requests.post(f"{BASE_URL}/auth/login", json={"username": username, "password": password})
        resp.raise_for_status()
    except requests.RequestException as e:
        print(f"Login failed: {e}")
        if resp is not None:
            print(resp.text)
        return

    token = resp.json().get("session_token")
    if not token:
        print("Failed to parse session token.")
        return

    print("Login successful! You can now chat with the Copilot.")
    print("Type 'quit' or 'exit' to close.\n")

    while True:
        try:
            msg = input("\nYou: ")
        except (KeyboardInterrupt, EOFError):
            break
            
        if msg.strip().lower() in ("quit", "exit"):
            break
            
        if not msg.strip():
            continue
            
        print("Copilot is thinking...")
        try:
            resp = requests.post(
                f"{BASE_URL}/chat",
                headers={"Authorization": f"Bearer {token}"},
                json={"message": msg}
            )
            resp.raise_for_status()
            data = resp.json()
            
            print(f"\nCopilot: {data.get('reply')}")
            
            tools = data.get("tool_events", [])
            if tools:
                tool_names = [t.get("name") for t in tools]
                print(f"\n[Tools invoked: {', '.join(tool_names)}]")
                
        except requests.RequestException as e:
            print(f"Error communicating with agent: {e}")
            if resp is not None:
                print(resp.text)

if __name__ == "__main__":
    main()
