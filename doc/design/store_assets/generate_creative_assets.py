"""App Storeのクリエイティブアセット（プロダクトページヘッダー・検索結果）を生成する。

HTMLを組み立ててChromeのヘッドレスでPNGに書き出し、`fastlane/creative_assets/<ロケール>/`へ置く。
書き出したPNGは`sync-metadata.yml`がApp Store Connectへ同期する（ADR-0045）。

使い方（Google Chromeが必要）:
    python3 doc/design/store_assets/generate_creative_assets.py

形・文言を直すときはこのスクリプトを編集して流し直す。PNGを手で直すと次の生成で消える。
"""
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[3]
OUT = ROOT / "fastlane/creative_assets"
SVG = ROOT / "doc/design/renewal/character/svg"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# キーはApp Store Connectのロケール（fastlane/metadata配下のディレクトリ名と同じ）
COPY = {
    "ja": {
        "header": "がんばった家事が、ちゃんと伝わる。",
        "search": "家事のがんばりに、ありがとうを。",
        "praise": "やったね、洗濯おわり！",
        "thanksTitle": "ありがとうが届いたよ",
        "thanksMessage": "助かったよ",
        "today": "きょうの家事",
        "chores": [("洗濯", 20, True), ("食器洗い", 10, True), ("お風呂そうじ", 10, False), ("ゴミ出し", 5, False)],
        "font": '"Hiragino Sans", "Hiragino Kaku Gothic ProN", sans-serif',
    },
    "en-US": {
        "header": "Every chore, noticed.",
        "search": "Share chores. Share thanks.",
        "praise": "Yay, Laundry is done!",
        "thanksTitle": "Hana sent you thanks!",
        "thanksMessage": "That really helped!",
        "today": "Today's Chores",
        "chores": [("Laundry", 20, True), ("Wash Dishes", 10, True), ("Clean the Bath", 10, False), ("Take Out Trash", 5, False)],
        "font": '-apple-system, "SF Pro Rounded", "Helvetica Neue", sans-serif',
    },
}

BASE_CSS = """
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { width: %(w)dpx; height: %(h)dpx; overflow: hidden; }
body { background: #FBF8F2; font-family: %(font)s; color: #263328; position: relative; }
.blob { position: absolute; border-radius: 50%%; filter: blur(8px); }
.abs { position: absolute; }
.headline { position: absolute; left: 0; right: 0; text-align: center; font-weight: 800; letter-spacing: 0.02em; }
.card { background: #FFFFFF; border-radius: 72px; box-shadow: 0 24px 80px rgba(74, 59, 44, 0.12); }
.chip { display: inline-block; background: #FFEDC2; color: #8A5A00; font-weight: 800; border-radius: 999px; }
.bubble { background: #FFFFFF; border-radius: 999px; box-shadow: 0 24px 80px rgba(74, 59, 44, 0.12); font-weight: 600; white-space: nowrap; }
.heart { color: #EC7290; }
.sparkle { position: absolute; }
"""


def sparkle(x, y, size, color):
    return (f'<svg class="sparkle" style="left:{x}px;top:{y}px" width="{size}" height="{size}" viewBox="0 0 10 10">'
            f'<path d="M5 0 Q5.6 4.4 10 5 Q5.6 5.6 5 10 Q4.4 5.6 0 5 Q4.4 4.4 5 0Z" fill="{color}"/></svg>')


def heart_svg(size):
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24"><path fill="#EC7290" '
            'd="M12 21s-7.5-4.6-10-9.3C.3 8.3 2.4 4 6.4 4c2.3 0 3.9 1.3 5.6 3.3C13.7 5.3 15.3 4 17.6 4c4 0 6.1 4.3 4.4 7.7C19.5 16.4 12 21 12 21z"/></svg>')


def thanks_card(c, x, y, scale=1.0, right=None):
    s = lambda v: int(v * scale)
    pos = f"right:{right}px" if right is not None else f"left:{x}px"
    return f"""
<div class="card abs" style="{pos};top:{y}px;padding:{s(64)}px {s(80)}px;display:flex;gap:{s(48)}px;align-items:center">
  <div style="width:{s(200)}px;height:{s(200)}px;border-radius:50%;background:#FDE3EA;display:flex;align-items:center;justify-content:center">{heart_svg(s(120))}</div>
  <div>
    <div style="font-size:{s(84)}px;font-weight:800;white-space:nowrap">{c['thanksTitle']}</div>
    <div style="margin-top:{s(24)}px;display:inline-block;background:#E3F3E8;border-radius:{s(40)}px;padding:{s(20)}px {s(44)}px;font-size:{s(72)}px;color:#2A6A44;white-space:nowrap">{c['thanksMessage']}</div>
  </div>
</div>"""


def praise_bubble(c, x, y, scale=1.0, chip=True):
    s = lambda v: int(v * scale)
    chip_html = f'<span class="chip" style="font-size:{s(84)}px;padding:{s(14)}px {s(56)}px">+20pt</span>' if chip else ""
    return f"""
<div class="abs" style="left:{x}px;top:{y}px;text-align:center">
  {chip_html}
  <div class="bubble" style="margin-top:{s(36) if chip else 0}px;font-size:{s(88)}px;padding:{s(56)}px {s(96)}px">{c['praise']}</div>
</div>"""


