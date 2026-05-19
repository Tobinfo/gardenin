const http = require("node:http");
const fs = require("node:fs/promises");
const path = require("node:path");

loadLocalEnv();

const { identifyPlant } = require("./plant-id-provider");

const root = path.resolve(__dirname, "..", "prototype");
const port = Number(process.env.PORT || 5173);
const host = process.env.HOST || "0.0.0.0";

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
    if (request.method === "GET" && request.url === "/api/status") {
      writeJson(response, 200, {
        plantIdProvider: process.env.PLANT_ID_PROVIDER || "demo",
        hasPlantNetKey: Boolean(process.env.PLANTNET_API_KEY)
      });
      return;
    }

    if (request.method === "POST" && request.url === "/api/identify") {
      const body = await readJsonBody(request);
      const result = await identifyPlant(body);
      writeJson(response, 200, result);
      return;
    }

    const requestUrl = new URL(request.url, `http://${host}:${port}`);
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
    if (request.url === "/api/identify") {
      writeJson(response, error.statusCode || 500, {
        error: error.message || "Unable to identify plant."
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
    "cache-control": "no-store"
  });
  response.end(JSON.stringify(body));
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
