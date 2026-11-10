import asyncio
import sys
from telethon import TelegramClient
from telethon.tl.types import User

# ── CONFIG ──────────────────────────────────────────────
# Get from https://my.telegram.org → API development tools
API_ID    = int(input("Enter your API ID: "))
API_HASH  = input("Enter your API HASH: ").strip()
SESSION   = "tg_session"
# ────────────────────────────────────────────────────────

async def get_all_dms(client):
    peers = []
    print("\n[*] Fetching all DMs...")
    async for dialog in client.iter_dialogs():
        if dialog.is_user:
            entity = dialog.entity
            if isinstance(entity, User) and not entity.bot:
                peers.append(entity)
    return peers

async def send_to_all(client, peers, message):
    success = 0
    fail = 0
    for user in peers:
        try:
            name = f"{user.first_name or ''} {user.last_name or ''}".strip()
            await client.send_message(user, message)
            print(f"  [✓] Sent to {name} (@{user.username or user.id})")
            success += 1
            await asyncio.sleep(2)  # rate limit safety
        except Exception as e:
            print(f"  [✗] Failed for {user.id}: {e}")
            fail += 1
    return success, fail

async def main():
    client = TelegramClient(SESSION, API_ID, API_HASH)
    await client.start()
    print("[✓] Logged in successfully!")

    peers = await get_all_dms(client)
    print(f"[*] Found {len(peers)} DM contacts.")

    if not peers:
        print("[!] No DMs found.")
        await client.disconnect()
        return

    print("\nEnter the message to send to ALL your DMs.")
    print("(Type your message, then press Enter twice to confirm)\n")
    lines = []
    while True:
        line = input()
        if line == "":
            break
        lines.append(line)
    message = "\n".join(lines)

    if not message.strip():
        print("[!] Empty message. Exiting.")
        await client.disconnect()
        return

    confirm = input(f"\n[?] Send to {len(peers)} contacts? (yes/no): ").strip().lower()
    if confirm != "yes":
        print("[!] Cancelled.")
        await client.disconnect()
        return

    print("\n[*] Sending...\n")
    success, fail = await send_to_all(client, peers, message)

    print(f"\n[✓] Done! Sent: {success} | Failed: {fail}")
    await client.disconnect()

if __name__ == "__main__":
    asyncio.run(main())
