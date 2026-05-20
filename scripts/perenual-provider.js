function hasPerenualKey() {
  return Boolean(process.env.PERENUAL_API_KEY);
}

async function searchPerenualPlant(queryInput) {
  const apiKey = process.env.PERENUAL_API_KEY;
  const query = String(queryInput || "").trim();

  if (!apiKey) {
    throw Object.assign(new Error("PERENUAL_API_KEY is required for Perenual lookups."), {
      statusCode: 500
    });
  }

  if (!query) {
    throw Object.assign(new Error("Plant search query is required."), {
      statusCode: 400
    });
  }

  const searchUrl = new URL("https://perenual.com/api/v2/species-list");
  searchUrl.searchParams.set("key", apiKey);
  searchUrl.searchParams.set("q", query);
  searchUrl.searchParams.set("page", "1");

  const searchResult = await fetchJson(searchUrl);
  const firstMatch = searchResult.data?.[0];
  if (!firstMatch?.id) {
    return {
      source: "Perenual",
      query,
      match: null
    };
  }

  const detailsUrl = new URL(`https://perenual.com/api/v2/species/details/${encodeURIComponent(firstMatch.id)}`);
  detailsUrl.searchParams.set("key", apiKey);
  const details = await fetchJson(detailsUrl);

  return {
    source: "Perenual",
    query,
    match: normalizePerenualPlant(details || firstMatch)
  };
}

async function fetchJson(url) {
  const response = await fetch(url, {
    headers: {
      "accept": "application/json",
      "user-agent": "gardenin prototype plant data lookup"
    }
  });
  const body = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw Object.assign(new Error(body.message || body.error || "Perenual request failed."), {
      statusCode: response.status
    });
  }

  if (body?.error) {
    throw Object.assign(new Error(String(body.error)), {
      statusCode: 502
    });
  }

  return body;
}

function normalizePerenualPlant(plant) {
  return {
    id: plant.id || null,
    commonName: plant.common_name || plant.commonName || null,
    scientificName: Array.isArray(plant.scientific_name)
      ? plant.scientific_name[0]
      : plant.scientific_name || plant.scientificName || null,
    otherNames: plant.other_name || [],
    cycle: plant.cycle || null,
    watering: plant.watering || null,
    sunlight: plant.sunlight || [],
    hardiness: plant.hardiness || null,
    careLevel: plant.care_level || null,
    description: plant.description || null,
    defaultImage: plant.default_image?.regular_url || plant.default_image?.thumbnail || null
  };
}

module.exports = {
  hasPerenualKey,
  searchPerenualPlant
};
