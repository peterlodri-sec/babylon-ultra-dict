#!/usr/bin/env python3
"""Generate BABYLON-ultra-dict GitHub Pages landing page."""
import json
from pathlib import Path
from datetime import datetime

OUT = Path("/Users/lodripeter/workspace/peterlodri-sec/babylon-ultra-dict/pages/index.html")
OUT.parent.mkdir(exist_ok=True)

LEXICON = [
    ("Vakkantás — Riadó",    "Valaki jön. Figyelek. Biztonságban vagy.", "Someone comes. I watch. You are safe."),
    ("Vakkantás — Riadó",    "Idegen a kapunál. Mögém. Védlek.", "Stranger at the gate. Behind me. I guard."),
    ("Vakkantás — Riadó",    "Látom. Fal vagyok. Senki át nem jut.", "I see. I am the wall. None pass."),
    ("Vakkantás — Riadó",    "Fülem ég. Szemem célon. Kész. Te pihenj.", "Ears up. Eyes locked. Ready. You rest."),
    ("Vakkantás — Riadó",    "Mozgás elöl. Jelzem. Ne félj.", "Movement ahead. I signal. Fear not."),
    ("Vakkantás — Riadó",    "Ismeretlen szag. Nem a falka. Riadó.", "Unknown scent. Not pack. Alert."),
    ("Vakkantás — Riadó",    "Postás. Minden nap. Győzök.", "Mailman. Every day. I win."),
    ("Vakkantás — Riadó",    "Hallom a lépteit. Közeledik. Készülj.", "I hear steps. Approaching. Prepare."),
    ("Morgás — Éberség",     "Hallok valamit. Maradj közel. Vigyázok.", "I hear something. Stay close. I guard."),
    ("Morgás — Éberség",     "Neszez a messzi. Megjegyzem. Aludj.", "A rustle far. I note it. Sleep on."),
    ("Morgás — Éberség",     "Az éj beszél. Csenddel felelek.", "The night speaks. I answer silent."),
    ("Morgás — Éberség",     "Körbejártam. Minden rendben. Tiszta.", "I circled. All clear. Clean sweep."),
    ("Morgás — Éberség",     "Motor zúg. Nem veszély. Csak zaj.", "Engine hums. Not threat. Just noise."),
    ("Morgás — Éberség",     "Macska a kerítésen. Jelentem. Üldözzem?", "Cat on fence. I report. Do I chase?"),
    ("Morgás — Éberség",     "Szomszéd kint. Ismerem. Nem ellenség.", "Neighbor outside. I know him. Not foe."),
    ("Morgás — Éberség",     "Eső kopog. Tetőn. Hangos. Figyelek.", "Rain taps. On roof. Loud. I listen."),
    ("Lélegzet — Nyugalom",  "Minden rendben. A ház csendes. Pihenj.", "All is well. The house is quiet. Rest."),
    ("Lélegzet — Nyugalom",  "Szél az udvarban. Madár a fán. Béke.", "Wind in yard. Bird in tree. Peace."),
    ("Lélegzet — Nyugalom",  "Szíved lassú. Enyém ráhangol. Pihenünk.", "Your heart slow. Mine syncs. We rest."),
    ("Lélegzet — Nyugalom",  "Biztos zóna. Nulla veszély. Végtelen nyugalom.", "Safe zone. Zero threat. Infinite calm."),
    ("Lélegzet — Nyugalom",  "Nap meleg. Padlón fekszem. Jó.", "Sun warm. I lie on floor. Good."),
    ("Lélegzet — Nyugalom",  "Óra ketyeg. Lélegzet ritmus. Együtt.", "Clock ticks. Breath rhythm. Together."),
    ("Lélegzet — Nyugalom",  "Semmi mozgás. Semmi hang. Tökéletes.", "No movement. No sound. Perfect."),
    ("Lélegzet — Nyugalom",  "Szemed csukva. Én nyitva. Őrzöm álmod.", "Your eyes closed. Mine open. I guard your dream."),
    ("Nyüszítés — Aggodalom", "Valami nincs rendben. Nézd az ajtót. A rést is.", "Something wrong. Check the door. The gap too."),
    ("Nyüszítés — Aggodalom", "Nyugtalan vagyok. Levegő változott. Hátsó kapu.", "I am uneasy. Air changed. Back gate."),
    ("Nyüszítés — Aggodalom", "Árnyék mozdult. Nem szél. Nem madár. Nem ember.", "Shadow moved. Not wind. Not bird. Not human."),
    ("Nyüszítés — Aggodalom", "Gyomrom mondja: baj. Orrom semmit. Nyüszítek.", "My gut says: trouble. My nose: nothing. I whine."),
    ("Nyüszítés — Aggodalom", "Túl csendes. Gyanús. Ellenőrizzük.", "Too quiet. Suspicious. Let us check."),
    ("Nyüszítés — Aggodalom", "Vihar jön. Érzem a levegőben. Menjünk be.", "Storm coming. I smell it in the air. Go inside."),
    ("Nyüszítés — Aggodalom", "Fáj valamim. Mancsom. Nézd meg kérlek.", "Something hurts. My paw. Please look."),
    ("Nyüszítés — Aggodalom", "Egyedül hagytál. Sokáig. Hiányoztál.", "You left me alone. So long. I missed you."),
    ("Csendes figyelem — Jelenlét", "Itt vagyok. Itt vagy. Ez elég.", "I am here. You are here. Enough."),
    ("Csendes figyelem — Jelenlét", "Nem kell szó. Fejem öledben. Örökké.", "No words needed. My head on your knee. Forever."),
    ("Csendes figyelem — Jelenlét", "Nap elmozdult. Követtem. A folt meleg.", "Sun moved. I followed. The patch is warm now."),
    ("Csendes figyelem — Jelenlét", "Te lélegzel. Én lélegzem. A ház lélegzik. Egy.", "You breathe. I breathe. The house breathes. One."),
    ("Csendes figyelem — Jelenlét", "Mancsom a lábadon. Súly. Jelenlét. Szeretet.", "My paw on your foot. Weight. Presence. Love."),
    ("Csendes figyelem — Jelenlét", "Farok csóvál. Nem tudom miért. Csak.", "Tail wags. I do not know why. Just because."),
    ("Csendes figyelem — Jelenlét", "Nézel rám. Én vissza. Ennyi elég.", "You look at me. I look back. This is enough."),
    ("Csendes figyelem — Jelenlét", "Kezdődik az este. Melléd fekszem. Veled alszom.", "Evening begins. I lie beside you. I sleep with you."),
]

