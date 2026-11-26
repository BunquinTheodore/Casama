import React from "react";
import {Cleaning, Data, Question, Title} from "./scenes-a";
import {Model, Shows, Weather} from "./scenes-b";
import {Casama, Takeaways} from "./scenes-c";
import {Credits, Limits} from "./scenes-d";
import type {SceneProps} from "./types";

export type {SceneProps} from "./types";

// One component per scene id; the order and the lengths come from video/scene_timings.json.
export const SCENES: Record<string, React.FC<SceneProps>> = {
  title: Title,
  question: Question,
  data: Data,
  cleaning: Cleaning,
  shows: Shows,
  weather: Weather,
  model: Model,
  takeaways: Takeaways,
  casama: Casama,
  limits: Limits,
  credits: Credits,
};