def header_html(c):
    w, h = 3840, 1646
    homette_h = 900
    homette_w = int(homette_h * 240 / 256)
    body = f"""
<div class="blob" style="left:-260px;top:-380px;width:1300px;height:1300px;background:#F6C152;opacity:.22"></div>
<div class="blob" style="left:3040px;top:860px;width:1200px;height:1200px;background:#5DBB84;opacity:.18"></div>
<div class="blob" style="left:3100px;top:-260px;width:620px;height:620px;background:#F4A0B4;opacity:.20"></div>
<div class="blob" style="left:180px;top:1180px;width:560px;height:560px;background:#5DBB84;opacity:.12"></div>
<div class="headline" style="top:150px;font-size:136px">{c['header']}</div>
<img class="abs" src="{(SVG / 'homette_praise.svg').as_uri()}" style="left:{(w - homette_w) // 2}px;top:420px;height:{homette_h}px">
{praise_bubble(c, 260, 640)}
{thanks_card(c, 2340, 760, right=260)}
{sparkle(1180, 470, 90, '#F2B035')}{sparkle(2700, 520, 70, '#5DBB84')}{sparkle(1350, 1300, 60, '#EC7290')}{sparkle(2440, 1360, 80, '#F2B035')}
"""
    return w, h, body


def search_html(c):
    w, h = 3840, 2560
    rows = ""
    for name, pt, done in c["chores"]:
        mark = ('<div style="width:96px;height:96px;border-radius:50%;background:#2A8454;display:flex;align-items:center;justify-content:center">'
                '<svg width="56" height="56" viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" stroke="#fff" stroke-width="3.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg></div>'
                if done else '<div style="width:96px;height:96px;border-radius:50%;border:8px solid #2A8454"></div>')
        style = "text-decoration:line-through;color:#66736A" if done else ""
        chip_bg = "#FFEDC2" if done else "#FFF6E0"
        rows += f"""
<div style="display:flex;align-items:center;gap:48px;padding:40px 0">
  {mark}
  <div style="flex:1;font-size:84px;{style};white-space:nowrap">{name}</div>
  <span class="chip" style="font-size:72px;padding:10px 44px;background:{chip_bg}">{'+' if done else ''}{pt}pt</span>
</div>"""
    done_count = sum(1 for _, _, d in c["chores"] if d)
    total = len(c["chores"])
    homette_h = 1000
    homette_w = int(homette_h * 240 / 256)
    body = f"""
<div class="blob" style="left:-300px;top:-300px;width:1400px;height:1400px;background:#F6C152;opacity:.20"></div>
<div class="blob" style="left:2900px;top:1700px;width:1400px;height:1400px;background:#5DBB84;opacity:.18"></div>
<div class="blob" style="left:3200px;top:-200px;width:700px;height:700px;background:#F4A0B4;opacity:.18"></div>
<div class="headline" style="top:170px;font-size:150px">{c['search']}</div>
<div class="card abs" style="left:360px;top:560px;width:1640px;padding:96px 110px">
  <div style="display:flex;align-items:baseline;justify-content:space-between">
    <div style="font-size:96px;font-weight:800">{c['today']}</div>
    <div style="font-size:160px;font-weight:800">{done_count}<span style="font-size:96px;color:#66736A">/{total}</span></div>
  </div>
  <div style="margin:40px 0 24px;height:40px;border-radius:20px;background:#E3F3E8;overflow:hidden">
    <div style="width:{done_count / total * 100}%;height:100%;background:#2A8454;border-radius:20px"></div>
  </div>
  {rows}
</div>
<img class="abs" src="{(SVG / 'homette_praise.svg').as_uri()}" style="left:{2280 + (1200 - homette_w) // 2}px;top:560px;height:{homette_h}px">
{praise_bubble(c, 2180, 1660, 0.95, chip=False).replace('text-align:center', 'text-align:center;width:1400px')}
{thanks_card(c, 0, 1990, 0.9, right=360)}
{sparkle(2250, 640, 100, '#F2B035')}{sparkle(3420, 760, 80, '#5DBB84')}{sparkle(3500, 1420, 70, '#EC7290')}
"""
    return w, h, body


def render(path, w, h, body, font, work_dir):
    html = f'<!doctype html><html><head><meta charset="utf-8"><style>{BASE_CSS % {"w": w, "h": h, "font": font}}</style></head><body>{body}</body></html>'
    html_path = work_dir / f"{path.parent.name}_{path.stem}.html"
    html_path.write_text(html, encoding="utf-8")
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([CHROME, "--headless=new", f"--screenshot={path}", f"--window-size={w},{h}",
                    "--hide-scrollbars", "--force-device-scale-factor=1", "--default-background-color=FBF8F2FF",
                    "--allow-file-access-from-files", html_path.as_uri()],
                   check=True, capture_output=True)
    print(path.relative_to(ROOT))


# ファイル名はApp Store Connectの配置（placementType）と対応する。scripts/appstoreconnect.sh の creative-assets sync 参照
with tempfile.TemporaryDirectory() as tmp:
    for locale, c in COPY.items():
        w, h, body = header_html(c)
        render(OUT / locale / "product_page_header.png", w, h, body, c["font"], pathlib.Path(tmp))
        w, h, body = search_html(c)
        render(OUT / locale / "search_results.png", w, h, body, c["font"], pathlib.Path(tmp))
