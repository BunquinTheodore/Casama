"""Build the presentation dashboard (one self contained HTML file).
Run after eda_delivery.py and late_model.py: python analysis/build_dashboard.py
"""

from __future__ import annotations

import base64
import json
from html import escape
from pathlib import Path

OUT = Path(__file__).resolve().parent / "output"


def image(name: str, alt: str) -> str:
    data = base64.b64encode((OUT / f"{name}.png").read_bytes()).decode()
    return f'<img src="data:image/png;base64,{data}" alt="{escape(alt)}">'


def month_name(period: str) -> str:
    """'2018-03' becomes 'March 2018' so labels never break at a hyphen."""
    year, month = period.split("-")
    names = ["January", "February", "March", "April", "May", "June", "July",
             "August", "September", "October", "November", "December"]
    return f"{names[int(month) - 1]} {year}"


def stat(value: str, label: str) -> str:
    return f'<div class="stat"><div class="num">{escape(value)}</div><div class="lbl">{escape(label)}</div></div>'


def finding(name: str, alt: str, takeaway: str, tone: str) -> str:
    return (
        f'<article class="finding {tone}"><div class="chart">{image(name, alt)}</div>'
        f'<p class="take">{takeaway}</p></article>'
    )


CSS = """
:root{--ink:#0a0a0a;--paper:#fff;--mid:#6b6b6b;--rule:#d9d9d9;--accent:#e4572e}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Manrope',system-ui,sans-serif;color:var(--ink);background:var(--paper);line-height:1.6}
h1,h2,.eyebrow,.lbl{font-family:'Josefin Sans',sans-serif;font-weight:300;text-transform:uppercase}
section{padding:96px 8vw}
section.dark{background:var(--ink);color:var(--paper)}
.eyebrow{font-size:13px;letter-spacing:.32em;color:var(--mid);margin-bottom:20px}
.dark .eyebrow{color:#9a9a9a}
h1{font-family:'Poppins',sans-serif;font-weight:600;text-transform:uppercase;font-size:clamp(20px,5.2vw,84px);letter-spacing:.02em;line-height:1.14}
h1 span{display:block;white-space:nowrap;text-align:left}
section img{max-width:100%;height:auto}
.dark img{outline:2px solid #fff;outline-offset:6px}
.num{white-space:nowrap}
h2{font-size:clamp(28px,4.2vw,52px);letter-spacing:.12em;margin-bottom:40px;line-height:1.15}
.lead{max-width:62ch;font-size:19px;color:var(--mid);margin-top:28px}
.dark .lead{color:#bdbdbd}
.hero-lead{max-width:none;text-wrap:balance}
@media(min-width:900px){h2.one-line{white-space:nowrap;font-size:clamp(28px,3.4vw,52px);letter-spacing:.1em}}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));margin-top:56px;border-top:1px solid currentColor}
.stat{padding:28px 24px 28px 0;border-bottom:1px solid var(--rule)}
.num{font-family:'Josefin Sans',sans-serif;font-weight:300;font-size:clamp(34px,4.4vw,56px);letter-spacing:.04em}
.lbl{font-size:12px;letter-spacing:.24em;color:var(--mid)}
.dark .lbl{color:#9a9a9a}
.findings{display:grid;gap:64px}
.finding{display:grid;grid-template-columns:1.5fr 1fr;gap:48px;align-items:center;border-top:1px solid var(--rule);padding-top:40px}
.finding img{width:100%;height:auto;display:block}
.take{font-size:20px;max-width:34ch}
.take b{background:var(--ink);color:var(--paper);padding:0 6px}
.dark .take b{background:var(--paper);color:var(--ink)}
.compare{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:32px;margin-top:40px}
.card{border:1px solid #444;padding:32px}
.card h3{font-family:'Josefin Sans',sans-serif;font-weight:300;text-transform:uppercase;letter-spacing:.2em;font-size:15px;margin-bottom:16px}
.card .big{font-size:48px;font-family:'Josefin Sans',sans-serif;font-weight:300}
.card p{color:#bdbdbd;margin-top:8px}
table{width:100%;border-collapse:collapse;margin-top:32px}
td,th{text-align:left;padding:18px 12px 18px 0;border-top:1px solid var(--rule);vertical-align:top}
th{font-family:'Josefin Sans',sans-serif;font-weight:300;text-transform:uppercase;letter-spacing:.2em;font-size:12px;color:var(--mid)}
.limits li{margin:0 0 14px 20px;max-width:70ch}
.steps{display:grid;grid-template-columns:repeat(6,1fr);gap:0 24px;border-top:1px solid var(--ink)}
.step{padding:28px 0 32px;border-bottom:1px solid var(--rule);min-width:0}
@media(max-width:1100px){.steps{grid-template-columns:repeat(3,1fr)}}
@media(max-width:620px){.steps{grid-template-columns:1fr}}
.step .n{font-family:'Josefin Sans',sans-serif;font-weight:300;font-size:44px;color:var(--mid)}
.step h3{font-family:'Josefin Sans',sans-serif;font-weight:300;text-transform:uppercase;letter-spacing:.2em;font-size:15px;margin:8px 0 10px}
.step p{color:var(--mid);font-size:15px;line-height:1.55}
.step h3{letter-spacing:.14em}
.pair{display:grid;grid-template-columns:1fr 1.4fr;gap:32px;margin-top:48px}
.pair img{width:100%;height:auto;background:#fff}
.learned{list-style:none;counter-reset:l;max-width:75ch}
.learned li{counter-increment:l;padding:22px 0 22px 64px;border-top:1px solid var(--rule);position:relative;font-size:18px}
.learned li::before{content:counter(l,decimal-leading-zero);position:absolute;left:0;font-family:'Josefin Sans',sans-serif;font-weight:300;font-size:30px;color:var(--mid)}
@media(max-width:820px){.pair{grid-template-columns:1fr}}
.sub{font-family:'Josefin Sans',sans-serif;font-weight:300;text-transform:uppercase;letter-spacing:.2em;font-size:15px;color:var(--mid);margin:56px 0 24px}
.questions{display:grid;grid-template-columns:repeat(5,1fr);gap:20px}
@media(max-width:1200px){.questions{grid-template-columns:repeat(2,1fr)}}
@media(max-width:620px){.questions{grid-template-columns:1fr}}
.q{border:1.5px solid var(--ink);padding:28px 22px;font-size:18px;line-height:1.4}
.q::before{content:"\\201C";display:block;font-family:'Poppins',sans-serif;font-size:44px;line-height:.6;margin-bottom:14px}
.scenario{list-style:none;counter-reset:s;max-width:78ch;border-left:1.5px solid var(--ink)}
.scenario li{counter-increment:s;padding:6px 0 22px 32px;position:relative;font-size:18px}
.scenario li::before{content:counter(s);position:absolute;left:-15px;top:4px;width:28px;height:28px;border-radius:50%;background:var(--ink);color:var(--paper);font-size:13px;text-align:center;line-height:28px}
.voices{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px}
.voice{border:1.5px solid var(--ink);padding:28px 24px}
.voice blockquote{font-size:19px;line-height:1.5}
.voice figcaption{margin-top:14px;color:var(--mid);font-size:14px}
.source{margin-top:48px;color:var(--mid);font-size:13px}
.glossary{border-bottom:1px solid var(--rule)}
.term{display:grid;grid-template-columns:minmax(200px,1fr) 2.4fr;gap:32px;padding:22px 0;border-top:1px solid var(--rule)}
.term dt{font-family:'Josefin Sans',sans-serif;font-weight:300;text-transform:uppercase;letter-spacing:.14em;font-size:15px}
.term dd{color:var(--mid);max-width:80ch}
@media(max-width:700px){.term{grid-template-columns:1fr;gap:6px}}
footer a{color:var(--ink);text-decoration:underline;text-underline-offset:3px}
footer{padding:48px 8vw;color:var(--mid);font-size:13px}
@media(max-width:820px){.finding{grid-template-columns:1fr}section{padding:64px 6vw}}
"""


