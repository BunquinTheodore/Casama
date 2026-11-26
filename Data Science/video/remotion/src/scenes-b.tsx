import React from "react";
import {Easing, interpolate} from "remotion";
import {Calendar, CloudRain, Parcel} from "./icons";
import {useBeat} from "./cues";
import {Donut, ForestPlot, HourBars, VolumeLate} from "./charts";
import {num, pct} from "./format";
import {Appear, CountUp, SceneFrame, Stamp, useProgress} from "./motion";
import {Cap, Card, Chip, Say} from "./parts";
import {C, HEAD} from "./theme";
import type {SceneProps} from "./types";
import {Bars, type BarRow, HBars} from "./ui";

const clamp = {extrapolateLeft: "clamp", extrapolateRight: "clamp"} as const;
const abs = (left: number, top: number, extra: React.CSSProperties = {}): React.CSSProperties => ({position: "absolute", left, top, ...extra});
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const monthLabel = (m: string) => `${MONTHS[Number(m.slice(5, 7)) - 1]} ${m.slice(2, 4)}`;
const FEATURE_NAMES: Record<string, string> = {
  estimated_days: "Days promised", purchase_weekday: "Weekday", purchase_hour: "Hour", month_of_year: "Month of year",
  handoff_days: "Seller handoff days", heavy_rain_days: "Heavy rain days", rain_mm_total: "Total rain", holiday_in_window: "Holiday in window",
};

/** A chart that grows when its beat is spoken and goes away when the next beat is. */
const Stage: React.FC<{beat: string; until?: string; children: React.ReactNode}> = ({beat, until, children}) => (
  <Appear beat={beat} until={until} from="up" distance={40} style={abs(0, 0)}>
    {children}
  </Appear>
);

