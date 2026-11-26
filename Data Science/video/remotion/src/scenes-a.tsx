import React from "react";
import {Easing, interpolate, useCurrentFrame} from "remotion";
import {Calendar, Chart, Check, Clock, CloudRain, Coin, Cross, Drop, House, Parcel, Person, Pin, Terminal} from "./icons";
import {useBeat} from "./cues";
import {num, pct} from "./format";
import {Appear, CountUp, DrawPath, Pulse, SceneFrame, Stamp, Typewriter, useProgress, Words} from "./motion";
import {Cap, Card, Chip, Say} from "./parts";
import {C, HEAD} from "./theme";
import type {SceneProps} from "./types";

const clamp = {extrapolateLeft: "clamp", extrapolateRight: "clamp"} as const;
const abs = (left: number, top: number, extra: React.CSSProperties = {}): React.CSSProperties => ({position: "absolute", left, top, ...extra});

/** A bar that grows from the left when its beat is spoken. */
const GrowBar: React.FC<{beat: string; width: number; height: number; color: string; children?: React.ReactNode}> = ({beat, width, height, color, children}) => {
  const {local} = useProgress(beat);
  const k = interpolate(local, [0, 22], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  return (
    <div style={{position: "relative", width: width * k, height, backgroundColor: color, overflow: "visible"}}>
      {children}
    </div>
  );
};

export const Title: React.FC<SceneProps> = ({findings: f}) => {
  const frame = useCurrentFrame();
  const headFrame = useBeat("head");
  const nobodyFrame = useBeat("nobody");
  const travel = interpolate(frame, [headFrame, nobodyFrame + 8], [0, 1], {...clamp, easing: Easing.inOut(Easing.cubic)});
  const lit = frame < nobodyFrame;
  const headline: React.CSSProperties = {fontFamily: HEAD, fontWeight: 300, textTransform: "uppercase", letterSpacing: "0.05em", fontSize: 118, lineHeight: 1.1};
  return (
    <SceneFrame index={1} bare>
      <div style={abs(120, 86)}>
        <Words beat="head" text="Parcels arrive" step={0.14} style={headline} />
        <Words beat="head" text="when nobody is in" step={0.14} delay={0.55} style={headline} />
      </div>
      <Appear beat="head" from="scale" style={abs(1290, 330)}>
        <House size={440} lit={lit} width={3} />
      </Appear>
      <Appear beat="head" style={abs(940 + travel * 514, 420 + travel * 192)}>
        <Parcel size={112} width={4} />
      </Appear>
      <Appear beat="nobody" from="scale" style={abs(1330, 790)}>
        <Chip color={C.accent} size={34}>
          <Person size={44} color={C.accent} home={false} /> nobody home
        </Chip>
      </Appear>
      <Appear beat="project" style={abs(120, 400)}>
        <Say size={44}>Data Science final project for Casama</Say>
      </Appear>
      <div style={abs(120, 480)}>
        <Appear beat="count">
          <CountUp beat="count" value={f.cleaning.analysed} seconds={1.7} style={{fontFamily: HEAD, fontWeight: 300, fontSize: 170, letterSpacing: "0.03em", lineHeight: 1}} />
          <Cap size={34} style={{marginTop: 10}}>real parcels</Cap>
        </Appear>
      </div>
      <Appear beat="weather" from="left" style={abs(820, 520)}>
        <Chip size={40}>
          <CloudRain size={56} /> weather
        </Chip>
      </Appear>
      <Appear beat="holidays" from="left" style={abs(820, 620)}>
        <Chip size={40}>
          <Calendar size={56} /> public holidays
        </Chip>
      </Appear>
      <div style={abs(120, 872)}>
        <Words beat="ask" text="When do deliveries run late?" step={0.12} style={{...headline, fontSize: 78, letterSpacing: "0.07em"}} />
        <svg width={1200} height={24} style={{marginTop: 12}}>
          <DrawPath beat="ask" d="M0 12 L1180 12" stroke={C.accent} width={8} seconds={1} />
        </svg>
      </div>
    </SceneFrame>
  );
};

export const Question: React.FC<SceneProps> = () => {
  const frame = useCurrentFrame();
  const lateFrame = useBeat("late");
  const late = frame >= lateFrame;
  const cards = [
    {beat: "q1", n: "01", icon: <CloudRain size={190} />, text: "More heavy rain after the seller ships: late more often?"},
    {beat: "q2", n: "02", icon: <Calendar size={190} />, text: "A public holiday in those same days: late more often?"},
    {beat: "q3", n: "03", icon: <Chart size={190} />, text: "Weather and holidays added: a more accurate model?"},
  ];
  return (
    <SceneFrame dark index={2} title="The question">
      <Appear beat="board" until="asked" from="left" style={abs(0, 10)}>
        <Card color={C.paper} width={780} height={540}>
          <div style={{display: "flex", alignItems: "center", gap: 20}}>
            <Parcel size={78} />
            <Cap size={38}>Parcel board</Cap>
          </div>
          <div style={{marginTop: 36, display: "flex", alignItems: "center", gap: 20}}>
            <Say size={36}>Parcel</Say>
            {late ? (
              <Chip color={C.accent} size={34}>
                <Clock size={44} color={C.accent} /> late
              </Chip>
            ) : (
              <Chip size={34} color={C.paper}>on the way</Chip>
            )}
          </div>
          <div style={{marginTop: 40}}>
            <Say size={36}>Housemates</Say>
            <div style={{display: "flex", gap: 30, marginTop: 14}}>
              {[true, true, false].map((home, i) => (
                <Person key={i} size={110} home={late ? false : home} width={4} />
              ))}
            </div>
          </div>
          <div style={{marginTop: 16, height: 54}}>
            <Appear beat="late" from="left">
              <Say size={38} style={{color: C.accent}}>nobody is home</Say>
            </Appear>
          </div>
        </Card>
      </Appear>
      <Appear beat="cod" until="asked" from="scale" style={abs(560, 360)}>
        <Pulse>
          <Coin size={150} color={C.accent} />
        </Pulse>
      </Appear>
      <Appear beat="board" until="asked" from="right" style={abs(960, 40)}>
        <House size={560} lit={!late} width={2.6} color={C.paper} />
      </Appear>
      <Appear beat="late" until="asked" from="down" style={abs(1160, 330)}>
        <Parcel size={120} color={C.paper} />
      </Appear>
      <Appear beat="cod" until="asked" from="up" style={abs(1060, 560)}>
        <Say size={40}>cash on delivery: pay when it arrives</Say>
      </Appear>
      {cards.map((card, i) => (
        <Appear key={`${card.beat}-slot`} beat="asked" from="none" style={abs(i * 580, 0)}>
          <Card dashed color={C.paper} width={520} height={600} style={{opacity: 0.35}}> </Card>
        </Appear>
      ))}
      {cards.map((card, i) => (
        <Appear key={card.beat} beat={card.beat} from="up" distance={90} style={abs(i * 580, 0)}>
          <Card color={C.paper} width={520} height={600}>
            <Cap size={52}>{card.n}</Cap>
            <div style={{margin: "26px 0 22px"}}>{card.icon}</div>
            <Say size={40}>{card.text}</Say>
          </Card>
        </Appear>
      ))}
      <div style={abs(500, 640)}>
        <Stamp beat="promise" size={46}>Reported either way</Stamp>
      </div>
    </SceneFrame>
  );
};

export const Data: React.FC<SceneProps> = ({findings: f}) => {
  const cards = [
    {beat: "orders", icon: <Parcel size={92} />, name: "Olist orders", sub: "Kaggle table", extra: <CountUp beat="orders" value={f.cleaning.raw_orders} seconds={1.4} suffix=" orders" style={{fontSize: 34, fontWeight: 700}} />},
    {beat: "customers", icon: <Pin size={92} />, name: "Olist customers", sub: "Kaggle table", extra: <span style={{fontSize: 34, fontWeight: 700}}>state of each customer</span>},
    {beat: "meteo", icon: <CloudRain size={92} />, name: "Open-Meteo", sub: "free weather API", extra: <span style={{fontSize: 34, fontWeight: 700}}>daily rain, no key</span>},
    {beat: "nager", icon: <Calendar size={92} />, name: "Nager.Date", sub: "free holiday API", extra: <span style={{fontSize: 34, fontWeight: 700}}>public holidays, no key</span>},
  ];
  const steps = ["download", "findings", "reuse", "explorer", "readme", "narration"];
  return (
    <SceneFrame index={3} title="Four sources">
      {cards.map((card, i) => (
        <React.Fragment key={card.beat}>
          <Appear beat="four" from="none" style={abs(i * 430, 0)}>
            <Card dashed width={390} height={270} color={C.ink} style={{opacity: 0.35}}> </Card>
          </Appear>
          <Appear beat={card.beat} from="scale" style={abs(i * 430, 0)}>
            <Card width={390} height={270} style={{backgroundColor: C.paper}}>
              <div style={{display: "flex", alignItems: "center", gap: 18}}>
                {card.icon}
                <div>
                  <Cap size={24} style={{letterSpacing: "0.12em"}}>
                    {card.name.split(" ").map((word) => (
                      <span key={word} style={{whiteSpace: "nowrap", marginRight: "0.4em", display: "inline-block"}}>{word}</span>
                    ))}
                  </Cap>
                  <div style={{fontSize: 26, fontWeight: 600, opacity: 0.75}}>{card.sub}</div>
                </div>
              </div>
              <div style={{marginTop: 26}}>{card.extra}</div>
            </Card>
          </Appear>
        </React.Fragment>
      ))}
      <Appear beat="apis" from="down" style={abs(860, -44)}>
        <Chip color={C.accent} size={30} style={{padding: "4px 24px"}}>two free APIs, no key needed</Chip>
      </Appear>

      <Appear beat="window" until="rain" style={abs(0, 330)}>
        <Cap size={34} style={{marginBottom: 20}}>the {f.h1.window_days} days after the seller hands the parcel over</Cap>
        <div style={{display: "flex", gap: 14, alignItems: "flex-end"}}>
          <Parcel size={96} />
          {Array.from({length: f.h1.window_days}, (_, i) => (
            <Appear key={i} beat="window" delay={0.25 + i * 0.22} from="up" distance={30}>
              <Card width={178} height={170} color={i === 0 ? C.accent : C.ink} style={{padding: "14px 18px"}}>
                <Cap size={26}>{i === 0 ? "handoff" : `day ${i + 1}`}</Cap>
                <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 84, marginTop: 8, color: i === 0 ? C.accent : C.ink}}>{i + 1}</div>
              </Card>
            </Appear>
          ))}
        </div>
      </Appear>

      <Appear beat="rain" until="command" style={abs(0, 330)}>
        <div style={{display: "flex", flexDirection: "column", gap: 30, alignItems: "flex-start"}}>
          <Chip size={44}>
            <Drop size={64} color={C.accent} /> heavy rain day: at least {num(f.h1.heavy_mm, 0)} mm
          </Chip>
          <Appear beat="brazil" from="left">
            <Chip size={44}>
              <Pin size={64} /> Brazilian data, not Philippine
            </Chip>
          </Appear>
          <Appear beat="point" from="left">
            <div style={{display: "flex", alignItems: "center", gap: 28}}>
              <div style={{display: "grid", gridTemplateColumns: "repeat(9, 22px)", gap: 8}}>
                {Array.from({length: f.limits.weather_points}, (_, i) => (
                  <Appear key={i} beat="point" delay={i * 0.03} from="scale" style={{width: 22, height: 22, borderRadius: 11, backgroundColor: C.accent}}>
                    <div />
                  </Appear>
                ))}
              </div>
              <Say size={40}>one weather point per state: {f.limits.weather_points} capitals</Say>
            </div>
          </Appear>
        </div>
      </Appear>

      <Appear beat="command" from="up" style={abs(0, 330)}>
        <div style={{backgroundColor: C.ink, color: C.paper, padding: "28px 36px", width: 1000, fontSize: 40}}>
          <div style={{display: "flex", alignItems: "center", gap: 18}}>
            <Terminal size={64} color={C.paper} />
            <Typewriter beat="command" text="python src/run_all.py" style={{fontSize: 44}} />
          </div>
          <div style={{marginTop: 22, display: "grid", gridTemplateColumns: "1fr 1fr", rowGap: 8}}>
            {steps.map((step, i) => (
              <Appear key={step} beat="command" delay={1.6 + i * 0.33} from="left" distance={20}>
                <span style={{fontFamily: "ui-monospace, Consolas, monospace", fontSize: 34}}>
                  <span style={{color: C.accent}}>[{step}]</span> done
                </span>
              </Appear>
            ))}
          </div>
        </div>
      </Appear>
    </SceneFrame>
  );
};

