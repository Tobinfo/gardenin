const profiles = [
  {
    commonName: "Hosta",
    scientificName: "Hosta",
    aliases: ["plantain lily"],
    minimumWateringDays: 4,
    maximumWateringDays: 7,
    fertilizeEveryDays: 45,
    pruneWindowMonths: [3, 4, 10, 11],
    droughtTolerance: 0.25,
    overwateringSensitivity: 0.45,
    diseaseWatchlist: ["slug damage", "leaf scorch", "crown rot"],
    careNotes: "Keep soil evenly moist. Avoid constantly wet crowns."
  },
  {
    commonName: "Tomato",
    scientificName: "Solanum lycopersicum",
    aliases: ["tomato plant"],
    minimumWateringDays: 2,
    maximumWateringDays: 4,
    fertilizeEveryDays: 21,
    pruneWindowMonths: [5, 6, 7, 8],
    droughtTolerance: 0.2,
    overwateringSensitivity: 0.35,
    diseaseWatchlist: ["early blight", "leaf spot", "powdery mildew"],
    careNotes: "Keep watering consistent and avoid wet leaves when possible."
  },
  {
    commonName: "Hydrangea",
    scientificName: "Hydrangea macrophylla",
    aliases: ["bigleaf hydrangea"],
    minimumWateringDays: 3,
    maximumWateringDays: 5,
    fertilizeEveryDays: 60,
    pruneWindowMonths: [7, 8, 9],
    droughtTolerance: 0.15,
    overwateringSensitivity: 0.4,
    diseaseWatchlist: ["leaf spot", "wilting", "powdery mildew"],
    careNotes: "Water deeply in warm weather. Prune timing depends on bloom type."
  },
  {
    commonName: "Basil",
    scientificName: "Ocimum basilicum",
    aliases: ["sweet basil"],
    minimumWateringDays: 2,
    maximumWateringDays: 3,
    fertilizeEveryDays: 30,
    pruneWindowMonths: [5, 6, 7, 8, 9],
    droughtTolerance: 0.1,
    overwateringSensitivity: 0.3,
    diseaseWatchlist: ["downy mildew", "yellowing leaves", "aphids"],
    careNotes: "Pinch tips often and water before leaves droop."
  }
];

const demoBoxes = [
  { x: 0.18, y: 0.16, width: 0.58, height: 0.64 },
  { x: 0.26, y: 0.12, width: 0.44, height: 0.72 },
  { x: 0.15, y: 0.18, width: 0.68, height: 0.56 },
  { x: 0.32, y: 0.2, width: 0.36, height: 0.52 }
];

async function identifyPlant({ imageDataUrl, imageSignature, demoIndex, focusBox }) {
  const provider = (process.env.PLANT_ID_PROVIDER || "demo").toLowerCase();

  if (provider === "plantnet" || provider === "pl@ntnet") {
    return identifyWithPlantNet({ imageDataUrl, focusBox });
  }

  if (provider !== "demo") {
    throw Object.assign(new Error(`Plant ID provider "${provider}" is not supported yet.`), {
      statusCode: 501
    });
  }

  return identifyWithDemoProvider({ imageDataUrl, imageSignature, demoIndex, focusBox });
}

