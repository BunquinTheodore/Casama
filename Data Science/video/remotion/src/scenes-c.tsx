import React from "react";
import {Easing, interpolate, spring, useCurrentFrame, useVideoConfig} from "remotion";
import {Bell, Calendar, Chart, Clock, CloudRain, Parcel, Person, Pin} from "./icons";
import {useBeat} from "./cues";
import {num} from "./format";
import {Appear, CountUp, DrawPath, Pulse, SceneFrame, SPRING, useProgress} from "./motion";
import {Cap, Chip, Say} from "./parts";
import {C, HEAD} from "./theme";
import type {SceneProps} from "./types";
import {abs, clamp, useDim} from "./scenes-d";

/* ---------- Five takeaways: five cards, one per spoken number, with one accent line that slides to the card being read. */

const CARD_W = 312;
const STEP = CARD_W + 30;
const INNER = CARD_W - 6 - 52;
const TAKE_BEATS = ["one", "two", "three", "four", "five"];

/** A thin scale under each big number: the value fills in, with a reference mark where one helps to read it. */
const Meter: React.FC<{beat: string; value: number; max: number; mark?: number; markLabel?: string}> = ({beat, value, max, mark, markLabel}) => {
  const {local, fps} = useProgress(beat, 0.3);
  const k = interpolate(local, [0, 1.3 * fps], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  const at = (v: number) => INNER * Math.min(1, v / max);
  return (
    <div style={{position: "relative", width: INNER, height: 52}}>
      <div style={abs(0, 10, {width: INNER, height: 4, backgroundColor: C.paper, opacity: 0.3})} />
      <div style={abs(0, 7, {width: Math.max(4, at(value) * k), height: 10, backgroundColor: C.paper})} />
      {mark === undefined ? null : (
        <>
          <div style={abs(at(mark) - 1.5, 0, {width: 3, height: 28, backgroundColor: C.paper})} />
          <div style={abs(at(mark) < INNER * 0.3 ? 0 : at(mark), 30, {translate: at(mark) < INNER * 0.3 ? "0 0" : "-50% 0", fontSize: 19, fontWeight: 700, whiteSpace: "nowrap", opacity: 0.8})}>
            {markLabel}
          </div>
        </>
      )}
    </div>
  );
};

/** The accent line above the cards: it lands on card one, then slides one card along with every new takeaway. */
const Slider: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const starts = TAKE_BEATS.map((b) => useBeat(b)); // eslint-disable-line react-hooks/rules-of-hooks
  const x = starts.slice(1).reduce((sum, start) => sum + STEP * spring({frame: frame - start, fps, config: SPRING}), 0);
  const grow = interpolate(frame - starts[0], [0, 12], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  return <div style={abs(x, 0, {width: CARD_W * grow, height: 8, backgroundColor: C.accent})} />;
};

type Take = {beat: string; icon: React.ReactNode; value: number; decimals: number; suffix?: string; caption: string; text: string; meter: React.ReactNode};

const TakeCard: React.FC<{take: Take; i: number}> = ({take, i}) => {
  const frame = useCurrentFrame();
  const next = TAKE_BEATS[i + 1];
  const nextStart = useBeat(next ?? take.beat);
  const active = !next || frame < nextStart;
  const dim = useDim(next, 0.55);
  return (
    <Appear beat={take.beat} from="up" distance={90} style={abs(i * STEP, 28, {width: CARD_W, height: 690})}>
      <div style={{height: "100%", boxSizing: "border-box", border: `3px solid ${C.paper}`, padding: "26px 26px 30px", opacity: dim, display: "flex", flexDirection: "column"}}>
        <div style={{display: "flex", justifyContent: "space-between", alignItems: "flex-start", height: 96}}>
          <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 52, lineHeight: 1}}>{String(i + 1).padStart(2, "0")}</div>
          <Appear beat={take.beat} delay={0.25} from="scale">
            {take.icon}
          </Appear>
        </div>
        <div style={{marginTop: 64, fontFamily: HEAD, fontWeight: 300, fontSize: 96, lineHeight: 1, whiteSpace: "nowrap", color: active ? C.accent : C.paper}}>
          <CountUp beat={take.beat} value={take.value} decimals={take.decimals} suffix={take.suffix} seconds={1.3} />
        </div>
        <Cap size={22} style={{marginTop: 16, whiteSpace: "nowrap"}}>
          {take.caption}
        </Cap>
        <div style={{marginTop: 30}}>{take.meter}</div>
        <Appear beat={take.beat} delay={0.5} from="up" distance={24} style={{marginTop: "auto", height: 212, boxSizing: "border-box", borderTop: `2px solid ${C.paper}`, paddingTop: 20}}>
          <div style={{fontSize: 28, fontWeight: 600, lineHeight: 1.3}}>{take.text}</div>
        </Appear>
      </div>
    </Appear>
  );
};

