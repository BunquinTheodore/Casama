import React from "react";
import {useCurrentFrame} from "remotion";
import {C, HEAD} from "./theme";

type IconProps = {size?: number; color?: string; width?: number};

const Svg: React.FC<IconProps & {children: React.ReactNode}> = ({size = 120, color = "currentColor", width = 4, children}) => (
  <svg viewBox="0 0 100 100" width={size} height={size} fill="none" stroke={color} strokeWidth={width} strokeLinejoin="round" strokeLinecap="round" style={{overflow: "visible"}}>
    {children}
  </svg>
);

export const Parcel: React.FC<IconProps> = (props) => (
  <Svg {...props}>
    <path d="M16 32 L50 16 L84 32 L84 70 L50 86 L16 70 Z" />
    <path d="M16 32 L50 48 L84 32" />
    <path d="M50 48 L50 86" />
    <path d="M33 24 L67 40" />
  </Svg>
);

/** A house. When `lit` is true the windows glow (someone is home); otherwise they are dark. */
export const House: React.FC<IconProps & {lit?: boolean}> = ({lit = true, ...props}) => (
  <Svg {...props}>
    <path d="M8 48 L50 12 L92 48" />
    <rect x="18" y="48" width="64" height="42" />
    <rect x="42" y="64" width="16" height="26" />
    <rect x="26" y="56" width="12" height="12" fill={lit ? C.accent : "none"} stroke={lit ? C.accent : props.color ?? "currentColor"} />
    <rect x="62" y="56" width="12" height="12" fill={lit ? C.accent : "none"} stroke={lit ? C.accent : props.color ?? "currentColor"} />
  </Svg>
);

export const CloudRain: React.FC<IconProps & {drops?: boolean}> = ({drops = true, ...props}) => {
  const frame = useCurrentFrame();
  return (
    <Svg {...props}>
      <path d="M28 58 a14 14 0 0 1 2 -28 a20 20 0 0 1 38 4 a12 12 0 0 1 0 24 Z" />
      {drops
        ? [34, 50, 66].map((x, i) => {
            const y = 66 + ((frame * 1.7 + i * 9) % 26);
            return <path key={x} d={`M${x} ${y} l-3 8`} stroke={C.accent} />;
          })
        : null}
    </Svg>
  );
};

export const Drop: React.FC<IconProps> = (props) => (
  <Svg {...props}>
    <path d="M50 18 C50 18 28 44 28 60 a22 22 0 0 0 44 0 C72 44 50 18 50 18 Z" />
  </Svg>
);

export const Calendar: React.FC<IconProps & {flag?: boolean}> = ({flag = true, ...props}) => (
  <Svg {...props}>
    <rect x="14" y="22" width="72" height="64" rx="6" />
    <path d="M14 40 L86 40" />
    <path d="M34 14 L34 30 M66 14 L66 30" />
    {flag ? <path d="M42 52 L42 78 M42 52 L66 58 L42 66" stroke={C.accent} /> : null}
  </Svg>
);

export const Chart: React.FC<IconProps> = (props) => (
  <Svg {...props}>
    <path d="M18 16 L18 82 L86 82" />
    <path d="M26 68 L44 50 L58 58 L80 28" stroke={C.accent} />
    <path d="M70 28 L80 28 L80 38" stroke={C.accent} />
  </Svg>
);

export const Pin: React.FC<IconProps> = (props) => (
  <Svg {...props}>
    <path d="M50 90 C28 62 22 50 22 38 a28 28 0 0 1 56 0 C78 50 72 62 50 90 Z" />
    <circle cx="50" cy="38" r="9" />
  </Svg>
);

export const Clock: React.FC<IconProps> = (props) => (
  <Svg {...props}>
    <circle cx="50" cy="50" r="34" />
    <path d="M50 28 L50 50 L66 60" />
  </Svg>
);

/** A housemate. `home` fills the figure in; otherwise only the outline is drawn (out of the house). */
export const Person: React.FC<IconProps & {home?: boolean}> = ({home = true, ...props}) => (
  <Svg {...props}>
    <circle cx="50" cy="32" r="14" fill={home ? props.color ?? "currentColor" : "none"} />
    <path d="M22 86 C22 60 78 60 78 86 Z" fill={home ? props.color ?? "currentColor" : "none"} />
  </Svg>
);

export const Coin: React.FC<IconProps> = (props) => (
  <Svg {...props}>
    <circle cx="50" cy="50" r="36" />
    <text x="50" y="58" textAnchor="middle" fontFamily={HEAD} fontSize="24" fill={props.color ?? "currentColor"} stroke="none" letterSpacing="2">
      COD
    </text>
  </Svg>
);

export const Bell: React.FC<IconProps> = (props) => (
  <Svg {...props}>
    <path d="M30 72 L70 72 L64 58 L64 44 C64 34 58 28 50 28 C42 28 36 34 36 44 L36 58 Z" />
    <path d="M44 80 a6 6 0 0 0 12 0" />
  </Svg>
);

export const Terminal: React.FC<IconProps> = (props) => (
  <Svg {...props}>
    <rect x="12" y="20" width="76" height="60" rx="6" />
    <path d="M26 40 L40 50 L26 60" stroke={C.accent} />
    <path d="M48 62 L66 62" />
  </Svg>
);

export const Check: React.FC<IconProps> = (props) => (
  <Svg {...props}>
    <path d="M22 52 L42 72 L80 28" />
  </Svg>
);

export const Cross: React.FC<IconProps> = (props) => (
  <Svg {...props}>
    <path d="M28 28 L72 72 M72 28 L28 72" />
  </Svg>
);
