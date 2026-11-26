import React from "react";
import {Easing, interpolate} from "remotion";
import {num} from "./format";
import {useProgress} from "./motion";
import {C, HEAD} from "./theme";

const clamp = {extrapolateLeft: "clamp", extrapolateRight: "clamp"} as const;

export type ForestRow = {label: string; value: number; lo: number; hi: number; beat: string; hot?: boolean; small?: boolean};

const LOW = 0.35;
const HIGH = 1.7;

/** Odds ratios on a log scale. The dashed line at one means "no difference": an interval that crosses it cannot be told apart from no effect. */
export const ForestPlot: React.FC<{rows: ForestRow[]; width: number; fg: string; lineBeat: string; pulseBeat?: string; bg?: string; rowHeight?: number}> = ({rows, width, fg, lineBeat, pulseBeat, bg = C.ink, rowHeight = 118}) => {
  const left = 250;
  const right = width - 30;
  const x = (v: number) => left + ((Math.log(v) - Math.log(LOW)) / (Math.log(HIGH) - Math.log(LOW))) * (right - left);
  const height = rows.length * rowHeight + 190;
  const line = useProgress(lineBeat);
  const flash = useProgress(pulseBeat ?? lineBeat);
  const drawn = interpolate(line.local, [0, 20], [0, 1], clamp);
  const pulse = pulseBeat ? interpolate(flash.local, [0, 8, 36], [0, 1, 0], clamp) : 0;
  return (
    <svg width={width} height={height} style={{overflow: "visible"}}>
      <line x1={x(1)} x2={x(1)} y1={40} y2={rows.length * rowHeight + 66} stroke={pulse > 0.05 ? C.accent : fg} strokeWidth={4 + 8 * pulse} strokeDasharray="10 10" opacity={0.85 * drawn + 0.15 * pulse} strokeDashoffset={(1 - drawn) * 60} />
      <text x={x(1)} y={24} textAnchor="middle" fontSize={28} fontWeight={700} fill={pulse > 0.05 ? C.accent : fg} opacity={drawn}>
        one means no difference
      </text>
      {rows.map((row, i) => (
        <ForestMark key={row.label} row={row} y={i * rowHeight + rowHeight / 2 + 60} x={x} fg={fg} bg={bg} left={left} />
      ))}
      {[0.5, 1, 1.5].map((tick) => (
        <g key={tick}>
          <line x1={x(tick)} x2={x(tick)} y1={rows.length * rowHeight + 70} y2={rows.length * rowHeight + 84} stroke={fg} strokeWidth={3} />
          <text x={x(tick)} y={rows.length * rowHeight + 116} textAnchor="middle" fontSize={26} fontWeight={600} fill={fg}>
            {num(tick, 1)}
          </text>
        </g>
      ))}
      <text x={left} y={rows.length * rowHeight + 164} fontSize={26} fontWeight={600} fill={fg} opacity={0.85}>
        fewer late parcels
      </text>
      <text x={right} y={rows.length * rowHeight + 164} textAnchor="end" fontSize={26} fontWeight={600} fill={fg} opacity={0.85}>
        more late parcels
      </text>
    </svg>
  );
};