export const Takeaways: React.FC<SceneProps> = ({findings: f}) => {
  const rain = f.h1.verdict === "supported" ? "Heavy rain went with more late parcels."
    : f.h1.verdict === "opposite" ? "Heavy rain went with fewer late parcels once month and state were accounted for."
    : "Heavy rain looks like a cause, until month and state are accounted for.";
  const holiday = f.h2.verdict === "supported" ? "A holiday in the window went with more late parcels."
    : f.h2.verdict === "opposite" ? "A holiday in the window went with fewer late parcels, the opposite of our guess."
    : "A holiday in the window made no clear difference.";
  const icon = {size: 88, color: C.paper};
  const oddsMeter = (beat: string, value: number) => <Meter beat={beat} value={value} max={2} mark={1} markLabel={`${num(1)} means no difference`} />;
  const takes: Take[] = [
    {beat: "one", icon: <Parcel {...icon} />, value: f.late.rate_pct, decimals: 1, suffix: "%", caption: "arrive late", text: "Most parcels arrive well before the estimate.",
      meter: <Meter beat="one" value={f.late.rate_pct} max={100} />},
    {beat: "two", icon: <Clock {...icon} />, value: f.handoff.late_pct_slow, decimals: 1, suffix: "%", caption: "late if slow", text: "A seller who takes a week or more is the strongest warning sign.",
      meter: <Meter beat="two" value={f.handoff.late_pct_slow} max={100} mark={f.handoff.late_pct_fast} markLabel={`quick: ${num(f.handoff.late_pct_fast, 1)}%`} />},
    {beat: "three", icon: <CloudRain {...icon} />, value: f.h1.adjusted_or.odds_ratio, decimals: 2, caption: "odds ratio", text: rain, meter: oddsMeter("three", f.h1.adjusted_or.odds_ratio)},
    {beat: "four", icon: <Calendar {...icon} />, value: f.h2.adjusted_or.odds_ratio, decimals: 2, caption: "odds ratio", text: holiday, meter: oddsMeter("four", f.h2.adjusted_or.odds_ratio)},
    {beat: "five", icon: <Chart {...icon} />, value: f.h3.auc_stage_3, decimals: 2, caption: "AUC at best", text: "A model beats guessing but stays modest.",
      meter: <Meter beat="five" value={f.h3.auc_stage_3} max={1} mark={0.5} markLabel={`${num(0.5, 1)} is a coin toss`} />},
  ];
  return (
    <SceneFrame dark index={8} title="Five takeaways">
      <Slider />
      {takes.map((take, i) => (
        <TakeCard key={take.beat} take={take} i={i} />
      ))}
    </SceneFrame>
  );
};

/* ---------- Casama: a phone with the parcel board on the left, what the app would do on the right. */

const PHONE_W = 470;

/** A two option switch whose dark pill slides from "quick" to "slow" just after the handoff time is asked for. */
const HandoffSwitch: React.FC = () => {
  const {p} = useProgress("ask", 1.1);
  const w = 176;
  const k = Math.min(1, Math.max(0, p));
  return (
    <div style={{position: "relative", display: "flex", border: `3px solid ${C.ink}`, borderRadius: 999, width: 2 * w, height: 50}}>
      <div style={abs(w * k, 0, {width: w, height: 50, borderRadius: 999, backgroundColor: C.ink})} />
      {["quick", "slow"].map((label, i) => (
        <div key={label} style={{position: "relative", width: w, textAlign: "center", lineHeight: "50px", fontSize: 24, fontWeight: 700, color: (i === 1) === k > 0.5 ? C.paper : C.ink}}>
          {label}
        </div>
      ))}
    </div>
  );
};

