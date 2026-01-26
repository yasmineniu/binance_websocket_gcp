import sys
import os
import asyncio
from logging import getLogger

# Add parent directory to path to allow importing from sibling 'models' if running as script
current_dir = os.path.dirname(os.path.abspath(__file__))
stage_a_dir = os.path.dirname(current_dir)
project_root = os.path.dirname(stage_a_dir)
sys.path.append(stage_a_dir)
sys.path.append(stage_a_dir)

from cryptofeed import FeedHandler
from cryptofeed.defines import TRADES, L2_BOOK, TICKER
BOOK_DELTA = 'book_delta'
from cryptofeed.exchanges import OKX, Binance

from cryptofeed.types import Ticker, OrderBook, Trade
from util_publish.emit import publish
import time
from models.l2_event import build_l2_event
from models.ticker_event import build_ticker_event
from models.trade_event import build_trade_event
from models.factor_event import build_factor_event

# State for factor generation
last_factor_ts = {}


import logging

# Configure logging to output to stdout
logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = getLogger('binance_feed')

async def handle_l2(book: OrderBook, receipt_timestamp, **kwargs):
    logger.info(f"Received L2 book update for {book.symbol}")
    payloads = build_l2_event(book, receipt_timestamp)
    for payload in payloads:
        publish(book.exchange.lower(), 'l2', payload)

    # 1s Factor Snapshot Logic
    current_ts = time.time() # processing time
    symbol = book.symbol
    if symbol not in last_factor_ts or (current_ts - last_factor_ts[symbol]) >= 1.0:
        factor_payload = build_factor_event(book, receipt_timestamp)
        if factor_payload:
            publish(book.exchange.lower(), 'factors', factor_payload)
            last_factor_ts[symbol] = current_ts

async def handle_ticker(ticker: Ticker, receipt_timestamp, **kwargs):
    logger.info(f"Received ticker update for {ticker.symbol}")
    payload = build_ticker_event(ticker, receipt_timestamp)
    publish(ticker.exchange.lower(), 'ticker', payload)

async def handle_trade(trade, receipt_timestamp, **kwargs):
    logger.info(f"Received trade update for {trade.symbol}")
    payload = build_trade_event(trade, receipt_timestamp)
    publish(trade.exchange.lower(), 'trades', payload)

def main():
    logger.info("Starting main...")
    fh = FeedHandler()

    try:
        logger.info("Checking for existing event loop...")
        asyncio.get_event_loop()
        logger.info("Existing event loop found.")
    except RuntimeError:
        logger.info("No existing event loop. Creating new one.")
        # FeedHandler sets policy to uvloop, so we need to set a new loop
        asyncio.set_event_loop(asyncio.new_event_loop())

    logger.info("Adding feed...")
    # HTTP Proxy for Binance/OKX if needed
    # proxy = "http://127.0.0.1:7890" # Example user proxy
    # We can pass http_proxy to Feed/Exchange classes if we instantiated them manually, 
    # but here we pass classes. FeedHandler doesn't easily propagate proxy to class-based add_feed?
    # Actually FeedHandler.add_feed accepts **kwargs which are passed to Feed __init__.
    
    fh.add_feed(
        Binance(
            symbols=['BTC-USDT', 'ETH-USDT'],
            channels=[TRADES, L2_BOOK, TICKER],
            callbacks={
                TICKER: handle_ticker,
                TRADES: handle_trade,
                L2_BOOK: handle_l2,
            },
            max_depth=30
        )
    )
    logger.info("Feed added. Running FeedHandler...")
    fh.run()


if __name__ == "__main__":
    main()