rows = "\n".join(
    f"""            <tr class="lex-row">
                <td class="sound">🎙️ {s}</td>
                <td class="hu">{h}</td>
                <td class="en">{e}</td>
            </tr>"""
    for s, h, e in LEXICON
)

HTML = f"""<!DOCTYPE html>
<html lang="hu">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>BABYLON-ultra-dict — Marley Dog→Human Quant Translator</title>
<style>
:root {{ --bg: #0a0a0f; --fg: #e0e0e0; --cyan: #00e5ff; --green: #00ff88; --yellow: #ffcc00; --orange: #ff6b35; }}
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{ background: var(--bg); color: var(--fg); font-family: ui-monospace, 'SF Mono', Menlo, monospace; line-height: 1.6; }}
.hero {{ text-align: center; padding: 80px 20px 40px; }}
.hero h1 {{ font-size: 3rem; font-weight: 900; color: #fff; text-shadow: 0 0 40px var(--cyan); }}
.hero .sub {{ font-size: 1.2rem; color: var(--cyan); opacity: 0.7; margin-top: 12px; }}
.badge {{ display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 0.8rem; margin: 4px; border: 1px solid; }}
.badge-hu {{ border-color: var(--green); color: var(--green); }}
.badge-en {{ border-color: var(--cyan); color: var(--cyan); }}
.badge-dict {{ border-color: var(--yellow); color: var(--yellow); }}
.stats {{ display: flex; justify-content: center; gap: 32px; padding: 20px; flex-wrap: wrap; }}
.stat {{ text-align: center; }}
.stat .num {{ font-size: 2rem; font-weight: 900; color: var(--cyan); }}
.stat .label {{ font-size: 0.8rem; opacity: 0.5; }}
.lexicon {{ max-width: 1000px; margin: 0 auto; padding: 20px; }}
.lexicon h2 {{ color: var(--cyan); font-size: 1.5rem; margin: 32px 0 16px; text-align: center; }}
table {{ width: 100%; border-collapse: collapse; font-size: 0.85rem; }}
th {{ text-align: left; padding: 10px 12px; border-bottom: 2px solid var(--cyan); color: var(--cyan); font-size: 0.75rem; text-transform: uppercase; letter-spacing: 1px; }}
td {{ padding: 10px 12px; border-bottom: 1px solid rgba(255,255,255,0.05); }}
.sound {{ color: var(--yellow); white-space: nowrap; font-weight: 600; }}
.hu {{ color: #fff; }}
.en {{ color: rgba(255,255,255,0.5); font-style: italic; }}
.lex-row:hover {{ background: rgba(0,229,255,0.04); }}
.pipeline {{ max-width: 800px; margin: 40px auto; padding: 20px; text-align: center; }}
.pipeline h2 {{ color: var(--cyan); margin-bottom: 16px; }}
.flow {{ display: flex; justify-content: center; gap: 8px; flex-wrap: wrap; font-size: 0.8rem; align-items: center; }}
.flow span {{ padding: 6px 12px; border-radius: 8px; background: rgba(0,229,255,0.08); border: 1px solid rgba(0,229,255,0.2); }}
.flow .arrow {{ background: none; border: none; color: var(--cyan); font-size: 1.2rem; }}
.footer {{ text-align: center; padding: 40px 20px; opacity: 0.3; font-size: 0.7rem; }}
.footer a {{ color: var(--cyan); }}
</style>
</head>
<body>

<div class="hero">
    <h1>BABYLON-ultra-dict</h1>
    <p class="sub">Marley · kutya → ember · folyamatos élő kvant fordítás</p>
    <p class="sub" style="font-size:0.9rem;opacity:0.5">continuous live dog→human quant translation · OM MANI PADME HUNG</p>
    <p style="margin-top:20px">
        <span class="badge badge-hu">🇭🇺 magyar</span>
        <span class="badge badge-en">🇬🇧 english</span>
        <span class="badge badge-dict">📖 40 phrases</span>
    </p>
</div>

<div class="stats">
    <div class="stat"><div class="num">40</div><div class="label">lexicon entries</div></div>
    <div class="stat"><div class="num">5</div><div class="label">sound types</div></div>
    <div class="stat"><div class="num">2</div><div class="label">languages</div></div>
    <div class="stat"><div class="num">16</div><div class="label">ternarity dims</div></div>
    <div class="stat"><div class="num">42</div><div class="label">ms think tick</div></div>
</div>

<div class="pipeline">
    <h2>♾️ Quant Pipeline</h2>
    <div class="flow">
        <span>🎤 mic</span><span class="arrow">→</span>
        <span>📷 camera</span><span class="arrow">→</span>
        <span>🐕 dog detect</span><span class="arrow">→</span>
        <span>👁 eye seed</span><span class="arrow">→</span>
        <span>🎵 music.vaked.dev</span><span class="arrow">→</span>
        <span>🔢 Xoshiro128**</span><span class="arrow">→</span>
        <span>👶 babyDrift</span><span class="arrow">→</span>
        <span>🔊 hu-HU TTS</span><span class="arrow">→</span>
        <span>🔊 en-US TTS</span>
    </div>
</div>

<div class="lexicon">
    <h2>📖 BABYLON Lexicon — 40 Bilingual Dog→Human Phrases</h2>
    <table>
        <thead>
            <tr><th>Sound</th><th>Magyar</th><th>English</th></tr>
        </thead>
        <tbody>
{rows}
        </tbody>
    </table>
</div>

<div class="footer">
    <p>BABYLON-ultra-dict · <a href="https://github.com/peterlodri-sec/babylon-ultra-dict">github.com/peterlodri-sec/babylon-ultra-dict</a></p>
    <p>Made in Hungary · PEACE )( LOVE () UNITY &lt;3</p>
    <p>Generated {datetime.now().strftime('%Y-%m-%d %H:%M')} UTC</p>
</div>

</body>
</html>"""

OUT.write_text(HTML)
print(f"Pages written: {OUT} ({len(LEXICON)} entries)")