/** Rings once like a bell when the warning arrives. */
const Ring: React.FC<{beat: string; children: React.ReactNode}> = ({beat, children}) => {
  const {local} = useProgress(beat, 0.15);
  const t = Math.max(0, local);
  const angle = local > 0 ? 18 * Math.sin(t * 0.75) * Math.exp(-t / 24) : 0;
  return <div style={{rotate: `${angle}deg`, transformOrigin: "50% 25%"}}>{children}</div>;
};

const Phone: React.FC = () => (
  <div style={{width: PHONE_W, height: 700, border: `7px solid ${C.ink}`, borderRadius: 54, padding: "22px 28px 34px", boxSizing: "border-box", backgroundColor: C.paper, display: "flex", flexDirection: "column"}}>
    <div style={{width: 110, height: 10, borderRadius: 5, backgroundColor: C.ink, margin: "0 auto"}} />
    <Cap size={24} style={{marginTop: 24}}>Parcel board</Cap>
    <div style={{marginTop: 16, border: `4px solid ${C.ink}`, padding: "16px 18px"}}>
      <div style={{display: "flex", alignItems: "center", gap: 16}}>
        <Parcel size={64} />
        <Say size={28} style={{whiteSpace: "nowrap"}}>New parcel added</Say>
      </div>
      <Appear beat="ask" from="up" distance={20} style={{marginTop: 14}}>
        <Cap size={18} style={{marginBottom: 8}}>seller handoff time</Cap>
        <HandoffSwitch />
      </Appear>
    </div>
    <Appear beat="warn" from="down" distance={70} style={{marginTop: 22}}>
      <Pulse amount={0.025} period={40}>
        <div style={{backgroundColor: C.accent, color: C.paper, padding: "16px 18px", display: "flex", gap: 14, alignItems: "center", borderRadius: 18}}>
          <Ring beat="warn">
            <Bell size={60} color={C.paper} />
          </Ring>
          <Say size={26} style={{lineHeight: 1.25}}>Heads up: this parcel may be late</Say>
        </div>
      </Pulse>
    </Appear>
    <div style={{marginTop: "auto"}}>
      <Appear beat="nudge" from="up" distance={20} style={{borderTop: `3px solid ${C.ink}`, paddingTop: 18}}>
        <Cap size={20}>who will be home?</Cap>
      </Appear>
      <div style={{display: "flex", justifyContent: "space-between", marginTop: 14}}>
        {[true, false, true].map((home, i) => (
          <Appear key={i} beat="nudge" delay={0.4 + i * 0.25} from="scale">
            <Person size={112} home={home} />
          </Appear>
        ))}
      </div>
    </div>
  </div>
);

/** What Casama would do, one ruled row per spoken idea; earlier rows step back when the next is spoken. */
const DoRow: React.FC<{beat: string; next?: string; top: number; icon: React.ReactNode; note: string; text: string; hot?: boolean}> = ({beat, next, top, icon, note, text, hot}) => {
  const dim = useDim(next);
  return (
    <Appear beat={beat} from="right" distance={60} style={abs(0, top, {width: 1120, borderTop: `3px solid ${C.ink}`, paddingTop: 24, display: "flex", gap: 34, alignItems: "center"})}>
      <div style={{opacity: dim, display: "flex", gap: 34, alignItems: "center"}}>
        {icon}
        <div>
          <Cap size={24}>{note}</Cap>
          <Say size={50} style={{whiteSpace: "nowrap", marginTop: 6, color: hot ? C.accent : C.ink}}>{text}</Say>
        </div>
      </div>
    </Appear>
  );
};

/** The Brazil to Philippines arc, drawn with a dot riding its head. */
const ReuseArc: React.FC = () => {
  const seconds = 1.2;
  const {local, fps} = useProgress("reuse");
  const k = interpolate(local, [0, seconds * fps], [0, 1], {...clamp, easing: Easing.inOut(Easing.cubic)}); // the same curve DrawPath uses
  const [x0, y0, cx, cy, x1, y1] = [110, 130, 400, -30, 690, 130];
  const u = 1 - k;
  const dot = {x: u * u * x0 + 2 * u * k * cx + k * k * x1, y: u * u * y0 + 2 * u * k * cy + k * k * y1};
  return (
    <svg width={800} height={170} style={abs(0, 40, {overflow: "visible"})}>
      <DrawPath beat="reuse" d={`M${x0} ${y0} Q ${cx} ${cy}, ${x1} ${y1}`} stroke={C.accent} width={6} seconds={seconds} />
      {k > 0 && k < 1 ? <circle cx={dot.x} cy={dot.y} r={12} fill={C.accent} /> : null}
    </svg>
  );
};

