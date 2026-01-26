import datetime
from cryptofeed.defines import BID

def build_l2_event(book, receipt_timestamp):
    """
    Builds a list of dictionary payloads for an L2 book event (deltas).
    """
    payloads = []
    
    # Process Deltas
    if book.delta:
        for side_name, delta_list in book.delta.items():
            side_name = 'bid' if side_name == BID else 'ask'
            # side_name is 'bid' or 'ask'
            for price, amount in delta_list:
                payload = {
                    "type": "delta",
                    "exchange": book.exchange.lower(),
                    "symbol": book.symbol,
                    "side": side_name,
                    "price": float(price),
                    "amount": float(amount),
                    "checksum": str(book.checksum) if book.checksum is not None else None,
                    "seq_id": book.sequence_number,
                    "is_snapshot": False,
                    "event_ts": datetime.datetime.fromtimestamp(book.timestamp, tz=datetime.timezone.utc).isoformat(),
                    "receipt_ts": datetime.datetime.fromtimestamp(receipt_timestamp, tz=datetime.timezone.utc).isoformat(),
                }
                payloads.append(payload)
    else:
        # 处理 Bids
        # 【关键修正】: Snapshot 是字典，必须用 .items()
        if book.book.bids:
            for price in book.book.bids:
                amount = book.book.bids[price]
                payload = {
                    "type": "snapshot", # 标记这是快照
                    "exchange": book.exchange.lower(),
                    "symbol": book.symbol,
                    "side": "bid",
                    "price": float(price),
                    "amount": float(amount),
                    "checksum": str(book.checksum) if book.checksum is not None else None,
                    "seq_id": book.sequence_number,
                    "is_snapshot": True,
                    "event_ts": datetime.datetime.fromtimestamp(book.timestamp or receipt_timestamp, tz=datetime.timezone.utc).isoformat(),
                    "receipt_ts": datetime.datetime.fromtimestamp(receipt_timestamp, tz=datetime.timezone.utc).isoformat(),
                }
                payloads.append(payload)
        
        # 处理 Asks (同上)
        if book.book.asks:
            for price in book.book.asks:
                amount = book.book.asks[price]
                payload = {
                    "type": "snapshot",
                    "exchange": book.exchange.lower(),
                    "symbol": book.symbol,
                    "side": "ask",
                    "price": float(price),
                    "amount": float(amount),
                    "checksum": str(book.checksum) if book.checksum is not None else None,
                    "seq_id": book.sequence_number,
                    "is_snapshot": True,
                    "event_ts": datetime.datetime.fromtimestamp(book.timestamp or receipt_timestamp, tz=datetime.timezone.utc).isoformat(),
                    "receipt_ts": datetime.datetime.fromtimestamp(receipt_timestamp, tz=datetime.timezone.utc).isoformat(),
                }
                payloads.append(payload)
        
    return payloads
