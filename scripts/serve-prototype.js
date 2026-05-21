const http = require("node:http");
const fs = require("node:fs/promises");
const path = require("node:path");
const crypto = require("node:crypto");

loadLocalEnv();

const { identifyPlant } = require("./plant-id-provider");
const { mobileApiContract } = require("./mobile-contract");
const { hasPerenualKey, searchPerenualPlant } = require("./perenual-provider");

const root = path.resolve(__dirname, "..", "prototype");
const port = Number(process.env.PORT || 5173);
const host = process.env.HOST || "0.0.0.0";
const identifyRateWindowMs = Number(process.env.IDENTIFY_RATE_WINDOW_MS || 60_000);
const identifyRateLimit = Number(process.env.IDENTIFY_RATE_LIMIT || 24);
const identifyUserKeyRateLimit = Number(process.env.IDENTIFY_USER_KEY_RATE_LIMIT || 60);
const requireUserPlantNetApiKey = process.env.REQUIRE_USER_PLANTNET_API_KEY === "true";
const identifyRateBuckets = new Map();

const mimeTypes = new Map([
  [".html", "text/html; charset=utf-8"],
  [".css", "text/css; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".png", "image/png"],
  [".jpg", "image/jpeg"],
  [".jpeg", "image/jpeg"],
  [".svg", "image/svg+xml"]
]);

const server = http.createServer(async (request, response) => {
  try {
    const requestUrl = new URL(request.url, `http://${host}:${port}`);

    if (request.method === "GET" && requestUrl.pathname === "/api/status") {
      writeJson(response, 200, {
        plantIdProvider: process.env.PLANT_ID_PROVIDER || "demo",
        hasPlantNetKey: Boolean(process.env.PLANTNET_API_KEY),
        hasPerenualKey: hasPerenualKey(),
        acceptsUserPlantNetKey: true,
        requiresUserPlantNetKey: requireUserPlantNetApiKey,
        identifyRateLimitPerMinute: Math.round(identifyRateLimit * 60_000 / identifyRateWindowMs),
        identifyUserKeyRateLimitPerMinute: Math.round(identifyUserKeyRateLimit * 60_000 / identifyRateWindowMs),
        contractVersion: mobileApiContract.version
      });
      return;
    }

    if (request.method === "GET" && requestUrl.pathname === "/api/mobile-contract") {
      writeJson(response, 200, mobileApiContract);
      return;
    }

    if (request.method === "GET" && requestUrl.pathname === "/api/perenual/search") {
      const result = await searchPerenualPlant(requestUrl.searchParams.get("q"));
      writeJson(response, 200, result);
      return;
    }

    if (request.method === "GET" && requestUrl.pathname === "/api/weather") {
      const result = await weatherForZip(requestUrl.searchParams.get("zip"));
      writeJson(response, 200, result);
      return;
    }

    if (request.method === "POST" && requestUrl.pathname === "/api/identify") {
      const rawBody = await readJsonBody(request);
      const userPlantNetApiKey = userPlantNetApiKeyFrom(request, rawBody);
      checkIdentifyRateLimit(request, Boolean(userPlantNetApiKey));
      const body = validateIdentifyPayload(rawBody);
      const result = await identifyPlant(body, {
        plantNetApiKey: userPlantNetApiKey,
        requireUserPlantNetApiKey
      });
      writeJson(response, 200, result);
      return;
    }

    const requestPath = requestUrl.pathname === "/" ? "/index.html" : decodeURIComponent(requestUrl.pathname);
    const filePath = path.normalize(path.join(root, requestPath));

    if (!filePath.startsWith(root)) {
      response.writeHead(403);
      response.end("Forbidden");
      return;
    }

    const body = await fs.readFile(filePath);
    response.writeHead(200, {
      "content-type": mimeTypes.get(path.extname(filePath)) || "application/octet-stream",
      "cache-control": "no-store"
    });
    response.end(body);
  } catch (error) {
    if (request.url?.startsWith("/api/")) {
      writeJson(response, error.statusCode || 500, {
        error: error.message || "Request failed."
      });
      return;
    }

    response.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
    response.end("Not found");
  }
});

server.listen(port, host, () => {
  const displayHost = host === "0.0.0.0" ? "127.0.0.1" : host;
  console.log(`GardenSnap prototype: http://${displayHost}:${port}`);
  console.log(`Plant ID provider: ${process.env.PLANT_ID_PROVIDER || "demo"}`);
});

async function weatherForZip(zipInput) {
  const zip = String(zipInput || "").trim();
  if (!/^\d{5}$/.test(zip)) {
    throw Object.assign(new Error("Enter a 5-digit ZIP code."), { statusCode: 400 });
  }

  const geocodeUrl = new URL("https://geocoding-api.open-meteo.com/v1/search");
  geocodeUrl.searchParams.set("name", zip);
  geocodeUrl.searchParams.set("count", "1");
  geocodeUrl.searchParams.set("countryCode", "US");
  geocodeUrl.searchParams.set("language", "en");
  geocodeUrl.searchParams.set("format", "json");

  const geocode = await fetchJson(geocodeUrl);
  const place = geocode.results?.[0];
  if (!place) {
    throw Object.assign(new Error("Weather location was not found for that ZIP."), { statusCode: 404 });
  }

  const forecastUrl = new URL("https://api.open-meteo.com/v1/forecast");
  forecastUrl.searchParams.set("latitude", String(place.latitude));
  forecastUrl.searchParams.set("longitude", String(place.longitude));
  forecastUrl.searchParams.set("current", "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code");
  forecastUrl.searchParams.set("daily", "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max");
  forecastUrl.searchParams.set("temperature_unit", "fahrenheit");
  forecastUrl.searchParams.set("wind_speed_unit", "mph");
  forecastUrl.searchParams.set("precipitation_unit", "inch");
  forecastUrl.searchParams.set("timezone", "auto");
  forecastUrl.searchParams.set("forecast_days", "7");

  const weather = await fetchJson(forecastUrl);
  const daily = weather.daily || {};
  const days = (daily.time || []).map((date, index) => ({
    date,
    highFahrenheit: Number(daily.temperature_2m_max?.[index] || 0),
    lowFahrenheit: Number(daily.temperature_2m_min?.[index] || 0),
    precipitationInches: Number(daily.precipitation_sum?.[index] || 0),
    precipitationProbability: Number(daily.precipitation_probability_max?.[index] || 0) / 100,
    humidity: Number(weather.current?.relative_humidity_2m || 55) / 100,
    windMph: Number(weather.current?.wind_speed_10m || 0),
    condition: weatherCodeLabel(daily.weather_code?.[index])
  }));

  return {
    source: "Open-Meteo",
    zip,
    place: [place.name, place.admin1].filter(Boolean).join(", "),
    current: {
      temperatureF: Number(weather.current?.temperature_2m || days[0]?.highFahrenheit || 0),
      humidity: Number(weather.current?.relative_humidity_2m || 55) / 100,
      windMph: Number(weather.current?.wind_speed_10m || 0),
      condition: weatherCodeLabel(weather.current?.weather_code)
    },
    forecast: days
  };
}

async function fetchJson(url) {
  const response = await fetch(url, {
    headers: {
      "user-agent": "floraos prototype weather lookup"
    }
  });
  const body = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw Object.assign(new Error(body.reason || body.error || "Weather provider failed."), {
      statusCode: response.status
    });
  }

  return body;
}

