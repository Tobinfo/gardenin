const mobileApiContract = {
  version: "2026-05-20.1",
  product: "gardenin",
  principles: [
    "Mobile clients never store external provider API keys.",
    "Durable photo storage is crop-only by default.",
    "Garden tracking and ID-only identification are separate modes.",
    "One-time location is explicit and does not require reverse geocoding.",
    "Data shapes stay consistent across web, Android, and iOS."
  ],
  activeEndpoints: [
    {
      method: "GET",
      path: "/api/status",
      purpose: "Check provider readiness and API contract version."
    },
    {
      method: "GET",
      path: "/api/mobile-contract",
      purpose: "Return the current server/mobile contract summary."
    },
    {
      method: "POST",
      path: "/api/identify",
      purpose: "Identify one crop image through the server-side plant ID provider."
    },
    {
      method: "GET",
      path: "/api/weather",
      query: {
        zip: "5-digit US ZIP code"
      },
      purpose: "Return weather context by ZIP."
    },
    {
      method: "GET",
      path: "/api/perenual/search",
      query: {
        q: "plant name"
      },
      purpose: "Look up plant profile data when a Perenual key is configured."
    }
  ],
  futureEndpoints: [
    {
      method: "POST",
      path: "/api/plants",
      purpose: "Create or update a garden plant."
    },
    {
      method: "POST",
      path: "/api/photos",
      purpose: "Save a crop photo to object storage."
    },
    {
      method: "DELETE",
      path: "/api/photos/:id",
      purpose: "Delete a user-owned crop photo."
    },
    {
      method: "POST",
      path: "/api/care-logs",
      purpose: "Save water, fertilize, prune, inspect, or observation logs."
    },
    {
      method: "POST",
      path: "/api/recognition-events",
      purpose: "Save local/provider recognition diagnostics and outcomes."
    },
    {
      method: "POST",
      path: "/api/id-only-gallery",
      purpose: "Save an optional ID-only personal gallery crop."
    },
    {
      method: "GET",
      path: "/api/sync",
      purpose: "Sync user plants, photos, gallery, care logs, weather snapshots, and recognition events."
    }
  ],
  storageModes: ["garden", "id-only-gallery"],
  coreModels: [
    "GardenPlant",
    "PlantPhoto",
    "IdOnlyGalleryItem",
    "CareLog",
    "RecognitionEvent",
    "WeatherSnapshot",
    "SeenLocation",
    "PhotoQuality"
  ],
  privacyDefaults: {
    cropOnlyStorage: true,
    fullFrameStoredByDefault: false,
    reverseGeocodingRequired: false,
    providerKeysOnClient: false
  }
};

module.exports = {
  mobileApiContract
};
