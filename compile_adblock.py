import urllib.request
import json

print("Downloading Ad Lists...")
easylist_url = "https://easylist.to/easylist/easylist.txt"
ru_adlist_url = "https://easylist-downloads.adblockplus.org/advblock.txt"

def fetch_lines(url):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            return response.read().decode('utf-8').split('\n')
    except Exception as e:
        print(f"Error fetching {url}: {e}")
        return []

lines = fetch_lines(ru_adlist_url) + fetch_lines(easylist_url)

rules = []

for line in lines:
    line = line.strip()
    if not line or line.startswith('!'): continue
    
    # Отключил сборку CSS правил, потому что в EasyList есть универсальные плохие селекторы типа ##.root
    # которые тупо прячут весь сайт Твича (потому что он собран на React и использует #root div)
    
    # Network blocking: ||example.com^
    if line.startswith('||') and '^' in line:
        domain = line[2:].split('^')[0]
        if '/' not in domain and '*' not in domain:
            if 'twitch' in domain or 'ttvnw' in domain or 'jtv' in domain:
                continue
            rules.append({
                "trigger": {
                    "url-filter": f".*{domain.replace('.', '\\\\.')}.*",
                    "unless-domain": ["twitch.tv", "ttvnw.net", "jtvnw.net", "ext-twitch.tv"] # Twitch breaks natively without proxy, so leave it excluded, but let everything apply to Rezka
                },
                "action": {"type": "block"}
            })

    if len(rules) > 30000: # Apple limit is 50,000, keep it fast
        break

# Add explicit hardcore blocks for HD Rezka & RU Casino
hardcore_css = ".ad-slot, .ad-container, .brand-link, .promo-brand, .b-top-banner, .b-post__promoblock, .video-ad, .teaser, .branding"
rules.append({
    "trigger": {"url-filter": ".*"},
    "action": {"type": "css-display-none", "selector": hardcore_css}
})

out_path = "adblock_rules.json"
with open(out_path, 'w') as f:
    json.dump(rules, f)

print(f"Compiled {len(rules)} Native WebKit rules to {out_path}!")
