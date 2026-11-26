"""Scenes 8 to 10: privacy, limits, credits."""

from __future__ import annotations

from common import BLUE, CORAL, GREEN, INK, box, phone, r

NAMES = ["Theodore Von Joshua M. Bunquin", "Christian B. Nayre", "Daniel B. Villanueva", "John C. Alcaraz", "Paul C. Alcaraz"]


def privacy(scene: dict, ctx: dict) -> tuple[str, str, str]:
    sid = "privacy"
    s = (360 - 20) / 780
    ph1, _ = phone(sid, "ph1", "settings-switch.png", 96, 110, 360, box(sid, "hi1", s, 40, 1332, 700, 196))
    ph2, _ = phone(sid, "ph2", "privacy-tab.png", 500, 110, 360, box(sid, "hi2", s, 40, 648, 700, 552))
    items = [
        ("off", "Off by default for every member"),
        ("taps", "Learns only from Home and Out taps"),
        ("device", "Runs on the device, no location"),
        ("deletes", "Switching it off deletes what Cas learned"),
        ("demo", "Demo household: pre opted in, and we say so"),
    ]
    rows = []
    for i, (key, text) in enumerate(items):
        top = 400 + i * 118
        rows.append(
            f'<div class="rule" style="left:960px;top:{top}px;width:864px"></div>'
            f'<div class="abs" id="{sid}-i-{key}" style="left:960px;top:{top + 2}px;width:864px;height:114px;display:flex;align-items:center;font-size:38px"><span class="num coral" style="font-size:44px;margin-right:24px">+</span>{text}</div>'
        )
    body = f"""
    <div class="abs h2" id="{sid}-h" style="left:960px;top:100px;width:864px">Why so careful?</div>
    <div class="abs body" id="{sid}-sens" style="left:960px;top:250px;width:864px;font-size:34px">Used badly, a routine tells someone when a home is empty.</div>
    {ph1}{ph2}
    {''.join(rows)}"""
    js = f"""
    rise('#{sid}-h', 0.8, 0.5);
    rise('#{sid}-sens', B.sensitive - 0.3, 0.5, 18);
    rise('#{sid}-ph1', B.off - 0.3, 0.6, 50);
    fade('#{sid}-hi1', B.off + 0.2, 0.3);
    rise('#{sid}-i-off', B.off, 0.45, 18);
    rise('#{sid}-i-taps', B.taps, 0.45, 18);
    rise('#{sid}-ph2', B.taps + 0.2, 0.6, 50);
    fade('#{sid}-hi2', B.taps + 0.8, 0.3);
    rise('#{sid}-i-device', B.device, 0.45, 18);
    rise('#{sid}-i-deletes', B.deletes, 0.45, 18);
    rise('#{sid}-i-demo', B.demo, 0.45, 18);"""
    return body, "", js


