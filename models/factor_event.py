import datetime

def build_factor_event(book, receipt_timestamp):
    """
    Builds a dictionary payload for a 1s factor snapshot.
    """
    if not book.book.bids or not book.book.asks:
        return None

    # Safe iteration for SortedDict (likely does not support .keys()[-1] indexing)
    
    # Bids are sorted DESC? The library behavior for bids might be ASC or DESC. 
    # Usually: Bids [High -> Low] (or Low->High). 
    # If keys() is not supported, we can convert to list.
    all_bids = list(book.book.bids) # [price1, price2, ...]
    all_asks = list(book.book.asks)
    
    if not all_bids or not all_asks:
        return None

    # Assuming Standard Cryptofeed/OrderBook behavior
    # Bids: usually SortedDict keys are sorted. If it's standard sorting: Low -> High.
    # So best bid is the LAST element.
    best_bid = float(all_bids[-1])
    best_ask = float(all_asks[0])
    
    # Calculate Factors
    mid_price = (best_bid + best_ask) / 2
    spread = best_ask - best_bid
    
    # Volume Imbalance (Top 5 levels)
    # Get values for the best prices
    bid_vol_5 = sum(float(book.book.bids[p]) for p in all_bids[-5:])
    ask_vol_5 = sum(float(book.book.asks[p]) for p in all_asks[:5])
    imbalance = (bid_vol_5 - ask_vol_5) / (bid_vol_5 + ask_vol_5) if (bid_vol_5 + ask_vol_5) > 0 else 0

    payload = {
        "exchange": book.exchange.lower(),
        "symbol": book.symbol,
        "mid_price": mid_price,
        "spread": spread,
        "imbalance_5": imbalance,
        "best_bid": best_bid,
        "best_ask": best_ask,
        "checksum": str(book.checksum) if book.checksum is not None else None,
        "event_ts": datetime.datetime.fromtimestamp(book.timestamp or receipt_timestamp, tz=datetime.timezone.utc).isoformat(),
        "receipt_ts": datetime.datetime.fromtimestamp(receipt_timestamp, tz=datetime.timezone.utc).isoformat(),
    }
    return payload