def build() -> str:
    f = json.loads((OUT / "findings.json").read_text(encoding="utf-8"))
    m = json.loads((OUT / "model_metrics.json").read_text(encoding="utf-8"))
    x = json.loads((OUT / "extra_findings.json").read_text(encoding="utf-8"))
    s1, s2 = m["stage_1_at_purchase"], m["stage_2_after_shipping"]
    lift = s2["alert_precision_pct"] / s2["base_late_rate_pct"]

    process = "".join(
        f'<div class="step"><div class="n">{n}</div><h3>{title}</h3><p>{body}</p></div>'
        for n, title, body in [
            ("01", "Ask", "Can we tell early which parcels will be late, so housemates can plan who receives them."),
            ("02", "Collect", f"Downloaded {f['raw_orders']:,} real orders from Kaggle. Eight columns, all timestamps and a status."),
            ("03", "Clean", f"Kept delivered orders with a date, removed impossible durations and extremes. "
                            f"{x['kept_pct']}% of all orders survived."),
            ("04", "Explore", "Charted delivery time, lateness, seasons, seller speed and promised windows."),
            ("05", "Model", "Trained on 2017 and tested on 2018, so the model is judged on months it never saw."),
            ("06", "Apply", "Turned each finding into a Casama parcel board feature."),
        ]
    )

    more = "".join(
        [
            finding("09_volume_vs_late", "Monthly orders and late rate",
                    f"Volume and lateness rise together (correlation <b>{x['volume_late_correlation']}</b>). "
                    "Busy months overload sellers and carriers.", "light"),
            finding("10_delivery_spread", "Delivery time spread by seller speed",
                    f"A fast seller means a median of <b>{x['median_total_days_fast_seller']} days</b> in total. "
                    f"A seller who takes 7+ days to ship means <b>{x['median_total_days_slow_seller']} days</b>.",
                    "light"),
            finding("11_promise_vs_actual", "Promised versus actual days",
                    "The dark mass sits below the line: most parcels beat the promise. The thin cloud above "
                    "the line is the late 8%.", "light"),
            finding("12_correlation", "Correlation heatmap",
                    f"Seller handoff days link most to lateness (<b>{x['corr_handoff_late']}</b>). "
                    f"The promised window links weakly (<b>{x['corr_promised_late']}</b>). Hour and weekday "
                    "barely matter.", "light"),
        ]
    )

    questions = "".join(
        f"<blockquote class='q'>{escape(text)}</blockquote>"
        for text in [
            "Is anyone home right now?",
            "Can someone receive my Shopee or Lazada parcel?",
            "Who has the extension cord?",
            "Did anyone buy drinking water?",
            "The faucet is leaking. Who reports it?",
        ]
    )
    scenario = "".join(
        f"<li><b>{escape(head)}</b> {escape(body)}</li>"
        for head, body in [
            ("A parcel is on the way.",
             "A housemate logs it with the courier and the expected arrival. It is cash on delivery."),
            ("Everyone is asked.",
             "Housemates are marked available by default and tap unavailable if they will be out all day."),
            ("A conflict is spotted.",
             "If every housemate is unavailable, the buyer gets an alert and can plan a backup."),
            ("Someone receives it.",
             "A housemate claims it, pays the courier (paluwal, or spot me) and the app records who owes what."),
            ("Where the data helps.",
             "If the parcel is likely to be late or early, the app can ask for availability sooner."),
        ]
    )
    quotes_file = OUT.parent / "qualitative.json"
    quotes = json.loads(quotes_file.read_text(encoding="utf-8")) if quotes_file.exists() else []
    voices = ""
    voices_note = ""
    if quotes:
        cards = "".join(
            f"<figure class='voice'><blockquote>{escape(q['quote'])}</blockquote>"
            f"<figcaption>{escape(q.get('who', 'Housemate'))}</figcaption></figure>"
            for q in quotes
        )
        voices = f'<h3 class="sub">In their words</h3><div class="voices">{cards}</div>'
        voices_note = " Quotes are from our own interviews."

    glossary = "".join(
        f"<div class='term'><dt>{escape(term)}</dt><dd>{meaning}</dd></div>"
        for term, meaning in [
            ("AUC (Area Under the Curve)",
             "A score from 0.5 to 1 for how well the model ranks parcels from safe to risky. Pick one late and one "
             "on time parcel at random: AUC is the chance the model gave the late one the higher risk. 0.5 is a "
             "coin flip and 1.0 is perfect."),
            ("Base rate",
             f"The share of all parcels that are late, with no model involved. In the 2018 test data it is "
             f"{s2['base_late_rate_pct']}%."),
            ("COD (Cash on Delivery)",
             "Paying the courier in cash when the parcel arrives. In Casama a housemate may need to front this cash."),
            ("Correlation",
             "A number from -1 to 1 showing how closely two measures move together. 0 means no link, and values "
             "near 1 or -1 mean a strong link. A link does not prove one thing causes the other."),
            ("Decile",
             "One tenth of the parcels. We rank parcels by predicted risk and split them into ten equal groups, "
             "where 1 is the safest and 10 is the riskiest."),
            ("EDA (Exploratory Data Analysis)",
             "Looking at the data with summaries and charts before modelling, to find patterns, errors and "
             "questions worth asking."),
            ("Estimated delivery date", "The date promised to the customer when the order was placed."),
            ("Gradient boosting",
             "A prediction method that builds many small decision trees one after another, where each new tree "
             "corrects the mistakes of the ones before it."),
            ("Late parcel", "A parcel delivered after its estimated delivery date."),
            ("Lift",
             "How many times more often the flagged parcels are late than an average parcel. A lift of 2 means "
             "twice as often."),
            ("Mean and median",
             "The mean is the average. The median is the middle value when everything is sorted, so a few very "
             "slow parcels do not distort it."),
            ("Model",
             "A program that learns patterns from past orders and uses them to estimate whether a new parcel "
             "will be late."),
            ("Outlier", "An extreme value, such as a delivery that took 200 days. We removed these before analysis."),
            ("Permutation importance",
             "A way to see which signals the model relies on. Shuffle one signal and measure how much the "
             "model's accuracy drops. A bigger drop means a more important signal."),
            ("Precision",
             "Of the parcels the alert flags, the share that really are late."),
            ("Recall",
             "Of all the parcels that really are late, the share the alert catches."),
            ("ROC curve (Receiver Operating Characteristic)",
             "A chart of the share of late parcels caught against the share of on time parcels wrongly flagged, "
             "as the alert threshold changes. The area under it is the AUC."),
            ("Seller handoff days",
             "The days between the purchase and the seller giving the parcel to the carrier."),
            ("Signal (feature)",
             "A measured fact the model can use, such as the promised days or the seller handoff days."),
            ("Time based split",
             "Training the model on older orders (2017) and testing it on newer ones (2018), so it is judged "
             "on months it never saw. A random split would look better but be less honest."),
        ]
    )

    learned = "".join(
        f"<li><b>{title}</b> {body}</li>"
        for title, body in [
            ("The seller matters more than the courier.",
             f"Handoff time was the strongest signal ({f['late_pct_slow_handoff']:.0f}% late when slow)."),
            ("Averages hide the risk.",
             f"The median parcel is {f['median_days_early']:.0f} days early, yet some months hit "
             f"{f['worst_month_late_pct']:.0f}% late."),
            ("Time of day and weekday do not predict lateness.",
             "We tested them and they added almost nothing, which saved us from a false story."),
            ("Predicting lateness is hard.",
             f"Even with the best signal, AUC reached {s2['roc_auc']}. Honest results beat impressive ones."),
            ("Split by time, not at random.",
             "A random split would have looked better and been less honest about future months."),
        ]
    )

    findings = "".join(
        [
            finding("01_delivery_time", "Distribution of delivery time",
                    f"Half of all parcels arrive within <b>{f['median_days']} days</b>. One in ten takes "
                    f"more than {f['p90_days']} days.", "light"),
            finding("02_estimate_gap", "Delivered versus estimated date",
                    f"Estimates are padded. Only <b>{f['late_rate_pct']}%</b> arrive late and the typical "
                    f"parcel lands {f['median_days_early']:.0f} days before the promise.", "light"),
            finding("03_late_by_month", "Late rate by month",
                    f"Lateness is not constant. <b>{month_name(f['worst_month'])}</b> hit "
                    f"{f['worst_month_late_pct']:.0f}% late, against {f['best_month_late_pct']:.0f}% in "
                    "the calmest month.", "light"),
            finding("04_late_by_handoff", "Late rate by seller handoff time",
                    f"The best early warning is the seller. When shipping takes 7+ days, "
                    f"<b>{f['late_pct_slow_handoff']:.0f}%</b> of parcels are late, versus "
                    f"{f['late_pct_fast_handoff']:.0f}% when it ships within a day.", "light"),
            finding("05_late_by_estimate", "Late rate by promised window",
                    f"Short promises break most: <b>{f['late_pct_shortest_promise']:.0f}%</b> late when "
                    f"under 10 days were promised, versus {f['late_pct_longest_promise']:.0f}% for 30+ days.",
                    "light"),
            finding("06_order_rhythm", "Orders by weekday and hour",
                    "Orders cluster in the afternoon. Parcels bought then often arrive while housemates "
                    "are at class or work.", "light"),
        ]
    )

    return f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Casama delivery analytics</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Josefin+Sans:wght@300&family=Manrope:wght@400;600&family=Poppins:wght@600&display=swap" rel="stylesheet">
