"""
Telegram Auto DM — Backend Server
Wraps Telethon in a simple HTTP API for the Flutter app.

Usage:
    pip install telethon fastapi uvicorn
    python server.py
"""

import asyncio
import json
from fastapi import FastAPI
from pydantic import BaseModel
from telethon import TelegramClient
from telethon.sessions import StringSession
from telethon.tl.types import User
import uvicorn

app = FastAPI()

# ── Request Models ──────────────────────────────────────

class SendCodeRequest(BaseModel):
    api_id: int
    api_hash: str
    phone: str

class SignInRequest(BaseModel):
    api_id: int
    api_hash: str
    phone: str
    phone_code_hash: str
    code: str

class DialogsRequest(BaseModel):
    api_id: int
    api_hash: str
    session: str

class SendMessageRequest(BaseModel):
    api_id: int
    api_hash: str
    session: str
    user_id: int
    message: str

# ── State (in-memory, single user) ─────────────────────
_clients: dict = {}
_code_hashes: dict = {}

# ── Endpoints ──────────────────────────────────────────

@app.post("/send_code")
async def send_code(req: SendCodeRequest):
    try:
        client = TelegramClient(StringSession(), req.api_id, req.api_hash)
        await client.connect()
        result = await client.send_code_request(req.phone)
        key = f"{req.api_id}:{req.phone}"
        _clients[key] = client
        _code_hashes[key] = result.phone_code_hash
        return {"ok": True, "phone_code_hash": result.phone_code_hash}
    except Exception as e:
        return {"ok": False, "error": str(e)}

@app.post("/sign_in")
async def sign_in(req: SignInRequest):
    try:
        key = f"{req.api_id}:{req.phone}"
        client = _clients.get(key)
        if not client:
            client = TelegramClient(StringSession(), req.api_id, req.api_hash)
            await client.connect()

        await client.sign_in(
            phone=req.phone,
            code=req.code,
            phone_code_hash=req.phone_code_hash,
        )
        session_str = client.session.save()
        return {"ok": True, "session": session_str}
    except Exception as e:
        return {"ok": False, "error": str(e)}

@app.post("/get_dialogs")
async def get_dialogs(req: DialogsRequest):
    try:
        client = TelegramClient(StringSession(req.session), req.api_id, req.api_hash)
        await client.connect()
        contacts = []
        async for dialog in client.iter_dialogs():
            if dialog.is_user:
                entity = dialog.entity
                if isinstance(entity, User) and not entity.bot:
                    contacts.append({
                        "id": entity.id,
                        "name": f"{entity.first_name or ''} {entity.last_name or ''}".strip(),
                        "username": entity.username,
                    })
        await client.disconnect()
        return {"ok": True, "contacts": contacts}
    except Exception as e:
        return {"ok": False, "error": str(e)}

@app.post("/send_message")
async def send_message(req: SendMessageRequest):
    try:
        client = TelegramClient(StringSession(req.session), req.api_id, req.api_hash)
        await client.connect()
        await client.send_message(req.user_id, req.message)
        await client.disconnect()
        return {"ok": True}
    except Exception as e:
        return {"ok": False, "error": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
