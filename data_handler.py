import requests
import logging

def send_results_to_api(result_data, config):
    api_url = config.get('server', 'api_url')
    agent_id = config.get('agent', 'id')
    payload = result_data.copy()
    payload['agent_id'] = agent_id
    try:
        response = requests.post(api_url, json=payload, timeout=15)
        response.raise_for_status() 
        logging.info(f"Successfully sent data to API for agent '{agent_id}'.")
        return True
    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to send data to API: {e}")
        return False