/**
 * Which picture appears when which words are spoken, and with which sound.
 *
 * Every visual in the video is anchored to a phrase of its scene's narration, so what is on screen is always what the
 * voice is saying. The same table drives the animation (src/cues.tsx), the sound effects (scripts/mix-sfx.mjs) and the
 * check that every phrase really exists in the narration (check.mjs). Keep it plain TypeScript with no JSX so Node can
 * read it too.
 */
export type SfxKind = "whoosh" | "swish" | "pop" | "tick" | "chime" | "thud" | "rise";
export type Beat = {phrase: string; sfx?: SfxKind; shift?: number};
export type Cue = {text: string; starts: number[]; ends: number[]};

export const BEATS: Record<string, Record<string, Beat>> = {
  title: {
    head: {phrase: "Parcels arrive"},
    nobody: {phrase: "nobody is in", sfx: "thud"},
    project: {phrase: "This is our Data Science", sfx: "swish"},
    count: {phrase: "We looked at", sfx: "rise"},
    weather: {phrase: "added weather", sfx: "pop"},
    holidays: {phrase: "public holidays", sfx: "pop"},
    ask: {phrase: "asked one simple question", sfx: "chime"},
  },
  question: {
    board: {phrase: "Casama's parcel board", sfx: "swish"},
    late: {phrase: "A late parcel", sfx: "pop"},
    cod: {phrase: "cash on delivery", sfx: "pop"},
    asked: {phrase: "We asked three questions", sfx: "whoosh"},
    q1: {phrase: "First, do parcels", sfx: "pop"},
    q2: {phrase: "Second, does a public holiday", sfx: "pop"},
    q3: {phrase: "Third, does adding", sfx: "pop"},
    promise: {phrase: "we promised to report them", sfx: "chime"},
  },
  data: {
    four: {phrase: "We used four sources", sfx: "swish"},
    orders: {phrase: "the Olist orders table", sfx: "pop"},
    customers: {phrase: "the Olist customers table", sfx: "pop"},
    apis: {phrase: "Two are free public APIs", sfx: "swish"},
    meteo: {phrase: "Open Meteo gave us", sfx: "pop"},
    nager: {phrase: "Nager Date gave us", sfx: "pop"},
    window: {phrase: "For every parcel we looked at", sfx: "rise"},
    rain: {phrase: "A heavy rain day means", sfx: "pop"},
    brazil: {phrase: "this is Brazilian data", sfx: "pop"},
    point: {phrase: "a single point per state", sfx: "tick"},
    command: {phrase: "anyone can repeat", sfx: "swish"},
  },
  cleaning: {
    start: {phrase: "We started with", sfx: "swish"},
    undelivered: {phrase: "were never delivered", sfx: "tick"},
    removed: {phrase: "we removed", sfx: "tick"},
    kept: {phrase: "of everything", sfx: "pop"},
    midnight: {phrase: "stored at midnight", sfx: "pop"},
    afternoon: {phrase: "at two in the afternoon", sfx: "tick"},
    calendar: {phrase: "later calendar day", sfx: "chime"},
    rate: {phrase: "That puts the late rate at", sfx: "rise"},
    clock: {phrase: "by the clock", sfx: "tick"},
  },
  shows: {
    median: {phrase: "The median parcel takes", sfx: "rise"},
    tenth: {phrase: "one in ten takes more than", sfx: "tick"},
    padded: {phrase: "Estimates are padded", sfx: "pop"},
    spikes: {phrase: "Lateness spikes in some months", sfx: "whoosh"},
    worst: {phrase: "was the worst", sfx: "thud"},
    seller: {phrase: "The strongest warning sign is the seller", sfx: "whoosh"},
    week: {phrase: "When a seller takes a week or more", sfx: "pop"},
    journey: {phrase: "A slow seller delays the whole journey", sfx: "pop"},
    promises: {phrase: "Short promises are broken most often", sfx: "whoosh"},
    busy: {phrase: "Busy months also tend to be late months", sfx: "pop"},
    shop: {phrase: "People shop mostly", sfx: "tick"},
  },
  weather: {
    intro: {phrase: "Now the weather and the holidays", sfx: "whoosh"},
    raw: {phrase: "In the raw numbers", sfx: "swish"},
    climbs: {phrase: "the late rate climbs", sfx: "rise"},
    account: {phrase: "But once we account for the month and the state", sfx: "whoosh"},
    factor: {phrase: "by a factor of", sfx: "pop"},
    noeffect: {phrase: "Rain on its own did not explain", sfx: "thud"},
    oddsratio: {phrase: "An odds ratio of one means no difference", sfx: "tick"},
    holidays: {phrase: "Holidays came next", sfx: "whoosh"},
    surprised: {phrase: "They surprised us", sfx: "thud"},
    opposite: {phrase: "That is the opposite of our guess", sfx: "pop"},
    why: {phrase: "We did not test why", sfx: "tick"},
    windows: {phrase: "We repeated everything", sfx: "swish"},
  },
  model: {
    trained: {phrase: "We trained a gradient boosting model", sfx: "swish"},
    before: {phrase: "bought before", sfx: "pop"},
    tested: {phrase: "tested it on", sfx: "pop"},
    split: {phrase: "We split by time rather than at random", sfx: "tick"},
    stage1: {phrase: "At purchase, it scores", sfx: "pop"},
    stage2: {phrase: "After the seller ships", sfx: "pop"},
    stage3: {phrase: "Adding weather and holidays takes it", sfx: "rise"},
    gain: {phrase: "That gain of", sfx: "chime"},
    signals: {phrase: "Of the added signals", sfx: "swish"},
    modest: {phrase: "The model is modest", sfx: "thud"},
    flagging: {phrase: "Flagging the riskiest parcels", sfx: "swish"},
    forecast: {phrase: "It is not a forecast", sfx: "tick"},
  },
  takeaways: {
    head: {phrase: "Five takeaways", sfx: "whoosh"},
    one: {phrase: "One: about", sfx: "pop"},
    two: {phrase: "Two: the", sfx: "pop"},
    three: {phrase: "Three: heavy rain", sfx: "pop"},
    four: {phrase: "Four: a public holiday", sfx: "pop"},
    five: {phrase: "Five: a model", sfx: "pop"},
  },
  casama: {
    head: {phrase: "What could Casama do with this", sfx: "whoosh"},
    ask: {phrase: "Ask for the seller", sfx: "pop"},
    warn: {phrase: "warn housemates early", sfx: "tick"},
    nudge: {phrase: "treat any warning as a nudge", sfx: "chime"},
    reuse: {phrase: "The pipeline is also reusable", sfx: "swish"},
    ph: {phrase: "the same holiday call returned", sfx: "rise"},
    coords: {phrase: "Change the coordinates"},
    final: {phrase: "the final decision about who stays home", sfx: "tick"},
  },
  limits: {
    head: {phrase: "Finally, the limits", sfx: "whoosh"},
    brazil: {phrase: "The data is Brazilian marketplace data", sfx: "pop"},
    timestamps: {phrase: "It holds timestamps only", sfx: "pop"},
    courier: {phrase: "no courier"},
    payment: {phrase: "no payment type"},
    cod: {phrase: "no cash on delivery"},
    point: {phrase: "Weather is one point per state", sfx: "pop"},
    assoc: {phrase: "These results are associations", sfx: "pop"},
    modest: {phrase: "And the model is modest", sfx: "thud"},
    credit: {phrase: "Weather data is by Open Meteo", sfx: "swish"},
  },
  credits: {
    thanks: {phrase: "Thank you for watching", sfx: "chime"},
    group: {phrase: "This was our Data Science final project", sfx: "swish"},
    sources: {phrase: "Weather data by Open Meteo dot com", sfx: "pop"},
    nager: {phrase: "public holidays from Nager Date"},
    olist: {phrase: "orders from the Olist"},
    refs: {phrase: "The full list of references", sfx: "swish"},
  },
};

/** Seconds from the start of the scene at which a beat happens (the lead in plus the moment the phrase is spoken). */
export const beatTime = (sceneId: string, key: string, cue: Cue, lead: number): number => {
  const beat = BEATS[sceneId]?.[key];
  if (!beat) throw new Error(`unknown beat ${sceneId}.${key}`);
  const at = cue.text.indexOf(beat.phrase);
  if (at < 0) throw new Error(`beat ${sceneId}.${key}: "${beat.phrase}" is not in the narration of that scene`);
  return lead + cue.starts[at] + (beat.shift ?? 0);
};