def limits(scene: dict, ctx: dict) -> tuple[str, str, str]:
    sid = "limits"
    cal = ctx["metrics"]["calibration"]
    bins = []
    for i, c in enumerate(cal[:10]):
        x = 96 + i * 82
        hp, ho = c["predicted"] * 400, c["observed"] * 400
        bins.append(
            f'<div class="abs {sid}-bin" style="left:{x}px;top:640px;width:70px;height:0">'
            f'<div class="abs" style="left:0;top:{-hp:.0f}px;width:32px;height:{hp:.0f}px;background:{INK};border-radius:6px 6px 0 0"></div>'
            f'<div class="abs" style="left:36px;top:{-ho:.0f}px;width:32px;height:{ho:.0f}px;background:{CORAL};border-radius:6px 6px 0 0"></div>'
            f'<div class="abs small" style="left:0;top:14px;width:70px;text-align:center;font-size:28px">{round(c["bin_low"] * 100)}</div></div>'
        )
    low0, low1 = round(cal[0]["observed"] * 100), round(cal[1]["observed"] * 100)
    items = [("indep", "Someone is home assumes housemates are independent"), ("untested", "Ranking and window were not tested separately"), ("reset", "History lives in memory and resets on restart")]
    rows = []
    for i, (key, text) in enumerate(items):
        top = 250 + i * 150
        rows.append(
            f'<div class="rule" style="left:960px;top:{top}px;width:864px"></div>'
            f'<div class="abs" id="{sid}-i-{key}" style="left:960px;top:{top + 2}px;width:864px;height:146px;display:flex;align-items:center;font-size:38px;line-height:1.25">{text}</div>'
        )
    body = f"""
    <div class="abs h2" id="{sid}-h" style="left:96px;top:100px;width:860px;font-size:62px;white-space:nowrap">What it cannot do</div>
    <div class="abs tag" style="left:96px;top:200px">Said, in percent (dark), and was home (coral)</div>
    <div class="rule" style="left:90px;top:640px;width:830px;background:{INK}"></div>
    {''.join(bins)}
    <div class="abs" id="{sid}-ring" style="left:84px;top:508px;width:172px;height:176px;border:5px dashed {CORAL};border-radius:18px"></div>
    <div class="abs body" id="{sid}-over" style="left:96px;top:740px;width:830px;font-size:34px">When it said under 20 percent, the person was home {low0} to {low1} percent of the time.</div>
    {''.join(rows)}
    <div class="stamp" id="{sid}-fil" style="left:960px;top:760px;white-space:normal;width:864px;text-align:center;line-height:1.3">Not tested with real Filipino housemates</div>"""
    js = f"""
    rise('#{sid}-h', 0.8, 0.5);
    tl.fromTo('.{sid}-bin', {{opacity:0}}, {{opacity:1, duration:0.4, stagger:0.06}}, 1.2);
    fade('#{sid}-ring', B.over, 0.3);
    rise('#{sid}-over', B.over, 0.5, 18);
    rise('#{sid}-i-indep', B.indep, 0.45, 18);
    rise('#{sid}-i-untested', B.untested, 0.45, 18);
    rise('#{sid}-i-reset', B.reset, 0.45, 18);
    stamp('#{sid}-fil', B.filipino, -2);"""
    return body, "", js


def credits(scene: dict, ctx: dict) -> tuple[str, str, str]:
    sid = "credits"
    names = "".join(
        f'<div class="abs num credits-name" style="left:96px;top:{300 + i * 78}px;font-size:40px;white-space:nowrap">{n}</div>' for i, n in enumerate(NAMES)
    )
    body = f"""
    <div class="abs h2" id="{sid}-g" style="left:96px;top:110px;width:800px">Group Theoraux</div>
    <div class="abs tag coral" id="{sid}-gl" style="left:96px;top:230px">Made by</div>
    {names}
    <div class="abs" id="{sid}-data" style="left:1010px;top:130px;width:814px"><div class="tag coral">Data</div><div class="body" style="font-size:34px;margin-top:8px">CASAS smart home dataset, Diane Cook and colleagues, Washington State University</div></div>
    <div class="stamp" id="{sid}-lic" style="left:1010px;top:340px">CC BY 4.0</div>
    <div class="abs" id="{sid}-tools" style="left:1010px;top:480px;width:814px"><div class="tag coral">Made with</div><div class="body" style="font-size:34px;margin-top:8px">Flutter and Dart, scikit-learn, Kokoro for the voice, HyperFrames for the picture</div></div>
    <div class="panel ink" id="{sid}-refs" style="left:1010px;top:690px;width:814px;height:150px;padding:30px 40px"><div class="tag" style="color:{CORAL}">References</div><div class="num" style="font-size:40px;margin-top:12px">AI/REFERENCES.md</div></div>
    <div class="abs h1 coral" id="{sid}-thanks" style="left:1010px;top:890px">Thank you</div>"""
    js = f"""
    rise('#{sid}-g', B.group - 0.2, 0.5);
    rise('#{sid}-gl', B.group, 0.4, 12);
    tl.fromTo('.credits-name', {{opacity:0, y:20}}, {{opacity:1, y:0, duration:0.45, ease:'power3.out', stagger:0.18}}, B.group + 0.3);
    rise('#{sid}-data', B.casas - 0.2, 0.5);
    stamp('#{sid}-lic', B.licence, -3);
    rise('#{sid}-tools', B.licence + 1.2, 0.5);
    rise('#{sid}-refs', B.refs, 0.5, 24);
    rise('#{sid}-thanks', B.thanks, 0.6, 30);"""
    return body, "", js
