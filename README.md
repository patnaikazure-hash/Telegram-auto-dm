# Telegram DM Blaster

Send a message to **all your Telegram DMs** at once.

## Setup

```bash
pip install -r requirements.txt
python main.py
```

## What you need

1. **API credentials** from [my.telegram.org](https://my.telegram.org)
   - Go to → API development tools
   - Create an app → get `api_id` and `api_hash`

2. Run the script, enter your credentials, log in with your phone number + OTP

## Features

- Logs into your Telegram account (session saved locally)
- Fetches all private DM conversations (skips bots)
- Shows each contact before sending
- 2-second delay between sends (avoids rate limiting)
- Confirmation prompt before sending

## Notes

- Session file (`tg_session.session`) is saved locally — keep it safe
- Don't spam — Telegram may temporarily limit your account for mass messaging
