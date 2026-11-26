"""Shared pieces of the HyperFrames scenes: the look (see hyperframes/SPEC.md), GSAP helpers and the scene wrapper."""

from __future__ import annotations

import json

W, H = 1920, 1080
CREAM, INK, CORAL, BLUE, GREEN = "#FFF8F1", "#1B2A4A", "#E8776A", "#4F6580", "#2E7D32"

COMMON_CSS = """
@font-face{font-family:'Josefin Sans';font-weight:300;src:url('assets/fonts/JosefinSans.woff2') format('woff2');}
@font-face{font-family:'Manrope';font-weight:500;src:url('assets/fonts/Manrope.woff2') format('woff2');}
#root{position:absolute;inset:0;background:#FFF8F1;color:#1B2A4A;font-family:'Manrope',sans-serif;font-weight:500;overflow:hidden}
#root *{box-sizing:border-box}
.abs{position:absolute}
.layer{position:absolute;left:0;top:0;width:1920px;height:1080px}
.h1{font-family:'Josefin Sans',sans-serif;font-weight:300;text-transform:uppercase;letter-spacing:.06em;line-height:1.06;font-size:112px;white-space:nowrap}
.h2{font-family:'Josefin Sans',sans-serif;font-weight:300;text-transform:uppercase;letter-spacing:.06em;line-height:1.1;font-size:68px}
.num{font-family:'Montserrat',sans-serif;font-weight:800;letter-spacing:-.02em;line-height:1}
.coral{color:#C0503F}
.body{font-size:36px;line-height:1.35}
.small{font-size:30px;line-height:1.3}
.panel{position:absolute;background:#fff;border:2px solid #1B2A4A;border-radius:28px;box-shadow:10px 10px 0 rgba(27,42,74,.12)}
.ink{background:#1B2A4A;color:#FFF8F1}
.stamp{position:absolute;border:5px solid #E8776A;color:#C0503F;border-radius:14px;padding:10px 28px;font-family:'Montserrat',sans-serif;font-weight:800;font-size:40px;letter-spacing:.05em;text-transform:uppercase;white-space:nowrap;background:#FFF8F1}
.stamp.ink{border-color:#1B2A4A;color:#1B2A4A}
.phone{position:absolute;border:10px solid #1B2A4A;border-radius:46px;overflow:hidden;background:#FFF8F1;box-shadow:10px 10px 0 rgba(27,42,74,.12)}
.phone img{display:block;width:100%}
.wipe{position:absolute;left:0;top:0;width:1920px;height:1080px;background:#E8776A}
.rule{position:absolute;height:2px;background:#1B2A4A}
.row{position:absolute;display:flex;align-items:center;font-size:36px}
.tag{font-family:'Montserrat',sans-serif;font-weight:800;font-size:28px;letter-spacing:.06em;text-transform:uppercase}
"""

JS_HELPERS = """
const tl = gsap.timeline({paused:true});
const rise = (sel, t, d = 0.5, y = 28) => tl.fromTo(sel, {opacity:0, y:y}, {opacity:1, y:0, duration:d, ease:'power3.out'}, t);
const fade = (sel, t, d = 0.4) => tl.fromTo(sel, {opacity:0}, {opacity:1, duration:d, ease:'power1.out'}, t);
const hide = (sel, t, d = 0.35) => tl.to(sel, {opacity:0, duration:d, ease:'power1.in'}, t);
const stamp = (sel, t, rot = -3) => tl.fromTo(sel, {opacity:0, scale:1.6, rotation:rot * 2.5}, {opacity:1, scale:1, rotation:rot, duration:0.35, ease:'back.out(2)'}, t);
const growY = (sel, t, d = 0.8) => tl.fromTo(sel, {scaleY:0, transformOrigin:'50% 100%'}, {scaleY:1, transformOrigin:'50% 100%', duration:d, ease:'power2.out'}, t);
const growX = (sel, t, d = 0.8) => tl.fromTo(sel, {scaleX:0, transformOrigin:'0% 50%'}, {scaleX:1, transformOrigin:'0% 50%', duration:d, ease:'power2.out'}, t);
const draw = (sel, t, d = 1.0) => tl.fromTo(sel, {strokeDashoffset:1}, {strokeDashoffset:0, duration:d, ease:'power1.inOut'}, t);
const count = (sel, t, to, dec = 2, d = 0.9) => { const o = {v:0}; tl.to(o, {v:to, duration:d, ease:'power2.out', onUpdate(){ document.querySelector(sel).textContent = o.v.toFixed(dec); }}, t); };
const wipe = (sel) => tl.fromTo(sel, {xPercent:0}, {xPercent:101, duration:0.55, ease:'power3.inOut'}, 0);
"""


