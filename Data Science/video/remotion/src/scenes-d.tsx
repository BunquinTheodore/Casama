import React from "react";
import {Easing, interpolate, useCurrentFrame} from "remotion";
import {Chart, Clock, CloudRain, Pin} from "./icons";
import {useBeat} from "./cues";
import {Appear, SceneFrame, Stamp, useProgress} from "./motion";
import {Cap, Chip, Say} from "./parts";
import {C, HEAD} from "./theme";
import type {SceneProps} from "./types";

export const clamp = {extrapolateLeft: "clamp", extrapolateRight: "clamp"} as const;
export const abs = (left: number, top: number, extra: React.CSSProperties = {}): React.CSSProperties => ({position: "absolute", left, top, ...extra});

/** Opacity that lowers a finished item once the next one is spoken, so the eye follows the voice. */
export const useDim = (next: string | undefined, to = 0.38): number => {
  const frame = useCurrentFrame();
  const at = useBeat(next ?? "head");
  return next ? interpolate(frame - at, [0, 12], [1, to], clamp) : 1;
};

const MEMBERS = ["Theodore Von Joshua M. Bunquin", "Christian B. Nayre", "Daniel B. Villanueva", "John C. Alcaraz", "Paul C. Alcaraz"];

/* ---------- Limits: five ruled statements, each with its own small picture; the one being read stays bright. */

/** Two things that go together, joined by a dotted line: an association, with no arrow of cause. */
const Link: React.FC<{size: number; color: string}> = ({size, color}) => (
  <svg viewBox="0 0 100 100" width={size} height={size} fill="none" stroke={color} strokeWidth={4} strokeLinecap="round">
    <circle cx="24" cy="64" r="14" />
    <circle cx="76" cy="36" r="14" />
    <path d="M37 57 L63 43" strokeDasharray="3 7" />
  </svg>
);