<style>{CSS}</style></head><body>

<section class="dark"><div class="eyebrow">CASAMA DATA SCIENCE</div>
<h1><span>Will anyone be</span><span>home when it arrives</span></h1>
<p class="lead hero-lead">Casama helps housemates coordinate parcels. This analysis studies {f['raw_orders']:,}
real online orders to learn when parcels are late, so the app can warn housemates earlier.</p>
<div class="stats">{stat(f"{f['delivered_orders_used']:,}", "Delivered orders analysed")}
{stat(f"{f['median_days']} days", "Median delivery time")}
{stat(f"{f['late_rate_pct']}%", "Arrive after the estimate")}
{stat(f"{f['worst_month_late_pct']:.0f}%", f"Late in the worst month, {month_name(f['worst_month'])}")}</div></section>

<section><div class="eyebrow">THE PROBLEM</div><h2>Parcels arrive when nobody is in</h2>
<p class="lead">In a shared home, a missed delivery means a failed attempt, a trip to the courier, or a
cash on delivery payment nobody can cover. If Casama knows a parcel is likely to be late or early,
housemates can plan who receives it.</p></section>

<section><div class="eyebrow">CONTEXT</div><h2>Life in a shared home</h2>
<p class="lead">Casama is for people who share a living space: college students in dorms, young professionals
renting a condo, and families coordinating errands. Their daily coordination usually happens in one busy
group chat, where important details get buried.</p>
<h3 class="sub">Questions housemates ask every day</h3>
<div class="questions">{questions}</div>
<h3 class="sub">A parcel day, step by step</h3>
<ol class="scenario">{scenario}</ol>
{voices}
<p class="source">Context and scenarios come from the Casama project proposal.{voices_note}</p></section>

