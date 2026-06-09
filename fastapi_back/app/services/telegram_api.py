"""Low-level Telegram Bot API client."""

from typing import Any, Dict, List, Optional

import httpx

from app.config.config import settings

API_BASE = "https://api.telegram.org"


class TelegramApi:
    def __init__(self, token: str):
        self._token = token
        self._base = f"{API_BASE}/bot{token}"

    async def get_me(self) -> Dict[str, Any]:
        return await self._post("getMe", {})

    async def send_message(
        self,
        chat_id: int,
        text: str,
        *,
        parse_mode: Optional[str] = None,
        disable_web_page_preview: bool = True,
    ) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "chat_id": chat_id,
            "text": text[:4096],
            "disable_web_page_preview": disable_web_page_preview,
        }
        if parse_mode:
            payload["parse_mode"] = parse_mode
        return await self._post("sendMessage", payload)

    async def get_updates(
        self,
        offset: Optional[int] = None,
        timeout: int = 30,
    ) -> List[Dict[str, Any]]:
        payload: Dict[str, Any] = {"timeout": timeout}
        if offset is not None:
            payload["offset"] = offset
        data = await self._post("getUpdates", payload)
        return data.get("result", [])

    async def _post(self, method: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        async with httpx.AsyncClient(timeout=httpx.Timeout(60.0, connect=10.0)) as client:
            res = await client.post(f"{self._base}/{method}", json=payload)
            res.raise_for_status()
            data = res.json()
            if not data.get("ok"):
                raise RuntimeError(data.get("description", "Telegram API error"))
            return data


def get_telegram_api() -> Optional[TelegramApi]:
    token = (settings.TELEGRAM_BOT_TOKEN or "").strip()
    if not token:
        return None
    return TelegramApi(token)