def scene_file(scene: dict, body: str, css: str, js: str, first: bool = False) -> str:
    """One scene as a sub composition file: styles, markup and script inside <template> (HyperFrames contract)."""
    sid = scene["id"]
    beats = {key: beat["at"] for key, beat in scene["beats"].items()}
    wipe_div = "" if first else f'<div class="wipe" data-layout-allow-overflow id="{sid}-wipe"></div>'
    wipe_js = "" if first else f"wipe('#{sid}-wipe');"
    progress_from, progress_len = scene["lead"], max(scene["duration"] - scene["lead"] - 1.2, 1.0)
    return f"""<template>
  <style>
{COMMON_CSS}
{css}
  </style>
  <div id="root" data-composition-id="{sid}" data-width="{W}" data-height="{H}">
<div class="layer" id="{sid}-stage">
{body}
    </div>
    <div class="abs" data-layout-ignore style="left:96px;top:1040px;width:1728px;height:6px;background:rgba(27,42,74,.12);border-radius:3px"></div>
    <div class="abs" data-layout-ignore id="{sid}-prog" style="left:96px;top:1040px;width:1728px;height:6px;background:#E8776A;border-radius:3px"></div>
    {wipe_div}
  </div>
  <script>
    const B = {json.dumps(beats)};
{JS_HELPERS}
    {wipe_js}
    tl.fromTo('#{sid}-stage', {{scale:1, transformOrigin:'35% 45%'}}, {{scale:1.035, transformOrigin:'35% 45%', duration:{progress_len + 1.0:.2f}, ease:'none'}}, {progress_from - 0.4});
    tl.fromTo('#{sid}-prog', {{scaleX:0, transformOrigin:'0% 50%'}}, {{scaleX:1, transformOrigin:'0% 50%', duration:{progress_len:.2f}, ease:'none'}}, {progress_from});
{js}
    window.__timelines["{sid}"] = tl;
  </script>
</template>
"""


def r(value: float, places: int = 2) -> str:
    return f"{value:.{places}f}"


def phone(sid: str, name: str, src: str, left: int, top: int, width: int, extra: str = "") -> tuple[str, float]:
    """A phone frame holding a real screenshot (780 x 1688 px). Returns the markup and the scale of image pixels."""
    inner = width - 20
    height = round(inner * 1688 / 780) + 20
    html = (
        f'<div class="phone" id="{sid}-{name}" style="left:{left}px;top:{top}px;width:{width}px;height:{height}px">'
        f'<img src="assets/screens/{src}" alt="">{extra}</div>'
    )
    return html, inner / 780


def box(sid: str, name: str, scale: float, x: int, y: int, w: int, h: int, color: str = CORAL) -> str:
    """A highlight outline over a part of a screenshot, in screenshot pixels (780 x 1688)."""
    return (
        f'<div class="abs" id="{sid}-{name}" style="left:{round(x * scale)}px;top:{round(y * scale)}px;'
        f'width:{round(w * scale)}px;height:{round(h * scale)}px;border:5px solid {color};border-radius:16px"></div>'
    )
