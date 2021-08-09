import requests

CITY = 'Milan'

w = requests.get(f'https://wttr.in/{CITY}?format=j1')
print(w.json())
