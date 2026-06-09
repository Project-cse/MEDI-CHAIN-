"""Telegram account linking (patient chat_id ↔ PMS user)."""

from typing import Any, Dict, Optional

from app.config.db import db


async def ensure_telegram_schema() -> None:
    await db.execute(
        """
        CREATE TABLE IF NOT EXISTS telegram_user_links (
            chat_id BIGINT PRIMARY KEY,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            telegram_username TEXT,
            linked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id)
        )
        """
    )
    await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_telegram_user_links_user_id ON telegram_user_links(user_id)"
    )


async def get_link_by_chat_id(chat_id: int) -> Optional[Dict[str, Any]]:
    sql = """
        SELECT l.chat_id, l.user_id, l.telegram_username, l.linked_at,
               u.name, u.email, u.phone, u.role
        FROM telegram_user_links l
        JOIN users u ON u.id = l.user_id
        WHERE l.chat_id = $1
    """
    return await db.fetch_row(sql, chat_id)


async def get_link_by_user_id(user_id: int) -> Optional[Dict[str, Any]]:
    sql = "SELECT * FROM telegram_user_links WHERE user_id = $1"
    return await db.fetch_row(sql, user_id)


async def link_chat_to_user(
    chat_id: int,
    user_id: int,
    telegram_username: Optional[str] = None,
) -> Dict[str, Any]:
    sql = """
        INSERT INTO telegram_user_links (chat_id, user_id, telegram_username)
        VALUES ($1, $2, $3)
        ON CONFLICT (chat_id) DO UPDATE SET
            user_id = EXCLUDED.user_id,
            telegram_username = EXCLUDED.telegram_username,
            linked_at = CURRENT_TIMESTAMP
        RETURNING *
    """
    return await db.fetch_row(sql, chat_id, user_id, telegram_username)


async def unlink_chat(chat_id: int) -> bool:
    row = await db.fetch_row(
        "DELETE FROM telegram_user_links WHERE chat_id = $1 RETURNING chat_id",
        chat_id,
    )
    return row is not None