const Reuse: React.FC<{reuse: SceneProps["reuse"]}> = ({reuse}) => {
  const names: string[] = reuse.first_five;
  const more = reuse.holiday_count - names.length;
  return (
    <Appear beat="reuse" from="up" style={abs(560, 0, {width: 1120, height: 748})}>
      <Cap size={28}>the pipeline is reusable</Cap>
      <div style={abs(40, 60)}>
        <Pin size={130} />
      </div>
      <Cap size={22} style={abs(40, 206, {whiteSpace: "nowrap"})}>Brazil, this study</Cap>
      <ReuseArc />
      <Appear beat="reuse" delay={1.2} from="scale" style={abs(620, 60)}>
        <Pin size={130} color={C.accent} />
      </Appear>
      <Appear beat="reuse" delay={1.2} from="up" distance={16} style={abs(620, 206)}>
        <Cap size={22} style={{whiteSpace: "nowrap", color: C.accent}}>the Philippines, {reuse.year}</Cap>
      </Appear>
      <Appear beat="coords" from="scale" style={abs(950, 28)}>
        <CloudRain size={110} color={C.ink} />
      </Appear>
      <Appear beat="coords" delay={0.3} from="up" distance={16} style={{position: "absolute", right: 0, top: 168}}>
        <Cap size={20} style={{whiteSpace: "nowrap"}}>same weather call</Cap>
      </Appear>

      <Appear beat="ph" from="scale" style={abs(0, 300)}>
        <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 170, color: C.accent, lineHeight: 0.9}}>
          <CountUp beat="ph" value={reuse.holiday_count} seconds={1.2} />
        </div>
        <Cap size={26} style={{marginTop: 12, whiteSpace: "nowrap"}}>public holidays</Cap>
        <Say size={26} style={{marginTop: 6, whiteSpace: "nowrap"}}>same holiday call, {reuse.year}</Say>
      </Appear>
      <div style={abs(420, 296, {width: 700})}>
        {names.map((name, i) => (
          <Appear key={name} beat="ph" delay={0.6 + i * 0.35} from="left" distance={30}>
            <div style={{fontSize: 30, fontWeight: 600, padding: "7px 0", borderTop: `2px solid ${C.ink}`, whiteSpace: "nowrap"}}>{name}</div>
          </Appear>
        ))}
        <Appear beat="ph" delay={0.6 + names.length * 0.35} from="left" distance={30}>
          <div style={{padding: "10px 0", borderTop: `2px solid ${C.ink}`}}>
            <Cap size={22}>and {more} more</Cap>
          </div>
        </Appear>
      </div>
    </Appear>
  );
};

export const Casama: React.FC<SceneProps> = ({reuse}) => {
  const rowIcon = {size: 92, color: C.ink};
  return (
    <SceneFrame index={9} title="From findings to Casama">
      <Appear beat="head" from="left" style={abs(0, 24)}>
        <Phone />
      </Appear>
      <Appear beat="ask" until="reuse" from="none" style={abs(560, 0, {width: 1120, height: 700})}>
        <DoRow beat="ask" next="warn" top={10} icon={<Clock {...rowIcon} />} note="when a parcel is added" text="Ask for the seller's handoff time" />
        <DoRow beat="warn" next="nudge" top={240} icon={<Bell {...rowIcon} />} note="when the handoff is slow" text="Warn housemates early" />
        <DoRow beat="nudge" top={470} icon={<Person {...rowIcon} />} note="not a promise" text="A nudge to plan who is home" hot />
      </Appear>
      <Reuse reuse={reuse} />
      <Appear beat="final" from="up" style={abs(560, 664)}>
        <Chip size={32}>the housemates decide who stays home</Chip>
      </Appear>
    </SceneFrame>
  );
};
