import React from "react";
import {AbsoluteFill, Easing, interpolate, useCurrentFrame, useVideoConfig} from "remotion";
import {BODY, C, HEAD, SIZE} from "./theme";

// One rounding rule shared with the explorer page, so a figure reads identically on the page and in the video.
import {num} from "./format";
export {num, pct} from "./format";

const EASE = Easing.bezier(0.16, 1, 0.3, 1);

export const Scene: React.FC<{dark?: boolean; children: React.ReactNode}> = ({dark, children}) => (
  <AbsoluteFill
    style={{
      backgroundColor: dark ? C.ink : C.paper,
      color: dark ? C.paper : C.ink,
      fontFamily: BODY,
      padding: "96px 120px",
    }}
  >
    {children}
  </AbsoluteFill>
);

/** Fades and lifts its children in at a fraction (0 to 1) of the scene, so timing follows the narration length. */
export const Reveal: React.FC<{at: number; children: React.ReactNode; style?: React.CSSProperties}> = ({at, children, style}) => {
  const frame = useCurrentFrame();
  const {durationInFrames, fps} = useVideoConfig();
  const start = at * durationInFrames;
  return (
    <div
      style={{
        ...style,
        opacity: interpolate(frame, [start, start + 0.7 * fps], [0, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: EASE}),
        translate: interpolate(frame, [start, start + 0.7 * fps], ["0px 28px", "0px 0px"], {extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: EASE}),
      }}
    >
      {children}
    </div>
  );
};

export const Heading: React.FC<{children: React.ReactNode; size?: number}> = ({children, size = SIZE.headline}) => (
  <div style={{fontFamily: HEAD, fontWeight: 300, textTransform: "uppercase", letterSpacing: "0.1em", fontSize: size, lineHeight: 1.1}}>
    {children}
  </div>
);

export const Support: React.FC<{children: React.ReactNode; style?: React.CSSProperties}> = ({children, style}) => (
  <div style={{fontSize: SIZE.support, lineHeight: 1.3, fontWeight: 500, ...style}}>{children}</div>
);

export const Source: React.FC<{children: React.ReactNode}> = ({children}) => (
  <div style={{fontSize: SIZE.source, letterSpacing: "0.06em", opacity: 0.85, marginTop: 14}}>{children}</div>
);

export type BarRow = {label: string; value: number; lo?: number | null; hi?: number | null; hot?: boolean};

const useGrow = (start: number, index: number) => {
  const frame = useCurrentFrame();
  return interpolate(frame - start - index * 5, [0, 26], [0, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: EASE});
};

const Bar: React.FC<{x: number; w: number; base: number; h: number; fg: string; row: BarRow; start: number; index: number; unit: string; decimals: number; top: number; scale: (v: number) => number; showValue: boolean}> = ({x, w, base, h, fg, row, start, index, unit, decimals, top, scale, showValue}) => {
  const grow = useGrow(start, index);
  const barH = h * grow;
  const labelY = row.hi != null ? scale(row.hi) : base - barH;
  return (
    <g>
      <rect x={x - w / 2} y={base - barH} width={w} height={barH} fill={row.hot ? C.accent : fg} />
      {row.lo != null && row.hi != null && grow > 0.95 ? (
        <line x1={x} x2={x} y1={scale(row.lo)} y2={scale(row.hi)} stroke={row.hot ? fg : C.accent} strokeWidth={6} />
      ) : null}
      {showValue ? (
        <text x={x} y={Math.max(top, labelY - 14)} textAnchor="middle" fontSize={SIZE.label + 4} fontWeight={700} fill={fg} opacity={grow}>
          {num(row.value, decimals)}
          {unit}
        </text>
      ) : null}
    </g>
  );
};

export const Bars: React.FC<{
  rows: BarRow[];
  width: number;
  height: number;
  fg: string;
  unit?: string;
  decimals?: number;
  min?: number;
  max?: number;
  tickEvery?: number;
  start?: number;
  /** "hot" prints a value only above highlighted bars, for charts with too many bars to label each one. */
  labels?: "all" | "hot";
}> = ({rows, width, height, fg, unit = "", decimals = 1, min = 0, max, tickEvery = 1, start = 0, labels = "all"}) => {
  const top = 40;
  const base = height - 70;
  const plotH = base - top - 40;
  const top0 = Math.max(...rows.map((r) => r.hi ?? r.value));
  const hi = max ?? top0 * 1.12;
  const scale = (v: number) => base - ((v - min) / (hi - min)) * plotH;
  const step = width / rows.length;
  return (
    <svg width={width} height={height} style={{overflow: "visible"}}>
      <line x1={0} x2={width} y1={base} y2={base} stroke={fg} strokeWidth={3} />
      {rows.map((r, i) => (
        <g key={r.label + i}>
          <Bar x={step * (i + 0.5)} w={step * 0.6} base={base} h={base - scale(r.value)} fg={fg} row={r} start={start} index={i} unit={unit} decimals={decimals} top={top} scale={scale} showValue={labels === "all" || !!r.hot} />
          {i % tickEvery === 0 ? (
            <text x={step * (i + 0.5)} y={base + 46} textAnchor="middle" fontSize={SIZE.label} fontWeight={600} fill={fg}>
              {r.label}
            </text>
          ) : null}
        </g>
      ))}
    </svg>
  );
};

export const HBars: React.FC<{rows: BarRow[]; width: number; fg: string; decimals?: number; labelWidth?: number; rowHeight?: number; start?: number; unit?: string}> = ({rows, width, fg, decimals = 0, labelWidth = 600, rowHeight = 96, start = 0, unit = ""}) => {
  const maxV = Math.max(...rows.map((r) => Math.max(r.value, 0))) || 1;
  const barArea = width - labelWidth - 220;
  return (
    <svg width={width} height={rows.length * rowHeight} style={{overflow: "visible"}}>
      {rows.map((r, i) => (
        <HRow key={r.label} row={r} y={i * rowHeight} labelWidth={labelWidth} barArea={barArea} maxV={maxV} fg={fg} decimals={decimals} start={start} index={i} h={rowHeight - 28} unit={unit} />
      ))}
    </svg>
  );
};

const HRow: React.FC<{row: BarRow; y: number; labelWidth: number; barArea: number; maxV: number; fg: string; decimals: number; start: number; index: number; h: number; unit: string}> = ({row, y, labelWidth, barArea, maxV, fg, decimals, start, index, h, unit}) => {
  const grow = useGrow(start, index);
  const len = (barArea * Math.max(row.value, 0)) / maxV;
  return (
    <g>
      <text x={labelWidth - 24} y={y + h / 2 + 11} textAnchor="end" fontSize={SIZE.label + 2} fontWeight={600} fill={fg}>
        {row.label}
      </text>
      <rect x={labelWidth} y={y} width={len * grow} height={h} fill={row.hot ? C.accent : fg} />
      <text x={labelWidth + len * grow + 20} y={y + h / 2 + 11} fontSize={SIZE.label + 4} fontWeight={700} fill={fg} opacity={grow}>
        {num(row.value, decimals)}
        {unit}
      </text>
    </g>
  );
};

export const Stat: React.FC<{value: string; label: string; at: number}> = ({value, label, at}) => (
  <Reveal at={at}>
    <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 120, letterSpacing: "0.04em", lineHeight: 1}}>{value}</div>
    <div style={{fontFamily: HEAD, fontWeight: 300, fontSize: 30, letterSpacing: "0.2em", textTransform: "uppercase", marginTop: 14}}>{label}</div>
  </Reveal>
);