/** A missing field: the chip pops in when it is named and a line strikes it out a moment later. */
const Struck: React.FC<{beat: string; label: string}> = ({beat, label}) => {
  const {local, fps} = useProgress(beat, 0.35);
  const k = interpolate(local, [0, 0.4 * fps], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  return (
    <Appear beat={beat} from="scale" style={{position: "relative"}}>
      <Chip size={28} color={C.paper} style={{padding: "6px 22px"}}>{label}</Chip>
      <div style={{position: "absolute", left: -8, right: -8, top: "calc(50% - 2px)", height: 4, backgroundColor: C.accent, transformOrigin: "left", scale: `${k} 1`}} />
    </Appear>
  );
};

/** One dot per weather point, filling in left to right. */
const Points: React.FC<{count: number}> = ({count}) => (
  <div style={{display: "flex", gap: 6}}>
    {Array.from({length: count}, (_, i) => (
      <Appear key={i} beat="point" delay={0.4 + i * 0.04} from="scale" style={{width: 16, height: 16, borderRadius: 8, backgroundColor: C.accent}}>
        <div />
      </Appear>
    ))}
  </div>
);

const LimitRow: React.FC<{beat: string; next?: string; i: number; icon: React.ReactNode; text: string; children?: React.ReactNode}> = ({beat, next, i, icon, text, children}) => {
  const dim = useDim(next, 0.42);
  return (
    <Appear beat={beat} from="left" distance={70} style={abs(0, i * 120, {width: 1680, height: 120, borderTop: `3px solid ${C.paper}`, boxSizing: "border-box"})}>
      <div style={{height: "100%", display: "flex", alignItems: "center", gap: 34, opacity: dim}}>
        {icon}
        <Say size={44} style={{whiteSpace: "nowrap"}}>{text}</Say>
        {children}
      </div>
    </Appear>
  );
};

export const Limits: React.FC<SceneProps> = ({findings: f}) => {
  const icon = {size: 80, color: C.paper};
  return (
    <SceneFrame dark index={10} title="What this does not prove">
      <LimitRow beat="brazil" next="timestamps" i={0} icon={<Pin {...icon} />} text="Brazilian marketplace data, not Philippine" />
      <LimitRow beat="timestamps" next="point" i={1} icon={<Clock {...icon} />} text="Timestamps only">
        <div style={{display: "flex", gap: 22, marginLeft: 26}}>
          <Struck beat="courier" label="courier" />
          <Struck beat="payment" label="payment type" />
          <Struck beat="cod" label="cash on delivery amount" />
        </div>
      </LimitRow>
      <LimitRow beat="point" next="assoc" i={2} icon={<CloudRain {...icon} />} text="Weather: one point per state">
        <div style={{marginLeft: 26}}>
          <Points count={f.limits.weather_points} />
        </div>
        <Appear beat="point" delay={0.4 + f.limits.weather_points * 0.04} from="left" distance={20}>
          <Cap size={26} style={{whiteSpace: "nowrap"}}>{f.limits.weather_points} capitals</Cap>
        </Appear>
      </LimitRow>
      <LimitRow beat="assoc" next="modest" i={3} icon={<Link {...icon} />} text="These results are associations">
        <div style={{marginLeft: "auto", paddingRight: 40}}>
          <Stamp beat="assoc" size={36} tilt={-3}>not causes</Stamp>
        </div>
      </LimitRow>
      <LimitRow beat="modest" i={4} icon={<Chart {...icon} />} text="Treat the model as a nudge, not a promise">
        <div style={{marginLeft: "auto", paddingRight: 40}}>
          <Stamp beat="modest" size={36} tilt={-3}>modest</Stamp>
        </div>
      </LimitRow>
      <Appear beat="credit" from="up" style={abs(0, 646)}>
        <Chip size={28} color={C.paper}>Weather data by Open-Meteo.com (CC BY 4.0), public holidays from Nager.Date</Chip>
      </Appear>
    </SceneFrame>
  );
};

/* ---------- Credits: a calm close. Thank you lands letter by letter, then the group and the sources in the order they are read. */

const Letters: React.FC<{beat: string; text: string; step?: number}> = ({beat, text, step = 0.05}) => (
  <div style={{display: "flex"}}>
    {text.split("").map((ch, i) => (
      <Appear key={i} beat={beat} delay={i * step} from="up" distance={50} style={{display: "inline-block", whiteSpace: "pre"}}>
        {ch}
      </Appear>
    ))}
  </div>
);

/** Which spoken phrase names a source, so each row arrives as the narrator reads it. */
const sourceBeat = (name: string): string => (/Meteo/.test(name) ? "sources" : /Nager/.test(name) ? "nager" : "olist");
const SOURCE_ORDER = ["sources", "nager", "olist"];

export const Credits: React.FC<SceneProps> = ({findings: f}) => {
  const sources = [...(f.sources as {name: string}[])].sort((a, b) => SOURCE_ORDER.indexOf(sourceBeat(a.name)) - SOURCE_ORDER.indexOf(sourceBeat(b.name)));
  const olistRank = (name: string) => sources.filter((s) => sourceBeat(s.name) === "olist").findIndex((s) => s.name === name);
  const rule = `3px solid ${C.ink}`;
  return (
    <SceneFrame index={11} title="References and credits">
      <div style={abs(0, -16, {fontFamily: HEAD, fontWeight: 300, fontSize: 140, letterSpacing: "0.08em", textTransform: "uppercase", lineHeight: 1})}>
        <Letters beat="thanks" text="Thank you" />
      </div>

      <div style={abs(0, 214, {width: 800})}>
        <Appear beat="group" from="left">
          <Cap size={26}>our Data Science final project</Cap>
          <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 64, letterSpacing: "0.1em", textTransform: "uppercase", color: C.accent, whiteSpace: "nowrap", marginTop: 14}}>
            Group Theoraux
          </div>
        </Appear>
        <div style={{marginTop: 18}}>
          {MEMBERS.map((member, i) => (
            <Appear key={member} beat="group" delay={0.5 + i * 0.25} from="left" distance={40}>
              <div style={{fontSize: 36, fontWeight: 600, padding: "9px 0", borderTop: rule, whiteSpace: "nowrap"}}>{member}</div>
            </Appear>
          ))}
        </div>
      </div>

      <div style={abs(900, 214, {width: 780})}>
        <Appear beat="sources" from="right">
          <Cap size={26}>data and references</Cap>
          <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 64, letterSpacing: "0.1em", textTransform: "uppercase", whiteSpace: "nowrap", marginTop: 14}}>Sources</div>
        </Appear>
        <div style={{marginTop: 18}}>
          {sources.map((s) => {
            const beat = sourceBeat(s.name);
            return (
              <Appear key={s.name} beat={beat} delay={beat === "olist" ? olistRank(s.name) * 0.4 : 0} from="right" distance={40}>
                <div style={{fontSize: 32, fontWeight: 600, padding: "11px 0", borderTop: rule, whiteSpace: "nowrap"}}>{s.name}</div>
              </Appear>
            );
          })}
        </div>
        <Appear beat="refs" from="up" style={{marginTop: 30}}>
          <Chip size={28}>full list: REFERENCES.md in the repository</Chip>
        </Appear>
      </div>
    </SceneFrame>
  );
};
