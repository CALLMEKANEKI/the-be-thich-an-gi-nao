import httpx


class FakeResponse:
    """Giả lập httpx.Response, chỉ có những gì code của mình dùng."""

    def __init__(self, data=None, status_code=200):
        self._data = data
        self.status_code = status_code

    def json(self):
        return self._data

    def raise_for_status(self):
        if self.status_code >= 400:
            raise httpx.HTTPStatusError(
                "lỗi giả lập",
                request=httpx.Request("GET", "http://test"),
                response=httpx.Response(self.status_code),
            )