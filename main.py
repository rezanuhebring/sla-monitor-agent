import time
import configparser
import logging
from network_tests import run_all_tests
from data_handler import send_results_to_api

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.FileHandler("monitor.log"), logging.StreamHandler()]
)

def main():
    logging.info("Starting Internet SLA Monitor Agent.")
    config = configparser.ConfigParser()
    config.read('config.ini')
    
    interval = config.getint('settings', 'interval_seconds', fallback=300)
    
    while True:
        logging.info("--- Running new test cycle ---")
        results = run_all_tests(config)
        if results:
            send_results_to_api(results, config)
        else:
            logging.warning("Test cycle produced no results. Skipping API call.")
        
        logging.info(f"--- Cycle finished. Waiting for {interval} seconds. ---")
        time.sleep(interval)

if __name__ == "__main__":
    main()