import orjson
import time
from google.cloud import pubsub_v1
from constant import EXCHANGES, DATATYPES

import logging
import sys
import datetime

# Configure logging
logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger('emit')

PROJECT_ID = "cryptofeed-480903"
publisher = pubsub_v1.PublisherClient()

# Optimization: Batch publishing to reduce CPU overhead
batch_settings = pubsub_v1.types.BatchSettings(
    max_messages=2500,  # default 100
    max_bytes=1024 * 1024,  # 1 MB
    max_latency=0.1,  # 50ms buffer (default 10ms)
)
publisher = pubsub_v1.PublisherClient(batch_settings=batch_settings)


def get_callback(future, data):
    def callback(future):
        try:
            message_id = future.result()
            # logger.info(f"Published message ID: {message_id}")
        except Exception as e:
            logger.error(f"Publishing failed: {e}")
    return callback

def publish(exchange: str, datatype: str, payload: dict):
    """
    Publish payload to Pub/Sub.
    exchange: must be in EXCHANGES
    datatype: must be in DATATYPES
    """
    if exchange not in EXCHANGES:
        raise ValueError(f"Invalid exchange: {exchange}. Must be one of {EXCHANGES}")
    if datatype not in DATATYPES:
        raise ValueError(f"Invalid datatype: {datatype}. Must be one of {DATATYPES}")

    topic_id = f"crypto.{exchange}.{datatype}"
    topic_path = publisher.topic_path(PROJECT_ID, topic_id)

    payload["ingest_ts"] = datetime.datetime.now(datetime.timezone.utc)

    data = orjson.dumps(payload)
    ordering_key=payload["symbol"]
    # logger.info(f"Publishing to {topic_path}: {len(data)} bytes")
    future = publisher.publish(topic_path, data)
    future.add_done_callback(get_callback(future, data))
