/* eslint-disable @typescript-eslint/no-explicit-any */
import React, {useEffect, useState} from "react";
import {loadFont} from "@remotion/fonts";
import {AbsoluteFill, Series, useDelayRender, useVideoConfig, staticFile} from "remotion";
import type {Cue} from "./beats";
import {SceneCuesProvider} from "./cues";
import {SCENES} from "./scenes";
import {C} from "./theme";

export type Timing = {id: string; file: string | null; seconds: number; lead_seconds?: number; audio_seconds?: number; estimated: boolean};
export type ExplorerProps = {findings: any; series: any; reuse: any; timings: Timing[]; cues: Record<string, Cue>};

const useFonts = () => {
  const {delayRender, continueRender} = useDelayRender();
  const [handle] = useState(() => delayRender("fonts"));
  useEffect(() => {
    Promise.all([
      loadFont({family: "Josefin Sans", url: staticFile("fonts/JosefinSans.woff2"), weight: "300"}),
      loadFont({family: "Manrope", url: staticFile("fonts/Manrope.woff2"), weight: "400 700"}),
    ]).then(() => continueRender(handle));
  }, [handle, continueRender]);
};

// The narration is mixed in separately (scripts/render-final.mjs), so the picture is always rendered muted.
export const Explorer: React.FC<ExplorerProps> = ({findings, series, reuse, timings, cues}) => {
  const {fps} = useVideoConfig();
  useFonts();
  return (
    <AbsoluteFill style={{backgroundColor: C.paper}}>
      <Series>
        {timings.map((t) => {
          const Scene = SCENES[t.id];
          return (
            <Series.Sequence key={t.id} name={t.id} durationInFrames={Math.ceil(t.seconds * fps)}>
              <SceneCuesProvider sceneId={t.id} cue={cues[t.id]} lead={t.lead_seconds ?? 0}>
                <Scene findings={findings} series={series} reuse={reuse} />
              </SceneCuesProvider>
            </Series.Sequence>
          );
        })}
      </Series>
    </AbsoluteFill>
  );
};
