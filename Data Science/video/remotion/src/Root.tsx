import React from "react";
import {type CalculateMetadataFunction, Composition, staticFile} from "remotion";
import {Explorer, type ExplorerProps} from "./Explorer";
import {FPS, HEIGHT, WIDTH} from "./theme";

const load = (name: string) => fetch(staticFile(`data/${name}.json`)).then((r) => r.json());

// Scene lengths come from scene_timings.json (the narration audio, or the word count estimate while there is none),
// and every number on screen comes from findings.json and series.json. Run `npm run sync` to refresh the copies.
const calculateMetadata: CalculateMetadataFunction<ExplorerProps> = async () => {
  const [findings, series, reuse, timings, cues] = await Promise.all([load("findings"), load("series"), load("reuse"), load("timings"), load("cues")]);
  return {
    durationInFrames: timings.reduce((sum: number, t: {seconds: number}) => sum + Math.ceil(t.seconds * FPS), 0),
    props: {findings, series, reuse, timings, cues},
  };
};

export const RemotionRoot: React.FC = () => (
  <Composition
    id="Explorer"
    component={Explorer}
    width={WIDTH}
    height={HEIGHT}
    fps={FPS}
    durationInFrames={FPS}
    defaultProps={{findings: {}, series: {}, reuse: {}, timings: [], cues: {}} as ExplorerProps}
    calculateMetadata={calculateMetadata}
  />
);
