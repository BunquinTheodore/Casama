import React from "react";
import {Easing, interpolate, spring, useCurrentFrame, useVideoConfig} from "remotion";
import {useBeat} from "./cues";
import {num} from "./format";
import {BODY, C, HEAD} from "./theme";

const clamp = {extrapolateLeft: "clamp", extrapolateRight: "clamp"} as const;
export const SPRING = {damping: 18, stiffness: 130, mass: 0.8};

/** Spring progress (0 to 1, a little overshoot) that starts when the words of `beat` are spoken. */
export const useProgress = (beat: string, delaySeconds = 0, config = SPRING) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const start = useBeat(beat) + Math.round(delaySeconds * fps);
  return {start, frame, fps, p: spring({frame: frame - start, fps, config}), local: frame - start};
};

type From = "up" | "down" | "left" | "right" | "scale" | "none";

/** Fades and moves its children in when `beat` is spoken, and out again when `until` is spoken. */
export const Appear: React.FC<{
  beat: string;
  until?: string;
  from?: From;
  delay?: number;
  distance?: number;
  style?: React.CSSProperties;
  children: React.ReactNode;
}> = ({beat, until, from = "up", delay = 0, distance = 46, style, children}) => {
  const {p, local, frame} = useProgress(beat, delay);
  const endFrame = useBeat(until ?? beat);
  const fadeIn = interpolate(local, [0, 7], [0, 1], clamp);
  const fadeOut = until ? interpolate(frame - endFrame, [0, 9], [1, 0], clamp) : 1;
  const k = 1 - p;
  const dx = from === "left" ? -distance * 1.6 * k : from === "right" ? distance * 1.6 * k : 0;
  const dy = from === "up" ? distance * k : from === "down" ? -distance * k : 0;
  const scale = from === "scale" ? 0.82 + 0.18 * p : 1;
  return (
    <div style={{...style, opacity: fadeIn * fadeOut, translate: `${dx}px ${dy}px`, scale: String(scale)}}>{children}</div>
  );
};

