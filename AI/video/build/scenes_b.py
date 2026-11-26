"""Scenes 5 to 7: algorithm, results, app."""

from __future__ import annotations

import math

from common import BLUE, CORAL, GREEN, INK, box, phone, r

GREY = "#9AA3B2"


def _curve(fn, x_max: float, width: float, height: float, steps: int = 40) -> str:
    points = []
    for i in range(steps + 1):
        x = x_max * i / steps
        points.append(f"{'M' if i == 0 else 'L'}{width * i / steps:.1f},{height * (1 - fn(x)):.1f}")
    return " ".join(points)


def algorithm(scene: dict, ctx: dict) -> tuple[str, str, str]:
    sid = "algorithm"
    p = ctx["metrics"]["params"]
    half, tau = p["half_life_days"], p["tau_hours"]
    decay = _curve(lambda a: 0.5 ** (a / half), 28, 560, 190)
    fading = _curve(lambda h: math.exp(-h / tau), 24, 560, 190)
    half_x = 560 * half / 28

    def chart(prefix: str, path: str, top: int, x_label: str, y_label: str) -> str:
        return (
            f'<svg class="abs" id="{sid}-{prefix}" style="left:560px;top:{top}px" width="620" height="250" viewBox="-30 -10 620 250">'
            f'<line x1="0" y1="190" x2="560" y2="190" stroke="{INK}" stroke-width="3"/><line x1="0" y1="0" x2="0" y2="190" stroke="{INK}" stroke-width="3"/>'
            f'<path id="{sid}-{prefix}-p" d="{path}" fill="none" stroke="{CORAL}" stroke-width="8" stroke-linecap="butt" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1"/>'
            f'<text x="560" y="232" text-anchor="end" font-size="28" fill="{INK}" font-family="Manrope">{x_label}</text>'
            f'<text x="8" y="26" font-size="28" fill="{INK}" font-family="Manrope">{y_label}</text></svg>'
        )

    body = f"""
    <div class="rule" style="left:96px;top:392px;width:1728px"></div>
    <div class="rule" style="left:96px;top:692px;width:1728px"></div>
    <div class="abs" id="{sid}-t1" style="left:96px;top:110px;width:440px"><div class="tag coral">Step one</div><div class="h2" style="font-size:54px;white-space:nowrap">The habit</div><div class="small" style="margin-top:14px">how often each hour of the week was home</div></div>
    {chart('c1', decay, 110, 'days ago, 0 to 28', 'weight')}
    <div class="abs" id="{sid}-half" style="left:{590 + half_x:.0f}px;top:104px;width:3px;height:200px;background:{INK};opacity:.5"></div>
    <div class="abs tag" id="{sid}-halfl" style="left:{604 + half_x:.0f}px;top:118px;white-space:nowrap">half weight at {half:.0f} days</div>
    <div class="abs" id="{sid}-halfn" style="left:1400px;top:120px;width:420px"><div class="num coral" style="font-size:110px">{half:.0f}</div><div class="small">days: an older reading counts half</div></div>
    <div class="abs" id="{sid}-t2" style="left:96px;top:420px;width:440px"><div class="tag coral">Step two</div><div class="h2" style="font-size:54px;white-space:nowrap">The present</div><div class="small" style="margin-top:14px">home or out right now</div></div>
    {chart('c2', fading, 410, 'hours ahead, 0 to 24', 'effect')}
    <div class="abs" id="{sid}-taul" style="left:1400px;top:420px;width:420px"><div class="num coral" style="font-size:110px">{tau:.0f}</div><div class="small">hours: how long the present lasts</div></div>
    <div class="abs" id="{sid}-t3" style="left:96px;top:722px;width:440px"><div class="tag coral">Step three</div><div class="h2" style="font-size:54px;white-space:nowrap">Combine</div></div>
    <div class="panel ink" id="{sid}-formula" style="left:560px;top:722px;width:1264px;height:150px;padding:22px 36px;font-family:Montserrat,sans-serif;font-weight:800;font-size:32px;line-height:1.4">forecast = sigmoid( b0 + b1 x logit(habit)<br>+ b2 x (2n - 1) x e^(-h / tau) )</div>
    <div class="abs" id="{sid}-b0" style="left:560px;top:900px;width:230px"><div class="num coral" style="font-size:60px" id="{sid}-b0n">0</div><div class="small">b0, the base</div></div>
    <div class="abs" id="{sid}-b1" style="left:810px;top:900px;width:230px"><div class="num coral" style="font-size:60px" id="{sid}-b1n">0</div><div class="small">b1, the habit</div></div>
    <div class="abs" id="{sid}-b2" style="left:1060px;top:900px;width:240px"><div class="num coral" style="font-size:60px" id="{sid}-b2n">0</div><div class="small">b2, the present</div></div>
    <div class="stamp" id="{sid}-whole" style="left:1330px;top:905px">The whole model</div>
    <div class="abs" id="{sid}-flat" style="left:96px;top:880px;width:440px"><div class="tag" style="white-space:nowrap">New person starts at</div><div class="num coral" style="font-size:52px">50%</div></div>"""
    js = f"""
    rise('#{sid}-t1', B.s1, 0.5);
    fade('#{sid}-c1', B.s1 + 0.2, 0.4);
    draw('#{sid}-c1-p', B.decay, 1.4);
    growY('#{sid}-half', B.half, 0.5);
    rise('#{sid}-halfl', B.half + 0.2, 0.4, 12);
    rise('#{sid}-halfn', B.half + 0.3, 0.5, 20);
    rise('#{sid}-t2', B.s2, 0.5);
    fade('#{sid}-c2', B.s2 + 0.2, 0.4);
    draw('#{sid}-c2-p', B.fade, 1.4);
    rise('#{sid}-taul', B.fade + 0.8, 0.4, 12);
    rise('#{sid}-t3', B.s3, 0.5);
    rise('#{sid}-formula', B.s3 + 0.3, 0.6, 30);
    rise('#{sid}-b0', B.weights, 0.4, 20);
    rise('#{sid}-b1', B.weights + 0.25, 0.4, 20);
    rise('#{sid}-b2', B.weights + 0.5, 0.4, 20);
    count('#{sid}-b0n', B.weights, {p['b0']}, 2);
    count('#{sid}-b1n', B.weights + 0.25, {p['b1']}, 2);
    count('#{sid}-b2n', B.weights + 0.5, {p['b2']}, 2);
    stamp('#{sid}-whole', B.whole, -3);
    rise('#{sid}-flat', B.flat, 0.5);"""
    return body, "", js


