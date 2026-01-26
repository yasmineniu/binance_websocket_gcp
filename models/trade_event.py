import datetime

def build_trade_event(trade, receipt_timestamp):
    """
    Builds a dictionary payload for a trade event.
    """
    payload = {
        "exchange": trade.exchange.lower(),
        "symbol": trade.symbol,
        "side": trade.side,
        "price": float(trade.price),
        "amount": float(trade.amount),
        "event_ts": datetime.datetime.fromtimestamp(trade.timestamp, tz=datetime.timezone.utc).isoformat(),
        "receipt_ts": datetime.datetime.fromtimestamp(receipt_timestamp, tz=datetime.timezone.utc).isoformat(),
    }
    return payload