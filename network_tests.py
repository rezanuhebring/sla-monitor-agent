import logging
import speedtest
from icmplib import ping

def run_speed_test():
    try:
        s = speedtest.Speedtest()
        s.get_best_server()
        s.download(threads=1)
        s.upload(threads=1)
        res = s.results.dict()
        return res.get("download", 0) / 1_000_000, res.get("upload", 0) / 1_000_000
    except Exception as e:
        logging.error(f"Speedtest failed: {e}", exc_info=True)
        return None, None

def perform_ping_test(target):
    try:
        host = ping(target, count=10, interval=0.2)
        if not host.is_alive:
            return 1000, 100, 1.0 # High values for failure
        return host.avg_rtt, host.jitter, host.packet_loss
    except Exception as e:
        logging.error(f"Ping test to {target} failed: {e}")
        return None, None, None

def run_all_tests(config):
    target = config.get('settings', 'target_host', fallback='8.8.8.8')
    logging.info("Running speed test...")
    down, up = run_speed_test()
    logging.info("Running ping test...")
    latency, jitter, loss = perform_ping_test(target)
    
    if all(v is not None for v in [down, up, latency, jitter, loss]):
        return {
            "download": round(down, 2), "upload": round(up, 2),
            "ping_latency": round(latency, 2), "jitter": round(jitter, 2),
            "packet_loss": loss
        }
    return None