async function identifyWithPlantNet({ imageDataUrl, focusBox }) {
  const apiKey = process.env.PLANTNET_API_KEY;
  const project = process.env.PLANTNET_PROJECT || "all";

  if (!apiKey) {
    throw Object.assign(new Error("PLANTNET_API_KEY is required for real plant ID."), {
      statusCode: 500
    });
  }

  if (!imageDataUrl) {
    throw Object.assign(new Error("A plant image is required for real plant ID."), {
      statusCode: 400
    });
  }

  const url = new URL(`https://my-api.plantnet.org/v2/identify/${encodeURIComponent(project)}`);
  url.searchParams.set("api-key", apiKey);
  url.searchParams.set("lang", "en");
  url.searchParams.set("nb-results", "5");
  url.searchParams.set("no-reject", "true");
  const form = new FormData();
  form.append("organs", "auto");
  form.append("images", dataUrlToBlob(imageDataUrl), "plant.jpg");

  const response = await fetch(url, {
    method: "POST",
    body: form
  });

  const result = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw Object.assign(new Error(result.message || result.error || "Pl@ntNet identification failed."), {
      statusCode: response.status
    });
  }

  const candidates = (result.results || [])
    .slice(0, 5)
    .map((suggestion) => plantNetCandidate(suggestion, focusBox))
    .filter(Boolean);

  if (candidates.length === 0) {
    throw Object.assign(new Error("Pl@ntNet did not return a plant match."), {
      statusCode: 404
    });
  }

  return {
    provider: {
      name: "Pl@ntNet",
      source: "plantnet"
    },
    candidates
  };
}

async function identifyWithDemoProvider({ imageDataUrl, imageSignature, demoIndex, focusBox }) {
  const seed = Number.isInteger(demoIndex)
    ? demoIndex
    : Number(imageSignature || imageDataUrl?.length || 0);
  const primaryIndex = Math.abs(seed) % profiles.length;
  const secondaryIndex = (primaryIndex + 1) % profiles.length;

  return {
    provider: {
      name: "GardenSnap demo",
      source: "local-demo"
    },
    candidates: [
      buildCandidate(profiles[primaryIndex], primaryIndex, 0.91),
      buildCandidate(profiles[secondaryIndex], secondaryIndex, 0.63, [])
    ].map((candidate) => ({
      ...candidate,
      observationBox: focusBox || candidate.observationBox
    }))
  };
}

function buildCandidate(profile, index, confidence, issues = issueWatchlistFor(profile)) {
  return {
    profile,
    confidence,
    observationBox: demoBoxes[index % demoBoxes.length],
    metadata: {
      providerName: "GardenSnap demo",
      providerPlantID: `demo-${profile.commonName.toLowerCase()}`,
      source: "local-demo"
    },
    issues
  };
}

function plantNetCandidate(suggestion, focusBox) {
  const species = suggestion.species || {};
  const commonNames = species.commonNames || [];
  const scientificName = species.scientificNameWithoutAuthor || species.scientificName;
  const commonName = commonNames[0] || scientificName || "Unknown plant";

  if (!commonName) {
    return null;
  }

  return {
    profile: {
      commonName,
      scientificName,
      aliases: commonNames.slice(1),
      minimumWateringDays: 3,
      maximumWateringDays: 6,
      fertilizeEveryDays: 45,
      pruneWindowMonths: [3, 4, 5, 9, 10],
      droughtTolerance: 0.35,
      overwateringSensitivity: 0.4,
      diseaseWatchlist: [],
      careNotes: "Imported from plant identification. Tune this care profile after confirming the plant."
    },
    confidence: Number(suggestion.score || 0),
    observationBox: focusBox || null,
    metadata: {
      providerName: "Pl@ntNet",
      providerPlantID: scientificName || commonName,
      source: "plantnet"
    },
    issues: []
  };
}

function issueWatchlistFor(profile) {
  const firstIssue = profile.diseaseWatchlist[0];

  if (!firstIssue) {
    return [];
  }

  return [
    {
      title: `Watch for ${firstIssue}`,
      detail: `The scan does not confirm disease, but ${profile.commonName} commonly needs checks for ${firstIssue}.`,
      severity: "watch"
    }
  ];
}

function dataUrlToBlob(dataUrl) {
  const [header, base64] = dataUrl.split(",");
  const mimeMatch = /^data:(.*?);base64$/.exec(header || "");
  const mimeType = mimeMatch?.[1] || "image/jpeg";
  const bytes = Buffer.from(base64 || "", "base64");
  return new Blob([bytes], { type: mimeType });
}

module.exports = {
  identifyPlant,
  profiles
};