<section><div class="eyebrow">OUR PROCESS</div><h2>From raw file to app feature</h2>
<div class="steps">{process}</div></section>

<section><div class="eyebrow">DATA QUALITY</div><h2>Cleaning the data</h2>
<div class="finding light"><div class="chart">{image("08_cleaning_funnel", "Cleaning funnel")}</div>
<p class="take">{x['undelivered_orders']:,} orders were never delivered, and
<b>{x['dropped_in_cleaning']}</b> more were removed as impossible or extreme.
Cancelled and unavailable orders are kept out of the lateness analysis on purpose.</p></div></section>

<section><div class="eyebrow">EXPLORATORY ANALYSIS</div><h2>What the data shows</h2>
<div class="findings">{findings}{more}</div></section>

<section class="dark"><div class="eyebrow">PREDICTION</div><h2 class="one-line">Can we tell which parcels will be late</h2>
<p class="lead">A gradient boosting model was trained on {m['train_orders']:,} orders from 2017 and tested
on {m['test_orders']:,} orders from 2018, so it is judged on months it has never seen.</p>
<div class="compare">
<div class="card"><h3>At purchase</h3><div class="big">AUC {s1['roc_auc']}</div>
<p>Barely better than guessing. Only the promised window and the month are known at this point.</p></div>
<div class="card"><h3>After the seller ships</h3><div class="big">AUC {s2['roc_auc']}</div>
<p>Adding the seller handoff time helps. Flagged parcels are late {s2['alert_precision_pct']}% of the time,
{lift:.1f} times the {s2['base_late_rate_pct']}% base rate, and the alert catches
{s2['alert_recall_pct']}% of all late parcels.</p></div></div>
<div class="pair">{image("13_roc", "ROC curve")}{image("14_risk_deciles", "Late rate by risk decile")}</div>
<div style="margin-top:48px">{image("07_model_importance", "Model feature importance")}</div></section>

