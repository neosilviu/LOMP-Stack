#!/usr/bin/env python3
"""
webhook_sender.py - Part of LOMP Stack v3.0
Part of LOMP Stack v3.0

Author: Silviu Ilie <neosilviu@gmail.com>
Company: aemdPC
Version: 3.0.0
Copyright © 2025 aemdPC. All rights reserved.
License: MIT License

Repository: https://github.com/aemdPC/lomp-stack-v3
Documentation: https://docs.aemdpc.com/lomp-stack
Support: https://support.aemdpc.com
"""


import json
import requests
import hashlib
import hmac
import time
from datetime import datetime

class WebhookSender:
    def __init__(self, config_file='webhook_config.json'):
        with open(config_file, 'r') as f:
            self.config = json.load(f)
    
    def send_webhook(self, event_type, data):
        """Send webhook to all registered endpoints for this event"""
        webhooks = self.config.get('webhooks', [])
        
        for webhook in webhooks:
            if not webhook.get('active', False):
                continue
                
            if event_type in webhook.get('events', []):
                self._send_to_endpoint(webhook, event_type, data)
    
    def _send_to_endpoint(self, webhook, event_type, data):
        """Send webhook to specific endpoint with retry logic"""
        payload = {
            'event': event_type,
            'data': data,
            'timestamp': datetime.utcnow().isoformat(),
            'webhook_id': webhook['id']
        }
        
        headers = {
            'Content-Type': 'application/json',
            'User-Agent': 'LOMP-Stack-Webhook/1.0'
        }
        
        # Add signature if secret is provided
        if webhook.get('secret'):
            signature = self._generate_signature(json.dumps(payload), webhook['secret'])
            headers['X-Webhook-Signature'] = f'sha256={signature}'
        
        max_attempts = webhook.get('retry_attempts', 3)
        
        for attempt in range(max_attempts):
            try:
                response = requests.post(
                    webhook['url'],
                    json=payload,
                    headers=headers,
                    timeout=30
                )
                
                if response.status_code == 200:
                    print(f"Webhook sent successfully to {webhook['url']}")
                    break
                else:
                    print(f"Webhook failed with status {response.status_code}")
                    
            except Exception as e:
                print(f"Webhook attempt {attempt + 1} failed: {str(e)}")
                if attempt < max_attempts - 1:
                    time.sleep(2 ** attempt)  # Exponential backoff
    
    def _generate_signature(self, payload, secret):
        """Generate HMAC signature for webhook"""
        return hmac.new(
            secret.encode('utf-8'),
            payload.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 3:
        print("Usage: webhook_sender.py <event_type> <data_json>")
        sys.exit(1)
    
    event_type = sys.argv[1]
    data = json.loads(sys.argv[2])
    
    sender = WebhookSender()
    sender.send_webhook(event_type, data)
