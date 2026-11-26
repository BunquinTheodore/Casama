import React, {createContext, useContext} from "react";
import {useVideoConfig} from "remotion";
import {beatTime, type Cue} from "./beats";

type SceneCues = {sceneId: string; cue: Cue; lead: number};
const Ctx = createContext<SceneCues | null>(null);

/** Gives everything inside one scene access to the spoken timing of that scene's narration. */
export const SceneCuesProvider: React.FC<SceneCues & {children: React.ReactNode}> = ({sceneId, cue, lead, children}) => (
  <Ctx.Provider value={{sceneId, cue, lead}}>{children}</Ctx.Provider>
);

/** The frame (inside the scene) at which the words of a beat start to be spoken. */
export const useBeat = (key: string): number => {
  const ctx = useContext(Ctx);
  const {fps} = useVideoConfig();
  if (!ctx) throw new Error("useBeat needs a SceneCuesProvider around it");
  return Math.round(beatTime(ctx.sceneId, key, ctx.cue, ctx.lead) * fps);
};