<section><div class="eyebrow">WHAT WE LEARNED</div><h2>Five takeaways</h2>
<ol class="learned">{learned}</ol></section>

<section><div class="eyebrow">USE IN CASAMA</div><h2>From findings to the app</h2>
<table><tr><th>Finding</th><th>Casama feature</th></tr>
<tr><td>Slow seller handoff predicts lateness</td><td>Parcel board shows a "might be late" flag once a parcel is logged as shipped late</td></tr>
<tr><td>Short promised windows break most often</td><td>Parcels with tight estimates ask housemates for availability sooner</td></tr>
<tr><td>Lateness peaks in busy months</td><td>Peak season banner: confirm who can receive parcels this week</td></tr>
<tr><td>Orders cluster in the afternoon</td><td>Suggest the receiver who is usually home at that hour from presence history</td></tr></table></section>

<section class="dark"><div class="eyebrow">LIMITS</div><h2>What this does not prove</h2>
<ul class="limits">
<li>The data is Brazilian marketplace orders from 2016 to 2018, not Philippine couriers. It shows the method, not local delivery times.</li>
<li>It has timestamps only. There is no courier, payment type or COD amount, so COD behaviour is not analysed.</li>
<li>The model is modest. Late parcels are hard to predict from timing alone, so alerts are a nudge, not a guarantee.</li>
<li>2018 contained unusual spikes in February and March that the 2017 training data did not show.</li></ul></section>

<section><div class="eyebrow">GLOSSARY</div><h2>Definition of terms</h2>
<dl class="glossary">{glossary}</dl></section>

<footer>Source: <a href="https://www.kaggle.com/datasets/zeynepustun/customer-order-delivery-dataset" target="_blank" rel="noopener">Customer Order Delivery Dataset on Kaggle</a>. Code in the analysis folder.</footer>
</body></html>"""


def main() -> None:
    target = OUT / "dashboard.html"
    target.write_text(build(), encoding="utf-8")
    print(f"Wrote {target}")


if __name__ == "__main__":
    main()
