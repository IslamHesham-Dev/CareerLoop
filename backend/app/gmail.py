from __future__ import annotations

import base64
from email.message import EmailMessage
from typing import Any
from urllib.parse import urlencode

import requests


AUTHORIZATION_URL = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URL = "https://oauth2.googleapis.com/token"
USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo"
SEND_URL = "https://gmail.googleapis.com/gmail/v1/users/me/messages/send"
GMAIL_SEND_SCOPE = "https://www.googleapis.com/auth/gmail.send"


class GmailIntegrationError(RuntimeError):
    pass


class GmailClient:
    @staticmethod
    def authorization_url(
        *,
        client_id: str,
        redirect_uri: str,
        state: str,
    ) -> str:
        query = urlencode(
            {
                "client_id": client_id,
                "redirect_uri": redirect_uri,
                "response_type": "code",
                "scope": f"openid email {GMAIL_SEND_SCOPE}",
                "access_type": "offline",
                "include_granted_scopes": "true",
                "prompt": "consent",
                "state": state,
            }
        )
        return f"{AUTHORIZATION_URL}?{query}"

    @staticmethod
    def exchange_code(
        *,
        client_id: str,
        client_secret: str,
        redirect_uri: str,
        code: str,
        timeout: float = 30,
    ) -> dict[str, Any]:
        return GmailClient._token_request(
            {
                "client_id": client_id,
                "client_secret": client_secret,
                "code": code,
                "grant_type": "authorization_code",
                "redirect_uri": redirect_uri,
            },
            timeout=timeout,
        )

    @staticmethod
    def refresh_access_token(
        *,
        client_id: str,
        client_secret: str,
        refresh_token: str,
        timeout: float = 30,
    ) -> dict[str, Any]:
        return GmailClient._token_request(
            {
                "client_id": client_id,
                "client_secret": client_secret,
                "refresh_token": refresh_token,
                "grant_type": "refresh_token",
            },
            timeout=timeout,
        )

    @staticmethod
    def user_email(access_token: str, *, timeout: float = 30) -> str:
        response = requests.get(
            USERINFO_URL,
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=timeout,
        )
        data = GmailClient._json(response)
        if response.status_code < 200 or response.status_code >= 300:
            raise GmailIntegrationError(
                str(data.get("error_description") or "Gmail identity failed.")
            )
        email = data.get("email")
        if not isinstance(email, str) or "@" not in email:
            raise GmailIntegrationError(
                "Google did not return the connected Gmail address."
            )
        return email

    @staticmethod
    def send_pdf(
        *,
        access_token: str,
        sender: str,
        recipient: str,
        subject: str,
        body: str,
        attachment: bytes,
        attachment_name: str,
        timeout: float = 45,
    ) -> dict[str, Any]:
        message = EmailMessage()
        message["To"] = recipient
        message["From"] = sender
        message["Subject"] = subject
        message.set_content(body)
        message.add_attachment(
            attachment,
            maintype="application",
            subtype="pdf",
            filename=attachment_name,
        )
        return GmailClient._send(message, access_token=access_token, timeout=timeout)

    @staticmethod
    def send(
        *,
        access_token: str,
        sender: str,
        recipient: str,
        subject: str,
        body: str,
        timeout: float = 45,
    ) -> dict[str, Any]:
        """Send a plain-text email with no attachment.

        Not every career email needs a CV attached (asking a professor a
        question, a short recruiter introduction); `send_pdf` forces one, so
        this is the version for everything else.
        """
        message = EmailMessage()
        message["To"] = recipient
        message["From"] = sender
        message["Subject"] = subject
        message.set_content(body)
        return GmailClient._send(message, access_token=access_token, timeout=timeout)

    @staticmethod
    def _send(
        message: EmailMessage,
        *,
        access_token: str,
        timeout: float,
    ) -> dict[str, Any]:
        raw = base64.urlsafe_b64encode(message.as_bytes()).decode("ascii")
        response = requests.post(
            SEND_URL,
            headers={
                "Authorization": f"Bearer {access_token}",
                "Accept": "application/json",
                "Content-Type": "application/json",
            },
            json={"raw": raw},
            timeout=timeout,
        )
        data = GmailClient._json(response)
        if response.status_code < 200 or response.status_code >= 300:
            error = data.get("error")
            message_text = (
                error.get("message")
                if isinstance(error, dict)
                else None
            )
            raise GmailIntegrationError(
                str(message_text or "Gmail could not send the email.")
            )
        message_id = data.get("id")
        if not isinstance(message_id, str) or not message_id:
            raise GmailIntegrationError(
                "Gmail accepted the email but returned no message ID."
            )
        return data

    @staticmethod
    def _token_request(
        data: dict[str, str],
        *,
        timeout: float,
    ) -> dict[str, Any]:
        response = requests.post(
            TOKEN_URL,
            data=data,
            headers={"Accept": "application/json"},
            timeout=timeout,
        )
        payload = GmailClient._json(response)
        if response.status_code < 200 or response.status_code >= 300:
            raise GmailIntegrationError(
                str(
                    payload.get("error_description")
                    or payload.get("error")
                    or "Google authorization could not be completed."
                )
            )
        return payload

    @staticmethod
    def _json(response: requests.Response) -> dict[str, Any]:
        try:
            payload = response.json()
        except ValueError:
            return {}
        return payload if isinstance(payload, dict) else {}