/** Ten parcels drop in on "the median parcel"; the tenth turns orange and slides apart on "one in ten takes more than". */
const ParcelRow: React.FC = () => {
  const slow = useProgress("tenth");
  const split = interpolate(slow.local, [0, 18], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  return (
    <div style={{display: "flex", gap: 40}}>
      {Array.from({length: 10}, (_, i) => (
        <ParcelDrop key={i} index={i} split={i === 9 ? split : 0} />
      ))}
    </div>
  );
};

const ParcelDrop: React.FC<{index: number; split: number}> = ({index, split}) => {
  const {p, local} = useProgress("median", 0.5 + index * 0.13, {damping: 9, stiffness: 150, mass: 0.8});
  const hot = split > 0.4;
  return (
    <div style={{opacity: interpolate(local, [0, 6], [0, 1], clamp), translate: `${split * 70}px ${(1 - p) * -90}px`, scale: String(1 + split * 0.18)}}>
      <Parcel size={120} color={hot ? C.accent : C.ink} width={hot ? 6 : 4} />
    </div>
  );
};

export const Shows: React.FC<SceneProps> = ({findings: f, series}) => {
  const months: BarRow[] = series.late_by_month.map((r: any) => ({label: monthLabel(r.month), value: r.late_pct, hot: r.late_pct >= 10}));
  const shortHandoff = ["<1", "1 to 2", "2 to 4", "4 to 7", "7+"];
  const handoff: BarRow[] = series.late_by_handoff.map((r: any, i: number, all: any[]) => ({label: shortHandoff[i], value: r.late_pct, hot: i === all.length - 1}));
  const promise: BarRow[] = series.late_by_promise.map((r: any, i: number) => ({label: ["<10", "10 to 15", "15 to 20", "20 to 30", "30+"][i], value: r.late_pct, hot: i === 0}));
  const hours = Array.from({length: 24}, (_, hour) => ({hour, orders: series.order_rhythm.filter((r: any) => r.hour === hour).reduce((s: number, r: any) => s + r.orders, 0)}));
  const monthStart = useBeat("spikes");
  const handoffStart = useBeat("seller");
  const promiseStart = useBeat("promises");
  return (
    <SceneFrame index={5} title="What the data shows">
      <Stage beat="median" until="spikes">
        <div style={{display: "flex", alignItems: "flex-end", gap: 40}}>
          <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 280, lineHeight: 0.95}}>
            <CountUp beat="median" value={f.delivery_days.median} decimals={1} seconds={1.6} />
          </div>
          <Cap size={56} style={{paddingBottom: 40}}>days to deliver, the median</Cap>
        </div>
        <div style={abs(0, 540)}>
          <ParcelRow />
        </div>
        <Appear beat="tenth" from="left" style={{marginTop: 34}}>
          <Chip size={46}>one parcel in ten takes more than <CountUp beat="tenth" value={f.delivery_days.p90} decimals={1} seconds={1.1} /> days</Chip>
        </Appear>
        <Appear beat="padded" from="left" style={{marginTop: 26}}>
          <Chip size={46} color={C.accent}>
            padded estimates: typically <CountUp beat="padded" value={f.late.median_days_early} decimals={1} seconds={1.1} /> days early
          </Chip>
        </Appear>
      </Stage>

      <Stage beat="spikes" until="seller">
        <Bars rows={months} width={1180} height={640} fg={C.ink} unit="%" tickEvery={3} labels="hot" start={monthStart} />
        <Cap size={32} style={{marginTop: 10}}>late parcels by month</Cap>
        <Appear beat="worst" from="scale" style={abs(1240, 130)}>
          <Card color={C.accent} width={420}>
            <Cap size={30}>{f.late.worst_month_name}</Cap>
            <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 120, color: C.accent, lineHeight: 1.1}}>
              <CountUp beat="worst" value={f.late.worst_month_late_pct} decimals={1} suffix="%" seconds={1.2} />
            </div>
            <Say size={34}>late, the worst month</Say>
          </Card>
        </Appear>
      </Stage>

      <Stage beat="seller" until="promises">
        <Bars rows={handoff} width={1020} height={640} fg={C.ink} unit="%" start={handoffStart} />
        <Cap size={32} style={{marginTop: 10}}>days until the seller hands the parcel over</Cap>
        <Appear beat="week" from="scale" style={abs(1120, 40)}>
          <Card color={C.accent} width={500}>
            <Cap size={30}>a week or more</Cap>
            <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 130, color: C.accent, lineHeight: 1.1}}>
              <CountUp beat="week" value={f.handoff.late_pct_slow} decimals={1} suffix="%" seconds={1.2} />
            </div>
            <Say size={34}>late, against {pct(f.handoff.late_pct_fast, 1)} for a quick handoff</Say>
          </Card>
        </Appear>
        <Appear beat="journey" from="left" style={abs(1120, 380)}>
          <Cap size={28} style={{marginBottom: 12}}>median days in total</Cap>
          {[{label: "quick handoff", v: f.handoff.median_total_days_fast, c: C.ink}, {label: "a week or more", v: f.handoff.median_total_days_slow, c: C.accent}].map((row, i) => (
            <div key={row.label} style={{display: "flex", alignItems: "center", gap: 18, marginBottom: 16}}>
              <div style={{width: 190, fontSize: 28, fontWeight: 600}}>{row.label}</div>
              <JourneyBar beat="journey" delay={i * 0.35} width={(row.v / f.handoff.median_total_days_slow) * 250} color={row.c} />
              <CountUp beat="journey" value={row.v} decimals={1} seconds={1} style={{fontSize: 38, fontWeight: 800}} />
            </div>
          ))}
        </Appear>
      </Stage>

      <Stage beat="promises" until="busy">
        <Bars rows={promise} width={1020} height={640} fg={C.ink} unit="%" start={promiseStart} />
        <Cap size={32} style={{marginTop: 10}}>days promised at purchase</Cap>
        <Appear beat="promises" delay={1.4} from="scale" style={abs(1120, 80)}>
          <Card width={500}>
            <Say size={40}>the shortest promises are broken most often</Say>
          </Card>
        </Appear>
      </Stage>

      <Stage beat="busy" until="shop">
        <VolumeLate rows={series.volume_vs_late} width={1240} height={520} fg={C.ink} beat="busy" />
        <div style={{display: "flex", gap: 30, marginTop: 18}}>
          <Chip size={34}>orders per month</Chip>
          <Chip size={34} color={C.accent}>share late</Chip>
        </div>
        <Appear beat="busy" delay={1.2} from="scale" style={abs(1320, 120)}>
          <Card width={320}>
            <Cap size={26}>they move together</Cap>
            <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 96}}>{num(f.late.volume_late_correlation, 2)}</div>
          </Card>
        </Appear>
      </Stage>

      <Stage beat="shop">
        <HourBars rows={hours} width={1240} height={500} fg={C.ink} beat="shop" />
        <Cap size={32} style={{marginTop: 10}}>orders by hour of the day: afternoon and evening</Cap>
      </Stage>
    </SceneFrame>
  );
};