/** A number that counts up to `value` when `beat` is spoken (it ends on exactly the value, formatted like everywhere else). */
export const CountUp: React.FC<{
  beat: string;
  value: number;
  decimals?: number;
  seconds?: number;
  prefix?: string;
  suffix?: string;
  style?: React.CSSProperties;
}> = ({beat, value, decimals = 0, seconds = 1.4, prefix = "", suffix = "", style}) => {
  const {local, fps} = useProgress(beat);
  const k = interpolate(local, [0, seconds * fps], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  return (
    <span style={{...style, fontVariantNumeric: "tabular-nums"}}>
      {prefix}
      {num(k >= 1 ? value : value * k, decimals)}
      {suffix}
    </span>
  );
};

/** Kinetic type: each word rises into place one after the other, starting when `beat` is spoken. */
export const Words: React.FC<{beat: string; text: string; step?: number; delay?: number; style?: React.CSSProperties}> = ({beat, text, step = 0.1, delay = 0, style}) => (
  <div style={{display: "flex", flexWrap: "wrap", columnGap: "0.32em", ...style}}>
    {text.split(" ").map((word, i) => (
      <Appear key={`${word}-${i}`} beat={beat} delay={delay + i * step} distance={60} style={{display: "inline-block"}}>
        {word}
      </Appear>
    ))}
  </div>
);

/** A bordered verdict that lands with a bounce, like a rubber stamp. */
export const Stamp: React.FC<{beat: string; children: React.ReactNode; color?: string; size?: number; tilt?: number; style?: React.CSSProperties}> = ({
  beat,
  children,
  color = C.accent,
  size = 42,
  tilt = -4,
  style,
}) => {
  const {p, local} = useProgress(beat, 0, {damping: 9, stiffness: 190, mass: 0.6});
  return (
    <div
      style={{
        display: "inline-block",
        border: `6px solid ${color}`,
        color,
        padding: "8px 26px",
        fontFamily: HEAD,
        fontWeight: 400,
        textTransform: "uppercase",
        letterSpacing: "0.12em",
        fontSize: size,
        opacity: interpolate(local, [0, 4], [0, 1], clamp),
        scale: String(2.3 - 1.3 * p),
        rotate: `${tilt}deg`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

/** A line or curve that draws itself when `beat` is spoken. */
export const DrawPath: React.FC<{
  beat: string;
  d: string;
  stroke?: string;
  width?: number;
  seconds?: number;
  fill?: string;
  dash?: string;
}> = ({beat, d, stroke = C.ink, width = 5, seconds = 0.9, fill = "none", dash}) => {
  const {local, fps} = useProgress(beat);
  const k = interpolate(local, [0, seconds * fps], [0, 1], {...clamp, easing: Easing.inOut(Easing.cubic)});
  return dash ? (
    <path d={d} stroke={stroke} strokeWidth={width} fill={fill} strokeDasharray={dash} strokeLinecap="round" opacity={k > 0 ? 1 : 0} />
  ) : (
    <path d={d} stroke={stroke} strokeWidth={width} fill={fill} pathLength={1} strokeDasharray={1} strokeDashoffset={1 - k} strokeLinecap="round" />
  );
};

/** Text typed out one character at a time from the moment `beat` is spoken. */
export const Typewriter: React.FC<{beat: string; text: string; perSecond?: number; style?: React.CSSProperties}> = ({beat, text, perSecond = 28, style}) => {
  const {local, fps, frame} = useProgress(beat);
  const shown = Math.max(0, Math.min(text.length, Math.floor((local / fps) * perSecond)));
  const cursor = Math.floor(frame / 12) % 2 === 0 ? "▌" : " ";
  return (
    <span style={{fontFamily: "ui-monospace, Consolas, monospace", ...style}}>
      {text.slice(0, shown)}
      {cursor}
    </span>
  );
};

/** A gentle repeating pulse, for something that wants attention. */
export const Pulse: React.FC<{children: React.ReactNode; amount?: number; period?: number; style?: React.CSSProperties}> = ({children, amount = 0.06, period = 36, style}) => {
  const frame = useCurrentFrame();
  return <div style={{...style, scale: String(1 + amount * Math.sin((frame / period) * Math.PI * 2))}}>{children}</div>;
};

const Backdrop: React.FC<{dark: boolean}> = ({dark}) => {
  const frame = useCurrentFrame();
  const drift = (frame * 0.28) % 64;
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        opacity: dark ? 0.16 : 0.1,
        backgroundImage: `radial-gradient(circle, ${dark ? C.paper : C.ink} 1.6px, transparent 1.8px)`,
        backgroundSize: "64px 64px",
        backgroundPosition: `${drift}px ${drift}px`,
      }}
    />
  );
};

const SCENE_COUNT = 11;

/** The frame every scene sits in: drifting dot grid, heading with a drawn underline, progress rail and an entry wipe. */
export const SceneFrame: React.FC<{dark?: boolean; index: number; title?: string; bare?: boolean; children: React.ReactNode}> = ({dark, index, title, bare, children}) => {
  const frame = useCurrentFrame();
  const fg = dark ? C.paper : C.ink;
  const wipe = interpolate(frame, [0, 16], [0, 1], {...clamp, easing: Easing.bezier(0.7, 0, 0.2, 1)});
  const underline = interpolate(frame, [8, 30], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  return (
    <div style={{position: "absolute", inset: 0, backgroundColor: dark ? C.ink : C.paper, color: fg, fontFamily: BODY, overflow: "hidden"}}>
      <Backdrop dark={!!dark} />
      {title ? (
        <div style={{position: "absolute", left: 120, top: 66}}>
          <div style={{fontFamily: HEAD, fontWeight: 300, textTransform: "uppercase", letterSpacing: "0.1em", fontSize: 76, lineHeight: 1.05}}>{title}</div>
          <div style={{height: 6, width: 520 * underline, backgroundColor: C.accent, marginTop: 14}} />
        </div>
      ) : null}
      <div style={{position: "absolute", right: 120, top: 84, fontFamily: HEAD, fontWeight: 300, fontSize: 30, letterSpacing: "0.3em"}}>
        {String(index).padStart(2, "0")} / {SCENE_COUNT}
      </div>
      <div style={bare ? {position: "absolute", inset: 0} : {position: "absolute", left: 120, right: 120, top: 236, bottom: 96}}>{children}</div>
      <div style={{position: "absolute", left: 120, right: 120, bottom: 44, display: "flex", gap: 10}}>
        {Array.from({length: SCENE_COUNT}, (_, i) => (
          <div key={i} style={{flex: 1, height: 5, backgroundColor: fg, opacity: i + 1 <= index ? 1 : 0.18}} />
        ))}
      </div>
      {index > 1 && frame < 18 ? (
        <div style={{position: "absolute", inset: 0, backgroundColor: dark ? C.paper : C.ink, translate: `${wipe * 100}% 0`}}>
          <div style={{position: "absolute", left: -14, top: 0, bottom: 0, width: 14, backgroundColor: C.accent}} />
        </div>
      ) : null}
    </div>
  );
};
