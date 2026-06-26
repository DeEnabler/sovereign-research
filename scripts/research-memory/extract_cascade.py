"""Per-URL extract waterfall: static fetch + trafilatura → Playwright + trafilatura."""

from __future__ import annotations

import os
import re
import urllib.error
import urllib.request

MIN_CHARS = int(os.environ.get("EXTRACT_MIN_CHARS", "200"))
MAX_TEXT = int(os.environ.get("EXTRACT_MAX_CHARS", "20000"))
FETCH_TIMEOUT = int(os.environ.get("EXTRACT_FETCH_TIMEOUT", "20"))
USER_AGENT = os.environ.get(
    "EXTRACT_USER_AGENT",
    "Mozilla/5.0 (compatible; sovereign-research/1.0)",
)

NAV_WORDS = re.compile(
    r"\b(cookie policy|subscribe|sign in|log in|navigation|accept all cookies)\b",
    re.I,
)


class ExtractResult:
    __slots__ = ("url", "text", "tier", "method", "chars", "error")

    def __init__(
        self,
        url: str,
        text: str,
        tier: int,
        method: str,
        chars: int,
        error: str = "",
    ) -> None:
        self.url = url
        self.text = text
        self.tier = tier
        self.method = method
        self.chars = chars
        self.error = error


def quality_ok(text: str) -> bool:
    text = (text or "").strip()
    if len(text) < MIN_CHARS:
        return False
    letters = sum(c.isalpha() for c in text)
    if letters / max(len(text), 1) < 0.35:
        return False
    if len(NAV_WORDS.findall(text[:800])) >= 3:
        return False
    return True


def _trafilatura_extract(html: bytes | str, url: str) -> str:
    try:
        import trafilatura
    except ImportError as exc:
        raise RuntimeError("trafilatura not installed") from exc
    if isinstance(html, bytes):
        downloaded = trafilatura.extract(
            html,
            url=url,
            include_links=False,
            include_tables=True,
            favor_precision=True,
        )
    else:
        downloaded = trafilatura.extract(
            html,
            url=url,
            include_links=False,
            include_tables=True,
            favor_precision=True,
        )
    return (downloaded or "").strip()


def _fetch_html(url: str) -> bytes:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": USER_AGENT, "Accept": "text/html,application/xhtml+xml"},
    )
    with urllib.request.urlopen(req, timeout=FETCH_TIMEOUT) as resp:
        return resp.read()


class ExtractCascade:
    """Sequential tier-1 then tier-2 extraction with one shared browser."""

    def __init__(self) -> None:
        self._playwright = None
        self._browser = None
        self._page = None

    def close(self) -> None:
        try:
            if self._browser:
                self._browser.close()
            if self._playwright:
                self._playwright.stop()
        except Exception:
            pass
        self._browser = None
        self._playwright = None
        self._page = None

    def _ensure_playwright(self) -> None:
        if self._page is not None:
            return
        from playwright.sync_api import sync_playwright

        self._playwright = sync_playwright().start()
        self._browser = self._playwright.chromium.launch(headless=True)
        self._page = self._browser.new_page(user_agent=USER_AGENT)

    def _playwright_html(self, url: str) -> str:
        self._ensure_playwright()
        assert self._page is not None
        self._page.goto(url, wait_until="domcontentloaded", timeout=FETCH_TIMEOUT * 1000)
        self._page.wait_for_timeout(1500)
        return self._page.content()

    def extract_one(self, url: str) -> ExtractResult:
        url = (url or "").strip()
        if not url:
            return ExtractResult(url="", text="", tier=0, method="failed", chars=0, error="empty url")

        # Tier 1: static fetch + trafilatura
        try:
            html = _fetch_html(url)
            text = _trafilatura_extract(html, url)[:MAX_TEXT]
            if quality_ok(text):
                return ExtractResult(url=url, text=text, tier=1, method="trafilatura", chars=len(text))
        except Exception as exc:
            tier1_err = str(exc)
        else:
            tier1_err = "thin or empty content"

        # Tier 2: Playwright render + trafilatura
        try:
            rendered = self._playwright_html(url)
            text = _trafilatura_extract(rendered, url)[:MAX_TEXT]
            if quality_ok(text):
                return ExtractResult(
                    url=url, text=text, tier=2, method="playwright", chars=len(text),
                )
            return ExtractResult(
                url=url, text=text[:MAX_TEXT], tier=0, method="failed",
                chars=len(text), error=f"tier2 thin content ({tier1_err})",
            )
        except Exception as exc:
            return ExtractResult(
                url=url, text="", tier=0, method="failed", chars=0,
                error=f"tier1: {tier1_err}; tier2: {exc}",
            )

    def extract_batch(self, urls: list[str]) -> list[ExtractResult]:
        results = []
        try:
            for url in urls:
                results.append(self.extract_one(url))
        finally:
            self.close()
        return results


def extract_urls_cascade(urls: list[str]) -> list[ExtractResult]:
    cascade = ExtractCascade()
    return cascade.extract_batch(urls)
