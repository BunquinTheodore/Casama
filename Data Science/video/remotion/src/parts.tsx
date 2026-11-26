import React from "react";
import {BODY, C, HEAD} from "./theme";

/** A pill with a coloured outline, for a short fact that pops up. */
export const Chip: React.FC<{children: React.ReactNode; color?: string; fill?: string; size?: number; style?: React.CSSProperties}> = ({
  children,
  color = C.ink,
  fill = "transparent",
  size = 36,
  style,
}) => (
  <div
    style={{
      display: "inline-flex",
      alignItems: "center",
      gap: 14,
      border: `4px solid ${color}`,
      backgroundColor: fill,
      color,
      borderRadius: 999,
      padding: "10px 28px",
      fontFamily: BODY,
      fontWeight: 700,
      fontSize: size,
      whiteSpace: "nowrap",
      ...style,
    }}
  >
    {children}
  </div>
);

/** Small spaced capitals in the heading face, for labels. */
export const Cap: React.FC<{children: React.ReactNode; size?: number; style?: React.CSSProperties}> = ({children, size = 30, style}) => (
  <div style={{fontFamily: HEAD, fontWeight: 300, textTransform: "uppercase", letterSpacing: "0.2em", fontSize: size, ...style}}>{children}</div>
);

/** Supporting text sized for a video frame. */
export const Say: React.FC<{children: React.ReactNode; size?: number; style?: React.CSSProperties}> = ({children, size = 46, style}) => (
  <div style={{fontFamily: BODY, fontWeight: 600, fontSize: size, lineHeight: 1.28, ...style}}>{children}</div>
);

/** A bordered panel. */
export const Card: React.FC<{children: React.ReactNode; color?: string; width?: number | string; height?: number | string; dashed?: boolean; style?: React.CSSProperties}> = ({
  children,
  color = C.ink,
  width,
  height,
  dashed,
  style,
}) => (
  <div style={{border: `4px ${dashed ? "dashed" : "solid"} ${color}`, padding: "26px 32px", width, height, boxSizing: "border-box", ...style}}>{children}</div>
);
