"""Scenes 1 to 4: title, problem, idea, data."""

from __future__ import annotations

from common import BLUE, CORAL, GREEN, INK, box, phone, r


def title(scene: dict, ctx: dict) -> tuple[str, str, str]:
    sid = "title"
    phone_html, _ = phone(sid, "phone", "parcels-mobile.png", 1240, 54, 460)
    body = f"""
    <div class="abs h1" id="{sid}-l1" style="left:96px;top:110px">Casama</div>
    <div class="abs h1" id="{sid}-l2" style="left:96px;top:236px">Home</div>
    <div class="abs h1 coral" id="{sid}-l3" style="left:96px;top:362px">Forecast</div>
    <div class="abs body" id="{sid}-sub" style="left:96px;top:560px;width:980px">An AI final project: <span style="position:relative;display:inline-block">who is probably home<span class="abs" id="{sid}-under" style="left:0;bottom:-6px;height:6px;width:100%;background:{CORAL}"></span></span> when your parcel arrives.</div>
    <div class="stamp" id="{sid}-group" style="left:96px;top:760px">Group Theoraux</div>
    <div class="panel ink" id="{sid}-honest" style="left:96px;top:890px;width:1010px;height:108px;padding:28px 36px;font-size:36px">Measured on real data, including what failed.</div>
    {phone_html}"""
    js = f"""
    tl.fromTo('#{sid}-phone', {{y:70}}, {{y:0, duration:0.8, ease:'power3.out'}}, 0);
    ['#{sid}-l1', '#{sid}-l2', '#{sid}-l3'].forEach((s, i) => rise(s, B.name + i * 0.14, 0.55));
    rise('#{sid}-sub', B.skill - 0.2, 0.5);
    growX('#{sid}-under', B.skill + 0.2, 0.6);
    stamp('#{sid}-group', B.group, -3);
    rise('#{sid}-honest', B.honest, 0.5);"""
    return body, "", js


def problem(scene: dict, ctx: dict) -> tuple[str, str, str]:
    sid = "problem"
    k = 0.9  # display pixels per screenshot pixel; the card is 630 px wide
    slice_a = f'<div class="abs" style="left:0;top:0;width:630px;height:225px;background:url(assets/screens/parcels-mobile.png) -36px -223px/702px auto no-repeat"></div>'
    slice_b = f'<div class="abs" style="left:0;top:225px;width:630px;height:128px;background:url(assets/screens/parcels-mobile.png) -36px -725px/702px auto no-repeat"></div>'
    body = f"""
    <div class="abs h2" id="{sid}-h" style="left:96px;top:100px;width:760px">The parcel board</div>
    <div class="abs" id="{sid}-card" style="left:96px;top:290px;width:630px;height:353px;overflow:hidden;border-radius:22px;border:2px solid {INK};background:#fff;box-shadow:10px 10px 0 rgba(27,42,74,.12)">{slice_a}{slice_b}</div>
    <div class="abs" id="{sid}-ring" style="left:90px;top:557px;width:170px;height:62px;border:5px solid {CORAL};border-radius:31px"></div>
    <div class="abs small coral" id="{sid}-taps" style="left:96px;top:658px;width:520px">everyone taps available</div>
    <div class="stamp" id="{sid}-late" style="left:440px;top:712px">Too late</div>
    <div class="abs body" id="{sid}-text" style="left:96px;top:810px;width:780px;font-size:32px">The warning that nobody can receive the parcel comes only after everyone has said unavailable. Nothing tells the buyer, ahead of time, who is likely to be home.</div>
    <div class="panel ink" id="{sid}-q1" style="left:930px;top:150px;width:894px;height:290px;padding:44px 52px"><div class="h2">Who is likely to be home?</div><div class="small" style="margin-top:22px;opacity:.8">when a parcel is expected</div></div>
    <div class="panel" id="{sid}-q2" style="left:930px;top:520px;width:894px;height:290px;padding:44px 52px"><div class="h2 coral">Which window is the safest?</div><div class="small" style="margin-top:22px;opacity:.8">for the courier to ring</div></div>"""
    js = f"""
    rise('#{sid}-h', 0.8, 0.5);
    rise('#{sid}-card', B.board, 0.6, 50);
    fade('#{sid}-ring', B.taps, 0.3);
    tl.fromTo('#{sid}-ring', {{scale:1.25}}, {{scale:1, duration:0.4, ease:'back.out(2)'}}, B.taps);
    rise('#{sid}-taps', B.taps + 0.2, 0.4, 14);
    stamp('#{sid}-late', B.warning, -4);
    rise('#{sid}-text', B.warning + 0.4, 0.5);
    rise('#{sid}-q1', B.question, 0.55, 40);
    rise('#{sid}-q2', B.window, 0.55, 40);"""
    return body, "", js