export const Cleaning: React.FC<SceneProps> = ({findings: f}) => {
  const c = f.cleaning;
  const full = 700;
  const widthOf = (n: number) => (full * n) / c.raw_orders;
  return (
    <SceneFrame dark index={4} title="Cleaning">
      <div style={abs(0, 20, {width: 960})}>
        <Appear beat="start" from="left">
          <Cap size={30} style={{marginBottom: 8}}>all orders</Cap>
          <div style={{display: "flex", alignItems: "center", gap: 24}}>
            <GrowBar beat="start" width={full} height={78} color={C.paper} />
            <CountUp beat="start" value={c.raw_orders} seconds={1.3} style={{fontSize: 46, fontWeight: 800}} />
          </div>
        </Appear>
        <div style={{marginTop: 34}}>
          <Appear beat="undelivered" from="left">
            <Cap size={30} style={{marginBottom: 8}}>delivered with a date</Cap>
            <div style={{display: "flex", alignItems: "center", gap: 24}}>
              <div style={{display: "flex"}}>
                <GrowBar beat="undelivered" width={widthOf(c.delivered_with_date)} height={78} color={C.paper} />
                <Appear beat="undelivered" from="none" delay={0.4}>
                  <div style={{width: widthOf(c.undelivered), height: 78, backgroundColor: C.accent}} />
                </Appear>
              </div>
              <CountUp beat="undelivered" value={c.delivered_with_date} seconds={1.2} style={{fontSize: 46, fontWeight: 800}} />
            </div>
            <div style={{marginTop: 10}}>
              <Chip color={C.accent} size={28} style={{padding: "2px 20px"}}>{num(c.undelivered)} never delivered</Chip>
            </div>
          </Appear>
        </div>
        <div style={{marginTop: 28}}>
          <Appear beat="removed" from="left">
            <Cap size={30} style={{marginBottom: 8}}>analysed</Cap>
            <div style={{display: "flex", alignItems: "center", gap: 24}}>
              <div style={{display: "flex"}}>
                <GrowBar beat="removed" width={widthOf(c.analysed)} height={78} color={C.accent} />
                <Appear beat="removed" from="none" delay={0.4}>
                  <div style={{width: widthOf(c.dropped) + 2, height: 78, backgroundColor: C.paper, opacity: 0.55}} />
                </Appear>
              </div>
              <CountUp beat="removed" value={c.analysed} seconds={1.2} style={{fontSize: 46, fontWeight: 800}} />
            </div>
            <div style={{marginTop: 10}}>
              <Chip size={28} color={C.paper} style={{padding: "2px 20px"}}>{num(c.dropped)} removed: impossible or extreme timings</Chip>
            </div>
          </Appear>
        </div>
        <Appear beat="kept" from="scale" style={{marginTop: 34}}>
          <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 104, color: C.accent}}>
            <CountUp beat="kept" value={c.kept_pct} decimals={1} suffix="%" seconds={1.1} /> <span style={{fontSize: 52, color: C.paper}}>kept</span>
          </div>
        </Appear>
      </div>

      <Appear beat="midnight" from="right" style={abs(1020, 0)}>
        <Cap size={30} style={{marginBottom: 14}}>when is a parcel late?</Cap>
        <div style={{display: "flex"}}>
          {["day before", "promised day", "day after"].map((label, i) => (
            <div key={label} style={{width: 220, height: 200, border: `4px solid ${C.paper}`, borderLeftWidth: i === 0 ? 4 : 0, padding: 14, boxSizing: "border-box", position: "relative"}}>
              <Cap size={24}>{label}</Cap>
            </div>
          ))}
        </div>
        <div style={{position: "absolute", left: 218, top: 44, width: 8, height: 214, backgroundColor: C.accent}} />
        <div style={{position: "absolute", left: 240, top: 268, fontSize: 28, fontWeight: 700, color: C.accent}}>estimate = midnight</div>
      </Appear>
      <Appear beat="afternoon" from="down" distance={80} style={abs(1260, 118)}>
        <div style={{width: 40, height: 40, borderRadius: 20, backgroundColor: C.paper}} />
      </Appear>
      <Appear beat="afternoon" until="calendar" from="up" style={abs(1060, 300)}>
        <Chip color={C.accent} size={34}>
          <Cross size={46} color={C.accent} /> two in the afternoon looks late by the clock
        </Chip>
      </Appear>
      <Appear beat="calendar" from="scale" style={abs(1060, 300)}>
        <Chip color={C.paper} size={34}>
          <Check size={46} color={C.paper} /> same calendar day: on time
        </Chip>
      </Appear>
      <Appear beat="calendar" from="down" distance={80} style={abs(1480, 118)}>
        <div style={{width: 40, height: 40, borderRadius: 20, backgroundColor: C.accent}} />
      </Appear>
      <Appear beat="calendar" from="up" style={abs(1360, 370)}>
        <Say size={32} style={{color: C.accent}}>a later day: late</Say>
      </Appear>

      <Appear beat="rate" from="scale" style={abs(1020, 450)}>
        <Cap size={30}>late, counted by calendar day</Cap>
        <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 170, color: C.accent, lineHeight: 1.1}}>
          <CountUp beat="rate" value={f.late.rate_pct} decimals={2} suffix="%" seconds={1.5} />
        </div>
      </Appear>
      <Appear beat="clock" from="left" style={abs(1020, 700)}>
        <div style={{display: "flex", alignItems: "baseline", gap: 18}}>
          <span style={{fontFamily: HEAD, fontWeight: 300, fontSize: 70, textDecoration: "line-through", opacity: 0.7}}>{pct(f.data_note.late_pct_timestamp_rule, 2)}</span>
          <Say size={32}>by the clock</Say>
        </div>
      </Appear>
    </SceneFrame>
  );
};