function weatherCodeLabel(codeInput) {
  const code = Number(codeInput);
  if ([0].includes(code)) return "Clear";
  if ([1, 2, 3].includes(code)) return "Partly cloudy";
  if ([45, 48].includes(code)) return "Fog";
  if ([51, 53, 55, 56, 57].includes(code)) return "Drizzle";
  if ([61, 63, 65, 66, 67, 80, 81, 82].includes(code)) return "Rain";
  if ([71, 73, 75, 77, 85, 86].includes(code)) return "Snow";
  if ([95, 96, 99].includes(code)) return "Thunderstorm";
  return "Partly cloudy";
}

function readJsonBody(request) {
  return new Promise((resolve, reject) => {
    let body = "";

    request.on("data", (chunk) => {
      body += chunk;
      if (body.length > 8_000_000) {
        reject(Object.assign(new Error("Image payload is too large."), { statusCode: 413 }));
        request.destroy();
      }
    });

    request.on("end", () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch {
        reject(Object.assign(new Error("Request body must be valid JSON."), { statusCode: 400 }));
      }
    });

    request.on("error", reject);
  });
}

function writeJson(response, statusCode, body) {
  response.writeHead(statusCode, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    "x-content-type-options": "nosniff"
  });
  response.end(JSON.stringify(body));
}

