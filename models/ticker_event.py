import datetime

def build_ticker_event(ticker, receipt_timestamp):
    """
    Builds a dictionary payload for a ticker event.
    """
    payload = {
        "exchange": ticker.exchange.lower(),
        "symbol": ticker.symbol,
        "bid": float(ticker.bid) if ticker.bid is not None else None,
        "ask": float(ticker.ask) if ticker.ask is not None else None,
        "last": float(getattr(ticker, "last", None) or (ticker.raw.get("last") if ticker.raw else None)) if (getattr(ticker, "last", None) or (ticker.raw.get("last") if ticker.raw else None)) is not None else None,
        "event_ts": datetime.datetime.fromtimestamp(ticker.timestamp, tz=datetime.timezone.utc).isoformat(),
        "receipt_ts": datetime.datetime.fromtimestamp(receipt_timestamp, tz=datetime.timezone.utc).isoformat(),
    }
    return payload