const ForestMark: React.FC<{row: ForestRow; y: number; x: (v: number) => number; fg: string; bg: string; left: number}> = ({row, y, x, fg, bg, left}) => {
  const {local, p} = useProgress(row.beat, 0, {damping: 11, stiffness: 160, mass: 0.7});
  const color = row.hot ? C.accent : fg;
  const reach = interpolate(local, [4, 26], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  const centre = x(row.value);
  const lo = centre + (x(row.lo) - centre) * reach;
  const hi = centre + (x(row.hi) - centre) * reach;
  const small = row.small;
  return (
    <g opacity={interpolate(local, [0, 6], [0, 1], clamp)}>
      <text x={left - 26} y={y + 10} textAnchor="end" fontFamily={HEAD} fontSize={small ? 30 : 38} fontWeight={300} fill={fg} style={{textTransform: "uppercase"}} letterSpacing={2}>
        {row.label}
      </text>
      <line x1={lo} x2={hi} y1={y} y2={y} stroke={color} strokeWidth={small ? 6 : 10} strokeLinecap="round" />
      <circle cx={centre} cy={y} r={(small ? 11 : 17) * p} fill={color} />
      <text x={centre} y={y - (small ? 24 : 34)} textAnchor="middle" fontSize={small ? 26 : 32} fontWeight={700} fill={color} stroke={bg} strokeWidth={10} strokeLinejoin="round" paintOrder="stroke" opacity={reach}>
        {num(row.value, 2)} ({num(row.lo, 2)} to {num(row.hi, 2)})
      </text>
    </g>
  );
};

/** A ring that fills to `value` percent when its beat is spoken. */
export const Donut: React.FC<{beat: string; value: number; label: string; size?: number; fg: string; color?: string}> = ({beat, value, label, size = 250, fg, color = C.accent}) => {
  const {local} = useProgress(beat);
  const k = interpolate(local, [0, 40], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  const radius = size / 2 - 22;
  const circumference = 2 * Math.PI * radius;
  return (
    <div style={{width: size, textAlign: "center"}}>
      <svg width={size} height={size}>
        <circle cx={size / 2} cy={size / 2} r={radius} fill="none" stroke={fg} strokeOpacity={0.18} strokeWidth={22} />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth={22}
          strokeDasharray={`${(circumference * value * k) / 100} ${circumference}`}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
          strokeLinecap="butt"
        />
        <text x={size / 2} y={size / 2 + 14} textAnchor="middle" fontFamily={HEAD} fontWeight={300} fontSize={56} fill={fg}>
          {num(value * k, 1)}%
        </text>
      </svg>
      <div style={{fontSize: 30, fontWeight: 600, marginTop: 6}}>{label}</div>
    </div>
  );
};

/** Orders by hour of the day, the busiest hour in the accent colour. */
export const HourBars: React.FC<{rows: {hour: number; orders: number}[]; width: number; height: number; fg: string; beat: string}> = ({rows, width, height, fg, beat}) => {
  const {local} = useProgress(beat);
  const top = Math.max(...rows.map((r) => r.orders));
  const peak = rows.find((r) => r.orders === top)?.hour;
  const step = width / rows.length;
  return (
    <svg width={width} height={height + 44}>
      <line x1={0} x2={width} y1={height} y2={height} stroke={fg} strokeWidth={3} />
      {rows.map((r, i) => {
        const grow = interpolate(local - i * 1.2, [0, 18], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
        const h = (r.orders / top) * (height - 20) * grow;
        return (
          <g key={r.hour}>
            <rect x={step * i + step * 0.12} y={height - h} width={step * 0.76} height={h} fill={r.hour === peak ? C.accent : fg} />
            {r.hour % 3 === 0 ? (
              <text x={step * i + step / 2} y={height + 34} textAnchor="middle" fontSize={24} fontWeight={600} fill={fg}>
                {r.hour}
              </text>
            ) : null}
          </g>
        );
      })}
    </svg>
  );
};

/** Orders per month as pale bars and the late rate as a line that draws itself over them. */
export const VolumeLate: React.FC<{rows: {orders: number; late_pct: number}[]; width: number; height: number; fg: string; beat: string}> = ({rows, width, height, fg, beat}) => {
  const {local} = useProgress(beat);
  const step = width / rows.length;
  const maxOrders = Math.max(...rows.map((r) => r.orders));
  const maxLate = Math.max(...rows.map((r) => r.late_pct)) * 1.1;
  const points = rows.map((r, i) => `${step * (i + 0.5)},${height - (r.late_pct / maxLate) * (height - 24)}`).join(" ");
  const reveal = interpolate(local, [0, 70], [0, 1], {...clamp, easing: Easing.inOut(Easing.cubic)});
  return (
    <svg width={width} height={height + 8}>
      {rows.map((r, i) => (
        <rect key={i} x={step * i + step * 0.15} y={height - (r.orders / maxOrders) * (height - 24) * Math.min(1, reveal * 2)} width={step * 0.7} height={(r.orders / maxOrders) * (height - 24) * Math.min(1, reveal * 2)} fill={fg} opacity={0.22} />
      ))}
      <polyline points={points} fill="none" stroke={C.accent} strokeWidth={7} strokeLinejoin="round" strokeLinecap="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - reveal} />
      <line x1={0} x2={width} y1={height} y2={height} stroke={fg} strokeWidth={3} />
    </svg>
  );
};