def results(scene: dict, ctx: dict) -> tuple[str, str, str]:
    sid = "results"
    m = ctx["metrics"]
    h3 = m["horizons"]["3"]
    bars = [("The model", h3["model"]["brier"], CORAL, "score"), ("Plain hour of week average", h3["slot_mean"]["brier"], INK, "base"),
            ("Same as right now", h3["persistence"]["brier"], INK, "lower"), ("Constant guess", h3["base_rate"]["brier"], INK, "lower")]
    scale = 480 / 0.16
    bar_html = []
    for i, (label, value, color, _) in enumerate(bars):
        top = 190 + i * 120
        bar_html.append(
            f'<div class="abs" id="{sid}-ba{i}" style="left:900px;top:{top}px;width:924px;height:96px">'
            f'<div class="abs small" style="left:0;top:28px;width:360px">{label}</div>'
            f'<div class="abs" id="{sid}-bar{i}" style="left:380px;top:12px;width:{value * scale:.0f}px;height:72px;background:{color};border-radius:12px"></div>'
            f'<div class="abs num" id="{sid}-bv{i}" style="left:{380 + value * scale + 18:.0f}px;top:22px;font-size:44px;color:{color}">0</div></div>'
        )
    # page B: Brier by horizon
    hs = ["1", "3", "6", "12", "24", "48", "72"]
    series = [("model", CORAL, 10), ("slot_mean", INK, 6), ("persistence", BLUE, 6), ("base_rate", GREY, 6)]
    lo, hi = 0.09, 0.16

    def pt(i: int, value: float) -> tuple[float, float]:
        return 70 + i * 125, 40 + (hi - value) / (hi - lo) * 520

    lines = []
    for name, color, width in series:
        coords = [pt(i, m["horizons"][h][name]["brier"]) for i, h in enumerate(hs)]
        d = " ".join(f"{'M' if i == 0 else 'L'}{x:.0f},{y:.0f}" for i, (x, y) in enumerate(coords))
        dots = "".join(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{width}" fill="{color}"/>' for x, y in coords)
        lines.append(f'<path id="{sid}-ln-{name}" d="{d}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="butt" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1"/>{dots}')
    xl = "".join(f'<text x="{70 + i * 125}" y="610" text-anchor="middle" font-size="28" fill="{INK}" font-family="Manrope">{h} h</text>' for i, h in enumerate(hs))
    legend = "".join(
        f'<div class="abs small" style="left:{900 + (i % 2) * 460}px;top:{760 + (i // 2) * 44}px;color:{c if c != GREY else BLUE}"><span style="display:inline-block;width:26px;height:8px;background:{c};margin-right:12px"></span>{t}</div>'
        for i, (t, c) in enumerate([("The model", CORAL), ("Plain average", INK), ("Same as right now", BLUE), ("Constant", GREY)])
    )
    auc6 = (m["horizons"]["6"]["slot_mean"]["auc"], m["horizons"]["6"]["model"]["auc"])
    auc24 = (m["horizons"]["24"]["slot_mean"]["auc"], m["horizons"]["24"]["model"]["auc"])
    # page C: learning curve
    lc = m["learning_curve"]
    days = ["3", "7", "14", "28"]
    lo2, hi2 = 0.6, 0.9

    def lp(i: int, value: float) -> tuple[float, float]:
        return 60 + i * 250, 20 + (hi2 - value) / (hi2 - lo2) * 300

    coords = [lp(i, lc[d]["auc"]) for i, d in enumerate(days)]
    path = " ".join(f"{'M' if i == 0 else 'L'}{x:.0f},{y:.0f}" for i, (x, y) in enumerate(coords))
    dots = "".join(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="9" fill="{CORAL}"/><text x="{x:.0f}" y="{y - 20:.0f}" text-anchor="middle" font-size="28" font-weight="800" fill="{INK}" font-family="Montserrat">{lc[d]["auc"]:.2f}</text>' for (x, y), d in zip(coords, days))
    xl2 = "".join(f'<text x="{60 + i * 250}" y="360" text-anchor="middle" font-size="28" fill="{INK}" font-family="Manrope">{d} days</text>' for i, d in enumerate(days))
    gbm, small = m["horizons"]["3"]["gbm"]["brier"], h3["model"]["brier"]
    prior_bad, prior_flat = m["cold_start"]["with_prior"]["brier"], m["cold_start"]["flat_prior"]["brier"]
    body = f"""
    <div class="abs h2" id="{sid}-h" style="left:96px;top:100px;width:740px">Does it work?</div>
    <div class="abs body" id="{sid}-test" style="left:96px;top:300px;width:700px;font-size:34px">Leave one home out. Forecast forward in time. Use only the past.</div>
    <div class="stamp ink" id="{sid}-lower" style="left:96px;top:520px">Lower is better</div>
    <div class="layer" id="{sid}-pa">{''.join(bar_html)}<div class="abs tag" style="left:900px;top:110px">Error score (Brier), 3 hours ahead</div></div>
    <div class="layer" id="{sid}-pb"><svg class="abs" style="left:900px;top:130px" width="924" height="640" viewBox="0 0 924 640">{''.join(lines)}{xl}</svg>{legend}
      <div class="abs tag" style="left:900px;top:90px">Error score by hours ahead, lower is better</div></div>
    <div class="panel" id="{sid}-rank" style="left:96px;top:620px;width:740px;height:300px;padding:30px 36px"><div class="tag coral">Ranking, AUC</div><div class="body" style="font-size:32px;margin-top:14px">From 6 hours ahead the plain average ranks slightly better.</div><div class="small" style="margin-top:14px">{auc6[0]:.3f} against {auc6[1]:.3f} at 6 hours, {auc24[0]:.3f} against {auc24[1]:.3f} at 24</div></div>
    <div class="layer" id="{sid}-pc">
      <div class="abs tag" style="left:900px;top:90px">Ranking score (AUC) by days of history</div>
      <svg class="abs" style="left:900px;top:130px" width="924" height="400" viewBox="0 0 924 400"><path id="{sid}-lc" d="{path}" fill="none" stroke="{CORAL}" stroke-width="8" stroke-linecap="butt" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1"/>{dots}{xl2}</svg>
      <div class="panel" id="{sid}-gbm" style="left:900px;top:590px;width:430px;height:250px;padding:24px 28px"><div class="tag">Gradient boosting</div><div class="num" style="font-size:56px;margin-top:10px">{gbm:.3f}</div><div class="small">vs {small:.3f} for the small model</div></div>
      <div class="panel" id="{sid}-prior" style="left:1394px;top:590px;width:430px;height:250px;padding:24px 28px"><div class="tag">First week, new home</div><div class="num coral" style="font-size:56px;margin-top:10px">{prior_bad:.3f}</div><div class="small">other homes' average, against {prior_flat:.3f} from 50%</div></div>
      <div class="stamp" id="{sid}-failed" style="left:1480px;top:860px">Failed</div>
    </div>"""
    js = f"""
    rise('#{sid}-h', 0.8, 0.5);
    rise('#{sid}-test', B.test, 0.5, 18);
    tl.set('#{sid}-pb,#{sid}-pc,#{sid}-rank', {{opacity:0}}, 0);
    fade('#{sid}-pa', B.score - 0.2, 0.4);
    growX('#{sid}-bar0', B.score, 0.8);  count('#{sid}-bv0', B.score, {bars[0][1]}, 3, 0.8);
    growX('#{sid}-bar1', B.base, 0.8);   count('#{sid}-bv1', B.base, {bars[1][1]}, 3, 0.8);
    stamp('#{sid}-lower', B.lower, -3);
    growX('#{sid}-bar2', B.lower + 0.3, 0.8); count('#{sid}-bv2', B.lower + 0.3, {bars[2][1]}, 3, 0.8);
    growX('#{sid}-bar3', B.lower + 0.6, 0.8); count('#{sid}-bv3', B.lower + 0.6, {bars[3][1]}, 3, 0.8);
    hide('#{sid}-pa', B.wins - 0.1, 0.3);
    fade('#{sid}-pb', B.wins, 0.4);
    ['base_rate', 'persistence', 'slot_mean', 'model'].forEach((n, i) => draw('#{sid}-ln-' + n, B.wins + 0.2 + i * 0.35, 1.0));
    rise('#{sid}-rank', B.rank, 0.5, 24);
    hide('#{sid}-pb,#{sid}-rank', B.weeks - 0.1, 0.3);
    fade('#{sid}-pc', B.weeks, 0.4);
    draw('#{sid}-lc', B.weeks + 0.2, 1.8);
    rise('#{sid}-gbm', B.gbm, 0.5, 24);
    rise('#{sid}-prior', B.failed - 0.3, 0.5, 24);
    stamp('#{sid}-failed', B.failed, -6);"""
    return body, "", js


def app(scene: dict, ctx: dict) -> tuple[str, str, str]:
    sid = "app"
    s = (460 - 20) / 780
    ph, scale = phone(sid, "phone", "parcels-mobile.png", 96, 54, 460,
                      box(sid, "hi", s, 74, 498, 632, 308))
    zs = 1.15
    zoom_w, zoom_h = round(632 * zs), round(308 * zs)

    def zbox(name: str, y0: int, y1: int) -> str:
        return f'<div class="abs" id="{sid}-{name}" style="left:6px;top:{round((y0 - 498) * zs)}px;width:{zoom_w - 12}px;height:{round((y1 - y0) * zs)}px;border:5px solid {CORAL};border-radius:12px"></div>'

    ph2, s2 = phone(sid, "sheet", "parcels-add-sheet.png", 1470, 110, 350, box(sid, "hiw", (350 - 20) / 780, 48, 1000, 684, 156))
    body = f"""
    <div class="abs tag coral" id="{sid}-live" style="left:640px;top:100px">The real Casama app, running in Chrome</div>
    {ph}
    <div class="abs" id="{sid}-zoom" style="left:640px;top:170px;width:{zoom_w}px;height:{zoom_h}px;border:2px solid {INK};border-radius:22px;overflow:hidden;background:url(assets/screens/parcels-mobile.png) {-round(74 * zs)}px {-round(498 * zs)}px/{round(780 * zs)}px auto no-repeat;box-shadow:10px 10px 0 rgba(27,42,74,.12)">
      {zbox('zr', 604, 672)}{zbox('za', 676, 742)}
    </div>
    <div class="panel ink" id="{sid}-dart" style="left:640px;top:530px;width:760px;height:270px;padding:28px 36px"><div class="tag" style="color:{CORAL}">Dart module in the app</div><div class="small" style="margin-top:14px;font-family:Montserrat,sans-serif;font-weight:800;font-size:28px;line-height:1.5">forecast_params<br>habit_profile<br>home_forecaster<br>arrival_advisor</div></div>
    <div class="stamp" id="{sid}-parity" style="left:640px;top:840px">Matches Python to 9 decimals</div>
    <div class="stamp ink" id="{sid}-advice" style="left:640px;top:945px">Advice only</div>
    {ph2}"""
    js = f"""
    rise('#{sid}-phone', B.real - 0.2, 0.7, 60);
    rise('#{sid}-live', B.real, 0.5, 14);
    fade('#{sid}-hi', B.card, 0.3);
    rise('#{sid}-zoom', B.card, 0.5, 30);
    fade('#{sid}-zr', B.reason, 0.3);
    fade('#{sid}-za', B.atleast, 0.3);
    tl.to('#{sid}-zr', {{opacity:0, duration:0.3}}, B.atleast);
    rise('#{sid}-sheet', B.window - 0.2, 0.6, 50);
    fade('#{sid}-hiw', B.window + 0.3, 0.3);
    rise('#{sid}-dart', B.dart, 0.5, 24);
    stamp('#{sid}-parity', B.parity, -3);
    stamp('#{sid}-advice', B.advice, 2);"""
    return body, "", js
