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
            target_book = book.book.bids if side_name == BID else book.book.asks
            for price, amount in delta_list:
                # OPTIMIZATION: Skip updates (amount > 0) that are outside the Top N (not in book)
                # This significantly reduces Pub/Sub volume for deep/irrelevant levels.
                if amount > 0 and price not in target_book:
                    continue
                
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
        if book.book.bids:
            for price in book.book.bids:
                amount = book.book.bids[price]
                payload = {
                    "type": "snapshot",
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
