"""Exit 0 for the bank app, 1 for no listener, 2 for another service."""
import sys
from urllib.error import HTTPError, URLError
from urllib.request import urlopen

try:
    with urlopen('http://127.0.0.1:8080', timeout=3) as response:
        page = response.read(200000).decode('utf-8', errors='replace')
except HTTPError:
    sys.exit(2)
except (URLError, TimeoutError):
    sys.exit(1)
sys.exit(0 if '<title>Faisal App</title>' in page else 2)