def idea(scene: dict, ctx: dict) -> tuple[str, str, str]:
    sid = "idea"
    grid = ctx["grid"]  # 168 habit values, slot = weekday * 24 + hour
    cells = []
    for slot, value in enumerate(grid):
        day, hour = divmod(slot, 24)
        alpha = max(0.06, round(value, 2))
        cells.append(
            f'<div class="abs {sid}-cell" style="left:{1010 + day * 108}px;top:{100 + hour * 36}px;width:102px;height:32px;border:2px solid rgba(27,42,74,.22);border-radius:6px">'
            f'<div class="abs {sid}-fill" style="inset:0;background:rgba(232,119,106,{alpha});border-radius:4px"></div></div>'
        )
    days = "".join(
        f'<div class="abs tag" style="left:{1010 + i * 108}px;top:58px;width:102px;text-align:center">{d}</div>' for i, d in enumerate(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
    )
    hours = "".join(f'<div class="abs small" style="left:930px;top:{98 + h * 36}px;width:70px;text-align:right">{h:02d}</div>' for h in (0, 6, 12, 18))
    thursday = 1010 + 3 * 108
    body = f"""
    <div class="abs h2" id="{sid}-h" style="left:96px;top:100px;width:780px">A forecast is a probability</div>
    <div class="panel" id="{sid}-ex" style="left:96px;top:400px;width:780px;height:290px;padding:34px 40px">
      <div class="tag coral">Thursday, 2 PM</div>
      <div style="display:flex;gap:26px;margin-top:22px">
        <div class="abs-ok" id="{sid}-w1" style="width:130px;height:96px;border-radius:18px;background:{GREEN};color:#fff;display:flex;align-items:center;justify-content:center;font-size:30px">home</div>
        <div id="{sid}-w2" style="width:130px;height:96px;border-radius:18px;background:{GREEN};color:#fff;display:flex;align-items:center;justify-content:center;font-size:30px">home</div>
        <div id="{sid}-w3" style="width:130px;height:96px;border-radius:18px;background:{GREEN};color:#fff;display:flex;align-items:center;justify-content:center;font-size:30px">home</div>
      </div>
      <div class="body" id="{sid}-so" style="margin-top:20px;font-size:32px">so this Thursday: probably home</div>
    </div>
    <div class="abs small" id="{sid}-stack" style="left:96px;top:740px;width:780px">
      <div class="tag">Older weeks count less</div>
      <div style="display:flex;gap:18px;margin-top:16px;align-items:flex-end">
        <div id="{sid}-s1" style="width:150px;height:130px;background:{INK};border-radius:14px;opacity:1"></div>
        <div id="{sid}-s2" style="width:150px;height:130px;background:{INK};border-radius:14px;opacity:.55"></div>
        <div id="{sid}-s3" style="width:150px;height:130px;background:{INK};border-radius:14px;opacity:.25"></div>
        <div class="small" style="width:260px;padding-left:10px">this week, last week, three weeks ago</div>
      </div>
    </div>
    <div class="layer" id="{sid}-grid">{days}{hours}{''.join(cells)}</div>
    <div class="abs" id="{sid}-ring" style="left:{thursday - 4}px;top:{100 + 14 * 36 - 4}px;width:110px;height:40px;border:6px solid {INK};border-radius:10px"></div>
    <div class="abs tag coral" id="{sid}-cap" style="left:1010px;top:984px;width:760px;text-align:center;font-size:28px">168 slots, one for every hour of the week</div>"""
    js = f"""
    rise('#{sid}-h', B.forecast, 0.5);
    tl.fromTo('.{sid}-cell', {{opacity:0}}, {{opacity:1, duration:0.2, stagger:{{each:0.0045, from:'start'}}}}, B.slots);
    fade('#{sid}-cap', B.slots + 0.4, 0.4);
    tl.set('.{sid}-fill', {{opacity:0}}, 0);
    fade('#{sid}-ring', B.alex, 0.3);
    tl.fromTo('#{sid}-ring', {{scale:1.5}}, {{scale:1, duration:0.4, ease:'back.out(2)'}}, B.alex);
    rise('#{sid}-ex', B.alex - 0.2, 0.5);
    ['#{sid}-w1', '#{sid}-w2', '#{sid}-w3'].forEach((s, i) => stamp(s, B.alex + 0.5 + i * 0.5, 0));
    rise('#{sid}-so', B.alex + 2.2, 0.5, 14);
    rise('#{sid}-stack', B.recent, 0.5);
    tl.fromTo('.{sid}-fill', {{opacity:0}}, {{opacity:1, duration:0.5, stagger:{{each:0.006, from:'start'}}}}, B.habit);"""
    return body, "", js


def data(scene: dict, ctx: dict) -> tuple[str, str, str]:
    sid = "data"
    homes = {h["id"]: h for h in ctx["metrics"]["data"]}
    rows = [
        ("Aruba", "aruba", "leave and return", True),
        ("Cairo", None, "leave only", False),
        ("Milan", None, "leave only", False),
        ("Tulum 1", "tulum1", "leave and return", True),
        ("Tulum 2", "tulum2", "leave and return", True),
    ]
    table = []
    for i, (name, key, labels, used) in enumerate(rows):
        top = 100 + i * 96
        days = f"{homes[key]['days']} days" if key else ""
        table.append(
            f'<div class="abs" id="{sid}-r{i}" style="left:900px;top:{top}px;width:924px;height:84px">'
            f'<div class="abs" id="{sid}-bar{i}" style="left:0;top:0;width:924px;height:84px;border-radius:16px;background:{GREEN if used else "#E7E1DA"};opacity:{0.14 if used else 1}"></div>'
            f'<div class="abs num" style="left:28px;top:22px;font-size:38px">{name}</div>'
            f'<div class="abs body" style="left:270px;top:20px;font-size:32px;white-space:nowrap">{days}</div>'
            f'<div class="abs small" style="left:500px;top:24px;white-space:nowrap">{labels}</div>'
            f'<div class="abs tag" style="left:770px;top:26px;white-space:nowrap;color:{GREEN if used else BLUE}">{"used" if used else "left out"}</div>'
            f'<div class="abs" id="{sid}-x{i}" style="left:20px;top:41px;width:884px;height:4px;background:{INK};display:{"none" if used else "block"}"></div>'
            "</div>"
        )
    strip = "".join(
        f'<div class="abs" style="left:{900 + i * 38.5}px;top:700px;width:35px;height:56px;border-radius:6px;background:{INK if home else "#E7E1DA"}"></div>'
        for i, home in enumerate(ctx["aruba_day"])
    )
    body = f"""
    <div class="abs h2" id="{sid}-h" style="left:96px;top:100px;width:740px">Real homes, real labels</div>
    <div class="abs body" id="{sid}-src" style="left:96px;top:300px;width:740px;font-size:32px">CASAS smart home dataset, Washington State University. CC BY 4.0.</div>
    <div class="stamp" id="{sid}-gate" style="left:96px;top:520px">Gate passed</div>
    <div class="stamp ink" id="{sid}-few" style="left:96px;top:660px">Only 3 homes</div>
    <div class="stamp ink" id="{sid}-notfil" style="left:96px;top:800px">Not Filipino homes</div>
    {''.join(table)}
    <div class="abs tag" id="{sid}-stripl" style="left:900px;top:650px">One day in Aruba, hour by hour</div>
    <div id="{sid}-strip">{strip}</div>
    <div class="abs small coral" id="{sid}-out" style="left:900px;top:772px;width:400px">Leave_Home 09:52</div>
    <div class="abs small" id="{sid}-in" style="left:1260px;top:772px;width:400px;color:{GREEN}">Enter_Home 12:10</div>"""
    js = f"""
    rise('#{sid}-h', 0.8, 0.5);
    rise('#{sid}-src', B.casas, 0.5, 18);
    ['#{sid}-r0', '#{sid}-r1', '#{sid}-r2', '#{sid}-r3', '#{sid}-r4'].forEach((s, i) => rise(s, B.casas + 0.3 + i * 0.12, 0.45, 20));
    fade('#{sid}-stripl', B.labels, 0.4);
    tl.fromTo('#{sid}-strip', {{opacity:0}}, {{opacity:1, duration:0.6}}, B.labels);
    rise('#{sid}-out', B.labels + 0.8, 0.4, 12);
    rise('#{sid}-in', B.labels + 1.6, 0.4, 12);
    tl.to('#{sid}-bar0,#{sid}-bar3,#{sid}-bar4', {{opacity:0.34, duration:0.4}}, B.three);
    growX('#{sid}-x1', B.left, 0.5);
    growX('#{sid}-x2', B.left + 0.2, 0.5);
    tl.to('#{sid}-r1,#{sid}-r2', {{opacity:0.4, duration:0.4}}, B.left + 0.5);
    stamp('#{sid}-gate', B.gate, -3);
    stamp('#{sid}-few', B.few, 2);
    stamp('#{sid}-notfil', B.notfil, -2);"""
    return body, "", js