const JourneyBar: React.FC<{beat: string; delay: number; width: number; color: string}> = ({beat, delay, width, color}) => {
  const {local, fps} = useProgress(beat, delay);
  const k = interpolate(local, [0, 0.7 * fps], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  return <div style={{width: Math.max(width, 6) * k, height: 36, backgroundColor: color}} />;
};

export const Weather: React.FC<SceneProps> = ({findings: f, series}) => {
  const dose: BarRow[] = series.rain_dose.map((r: any) => ({label: r.group === "3 or more" ? "3+" : r.group, value: r.late_pct, lo: r.ci_low, hi: r.ci_high}));
  const holiday: BarRow[] = series.holiday_effect.map((r: any) => ({label: r.group === "Holiday in window" ? "Holiday" : "No holiday", value: r.late_pct, lo: r.ci_low, hi: r.ci_high}));
  const doseStart = useBeat("raw");
  const holidayStart = useBeat("holidays");
  const s10 = f.sensitivity["10"];
  const s14 = f.sensitivity["14"];
  const rows = [
    {label: "Heavy rain", value: f.h1.adjusted_or.odds_ratio, lo: f.h1.adjusted_or.ci_low, hi: f.h1.adjusted_or.ci_high, beat: "factor"},
    {label: "Holiday", value: f.h2.adjusted_or.odds_ratio, lo: f.h2.adjusted_or.ci_low, hi: f.h2.adjusted_or.ci_high, beat: "opposite", hot: true},
    {label: "rain, 10 d", value: s10.h1_or.odds_ratio, lo: s10.h1_or.ci_low, hi: s10.h1_or.ci_high, beat: "windows", small: true},
    {label: "rain, 14 d", value: s14.h1_or.odds_ratio, lo: s14.h1_or.ci_low, hi: s14.h1_or.ci_high, beat: "windows", small: true},
    {label: "holiday, 10 d", value: s10.h2_or.odds_ratio, lo: s10.h2_or.ci_low, hi: s10.h2_or.ci_high, beat: "windows", small: true, hot: true},
    {label: "holiday, 14 d", value: s14.h2_or.odds_ratio, lo: s14.h2_or.ci_low, hi: s14.h2_or.ci_high, beat: "windows", small: true, hot: true},
  ];
  return (
    <SceneFrame dark index={6} title="Weather and holidays">
      <Appear beat="intro" until="raw" from="up" style={abs(0, 20)}>
        <Cap size={32} style={{marginBottom: 22}}>the days after a parcel is handed over: rain, and a public holiday</Cap>
        <div style={{display: "flex", gap: 18}}>
          {Array.from({length: f.h1.window_days}, (_, i) => (
            <Appear key={i} beat="intro" delay={0.3 + i * 0.2} from="up" distance={30}>
              <Card width={210} height={250} color={C.paper} style={{padding: "16px 18px"}}>
                <Cap size={26}>day {i + 1}</Cap>
                <div style={{marginTop: 14}}>
                  {i === 1 || i === 2 || i === 5 ? <CloudRain size={120} color={C.paper} /> : i === 3 ? <Calendar size={120} color={C.paper} /> : null}
                </div>
              </Card>
            </Appear>
          ))}
        </div>
      </Appear>

      <Appear beat="raw" until="holidays" from="left" style={abs(0, 0)}>
        <Bars rows={dose} width={760} height={560} fg={C.paper} unit="%" start={doseStart} />
        <Cap size={30} style={{marginTop: 8}}>heavy rain days in the window</Cap>
        <Appear beat="climbs" from="up" style={{marginTop: 22}}>
          <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 84}}>
            <CountUp beat="climbs" value={dose[0].value} decimals={1} suffix="%" seconds={0.8} /> to{" "}
            <span style={{color: C.accent}}>
              <CountUp beat="climbs" value={dose[3].value} decimals={1} suffix="%" seconds={1.6} />
            </span>
          </div>
        </Appear>
      </Appear>
      <Appear beat="holidays" from="left" style={abs(0, 0)}>
        <Bars rows={holiday} width={760} height={560} fg={C.paper} unit="%" start={holidayStart} />
        <Cap size={30} style={{marginTop: 8}}>holiday in the window</Cap>
        <Appear beat="surprised" from="scale" style={{marginTop: 22}}>
          <Chip color={C.accent} size={42}>they surprised us</Chip>
        </Appear>
      </Appear>

      <Appear beat="account" from="right" style={abs(820, 0)}>
        <div style={{display: "flex", gap: 18, marginBottom: 4}}>
          <Chip size={32}>account for month</Chip>
          <Chip size={32}>account for state</Chip>
        </div>
        <ForestPlot rows={rows} width={860} fg={C.paper} bg={C.ink} lineBeat="account" pulseBeat="oddsratio" rowHeight={78} />
      </Appear>
      <Appear beat="noeffect" until="holidays" from="none" style={abs(330, 6)}>
        <Stamp beat="noeffect" size={38}>no clear effect</Stamp>
      </Appear>
      <div style={abs(60, 6)}>
        <Stamp beat="opposite" size={34}>opposite of our guess</Stamp>
      </div>
      <Appear beat="why" from="up" style={abs(450, 636)}>
        <Chip size={32} color={C.paper}>why? not tested</Chip>
      </Appear>
    </SceneFrame>
  );
};