function userPlantNetApiKeyFrom(request, body) {
  const value = String(request.headers["x-plantnet-api-key"] || body?.plantNetApiKey || "").trim();
  if (!value) {
    return "";
  }

  if (!/^[A-Za-z0-9._:-]{8,180}$/.test(value)) {
    throw Object.assign(new Error("Pl@ntNet API key format is invalid."), { statusCode: 400 });
  }

  return value;
}

function validateIdentifyPayload(body) {
  if (!body || typeof body !== "object") {
    throw Object.assign(new Error("Request body must be an object."), { statusCode: 400 });
  }

  const imageDataUrl = String(body.imageDataUrl || "");
  if (!/^data:image\/(?:jpeg|jpg|png|webp);base64,[A-Za-z0-9+/=\s]+$/.test(imageDataUrl)) {
    throw Object.assign(new Error("A JPEG, PNG, or WebP crop image is required."), { statusCode: 400 });
  }

  if (imageDataUrl.length > 7_500_000) {
    throw Object.assign(new Error("Crop image is too large."), { statusCode: 413 });
  }

  return {
    imageDataUrl,
    imageSignature: Number.isFinite(Number(body.imageSignature)) ? Number(body.imageSignature) : undefined,
    demoIndex: Number.isInteger(body.demoIndex) ? body.demoIndex : undefined,
    focusBox: validateFocusBox(body.focusBox),
    mode: validateMode(body.mode)
  };
}

function validateFocusBox(box) {
  if (!box || typeof box !== "object") {
    return undefined;
  }

  const x = Number(box.x);
  const y = Number(box.y);
  const width = Number(box.width);
  const height = Number(box.height);
  const values = [x, y, width, height];
  const isValid = values.every(Number.isFinite) &&
    x >= 0 &&
    y >= 0 &&
    width > 0 &&
    height > 0 &&
    x + width <= 1.01 &&
    y + height <= 1.01;

  if (!isValid) {
    throw Object.assign(new Error("focusBox must use normalized crop coordinates."), { statusCode: 400 });
  }

  return { x, y, width, height };
}

function validateMode(mode) {
  const value = String(mode || "garden-scan");
  return ["garden-scan", "id-only", "training"].includes(value) ? value : "garden-scan";
}

function checkIdentifyRateLimit(request, hasUserPlantNetApiKey) {
  const now = Date.now();
  const client = clientIdentity(request);
  const limit = hasUserPlantNetApiKey ? identifyUserKeyRateLimit : identifyRateLimit;
  const bucketKey = `${client}:${hasUserPlantNetApiKey ? "user-key" : "server-key"}`;
  const bucket = identifyRateBuckets.get(bucketKey) || {
    count: 0,
    resetAt: now + identifyRateWindowMs
  };

  if (bucket.resetAt <= now) {
    bucket.count = 0;
    bucket.resetAt = now + identifyRateWindowMs;
  }

  bucket.count += 1;
  identifyRateBuckets.set(bucketKey, bucket);
  pruneIdentifyRateBuckets(now);

  if (bucket.count > limit) {
    throw Object.assign(new Error("Too many plant ID requests. Wait a minute, then try again."), {
      statusCode: 429
    });
  }
}

function clientIdentity(request) {
  const forwarded = String(request.headers["x-forwarded-for"] || "").split(",")[0].trim();
  const raw = forwarded || request.socket.remoteAddress || "unknown";
  return crypto.createHash("sha256").update(raw).digest("hex").slice(0, 16);
}

function pruneIdentifyRateBuckets(now) {
  if (identifyRateBuckets.size < 500) {
    return;
  }

  for (const [key, bucket] of identifyRateBuckets) {
    if (bucket.resetAt <= now) {
      identifyRateBuckets.delete(key);
    }
  }
}

function loadLocalEnv() {
  const envPath = path.resolve(__dirname, "..", ".env");

  try {
    const contents = require("node:fs").readFileSync(envPath, "utf8");
    for (const line of contents.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) {
        continue;
      }

      const separatorIndex = trimmed.indexOf("=");
      if (separatorIndex === -1) {
        continue;
      }

      const key = trimmed.slice(0, separatorIndex).trim();
      const value = trimmed.slice(separatorIndex + 1).trim().replace(/^["']|["']$/g, "");
      if (key && process.env[key] === undefined) {
        process.env[key] = value;
      }
    }
  } catch {
    // Local env file is optional.
  }
}