const Axis: React.FC<{label: string; beat: string; value: number; color: string; width: number; fg: string}> = ({label, beat, value, color, width, fg}) => {
  const {local} = useProgress(beat);
  const k = interpolate(local, [0, 24], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  const height = ((value - 0.5) / 0.2) * 520 * k;
  return (
    <div style={{width, textAlign: "center", position: "relative", height: 640}}>
      <div style={{position: "absolute", bottom: 80, left: width * 0.14, width: width * 0.72, height, backgroundColor: color}} />
      <div style={{position: "absolute", bottom: 90 + height, width, fontFamily: HEAD, fontWeight: 300, fontSize: 52, color: fg, opacity: k}}>{num(value * Math.min(1, k * 1.2), 3)}</div>
      <div style={{position: "absolute", bottom: 20, width, fontSize: 30, fontWeight: 700, color: fg, opacity: interpolate(local, [0, 10], [0.28, 1], clamp)}}>{label}</div>
    </div>
  );
};

export const Model: React.FC<SceneProps> = ({findings: f}) => {
  const h3 = f.h3;
  const imp: BarRow[] = Object.entries(h3.importance_stage_3 as Record<string, number>)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([k, v]) => ({label: FEATURE_NAMES[k] ?? k, value: v, hot: k.includes("rain") || k.includes("holiday")}));
  const total = h3.train_orders + h3.test_orders;
  const trainWidth = (h3.train_orders / total) * 1500;
  const testWidth = (h3.test_orders / total) * 1500;
  const signalsStart = useBeat("signals");
  return (
    <SceneFrame index={7} title="Can we predict late parcels?">
      <Appear beat="trained" until="stage1" from="up" style={abs(0, 30)}>
        <Cap size={32} style={{marginBottom: 26}}>a gradient boosting model, judged on months it never saw</Cap>
        <div style={{display: "flex"}}>
          <Appear beat="before" from="left">
            <div style={{width: trainWidth, height: 170, backgroundColor: C.ink, color: C.paper, padding: "20px 28px", boxSizing: "border-box"}}>
              <Cap size={28}>trained on</Cap>
              <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 64}}>
                <CountUp beat="before" value={h3.train_orders} seconds={1.2} /> <span style={{fontSize: 34}}>parcels</span>
              </div>
            </div>
          </Appear>
          <Appear beat="tested" from="left">
            <div style={{width: testWidth, height: 170, backgroundColor: C.accent, color: C.paper, padding: "20px 28px", boxSizing: "border-box"}}>
              <Cap size={28}>tested on</Cap>
              <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 64}}>
                <CountUp beat="tested" value={h3.test_orders} seconds={1.2} /> <span style={{fontSize: 34}}>later parcels</span>
              </div>
            </div>
          </Appear>
        </div>
        <div style={{display: "flex", justifyContent: "space-between", width: 1500, marginTop: 14, fontSize: 30, fontWeight: 700}}>
          <span>earlier</span>
          <span>time</span>
          <span>later</span>
        </div>
        <Appear beat="split" from="up" style={{marginTop: 28}}>
          <Chip size={40}>split by time, not at random</Chip>
        </Appear>
      </Appear>

      <Appear beat="stage1" from="up" style={abs(0, 0)}>
        <div style={{position: "relative", width: 900, height: 660}}>
          <div style={{position: "absolute", left: 0, right: 0, bottom: 80, height: 0, borderTop: `4px dashed ${C.ink}`, opacity: 0.6}} />
          <div style={{position: "absolute", left: 0, bottom: 92, width: 170, fontSize: 28, fontWeight: 700, lineHeight: 1.2}}>coin toss: {num(0.5, 1)}</div>
          <div style={{display: "flex", position: "absolute", left: 176, bottom: 0}}>
            <Axis label="at purchase" beat="stage1" value={h3.auc_stage_1} color={C.ink} width={240} fg={C.ink} />
            <Axis label="after shipping" beat="stage2" value={h3.auc_stage_2} color={C.ink} width={240} fg={C.ink} />
            <Axis label="with weather" beat="stage3" value={h3.auc_stage_3} color={C.accent} width={240} fg={C.accent} />
          </div>
        </div>
      </Appear>
      <Appear beat="gain" until="signals" from="scale" style={abs(1020, 40)}>
        <Card color={C.accent} width={360}>
          <Cap size={26}>the gain</Cap>
          <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 100, color: C.accent, lineHeight: 1.1}}>
            +<CountUp beat="gain" value={h3.diff} decimals={3} seconds={1.2} />
          </div>
          <Say size={28}>{num(h3.diff_ci_low, 3)} to {num(h3.diff_ci_high, 3)}</Say>
        </Card>
      </Appear>

      <Appear beat="signals" until="flagging" from="right" style={abs(980, 0)}>
        <Cap size={26} style={{marginBottom: 18, whiteSpace: "nowrap"}}>what the last model leaned on</Cap>
        <HBars rows={imp} width={700} fg={C.ink} decimals={2} labelWidth={290} rowHeight={86} start={signalsStart} />
      </Appear>
      <div style={abs(1040, 520)}>
        <Stamp beat="modest" size={56}>modest</Stamp>
      </div>
      <Appear beat="flagging" from="right" style={abs(980, 0)}>
        <Cap size={30} style={{marginBottom: 18}}>flagging the riskiest parcels</Cap>
        <div style={{display: "flex", gap: 40}}>
          <Donut beat="flagging" value={h3.alert_recall_stage_3} label="of late parcels caught" fg={C.ink} size={320} />
          <Donut beat="flagging" value={h3.alert_precision_stage_3} label="of flags correct" fg={C.ink} size={320} />
        </div>
      </Appear>
      <Appear beat="forecast" from="up" style={abs(920, 650)}>
        <Chip size={28} color={C.accent} style={{whiteSpace: "nowrap"}}>weather observed after the fact: not a forecast</Chip>
      </Appear>
    </SceneFrame>
  );
};
