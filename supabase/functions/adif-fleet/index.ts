import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const SOURCES = [
  "https://gtfsrt.renfe.com/vehicle_positions_LD.json",
  "https://gtfsrt.renfe.com/vehicle_positions.json",
];

const STATIONS: Record<string, string> = {
  "22100": "Ourense",
  "31400": "Santiago de Compostela",
  "31412": "A Coruña",
  "22308": "Vigo-Urzáiz",
  "22300": "Vigo-Guixar",
  "22200": "Pontevedra",
  "22204": "Vilagarcía de Arousa",
  "17000": "Madrid-Chamartín",
  "18000": "Madrid-Puerta de Atocha",
  "71801": "Barcelona-Sants",
  "03216": "Valencia Joaquín Sorolla",
  "51003": "Sevilla-Santa Justa",
  "54413": "Málaga-María Zambrano",
  "70600": "Zaragoza-Delicias",
  "10600": "Valladolid-Campo Grande",
  "15100": "León",
  "30100": "Zamora",
};

interface FeedEntity {
  id?: string;
  serviceName?: string;
  trainType?: string;
  product?: string;
  routeShortName?: string;
  line?: string;
  vehicle?: {
    trip?: {
      tripId?: string;
      routeId?: string;
      routeShortName?: string;
      trainType?: string;
      product?: string;
      serviceName?: string;
    };
    position?: { latitude?: number; longitude?: number; speed?: number; bearing?: number };
    currentStatus?: string;
    timestamp?: string | number;
    stopId?: string;
    vehicle?: {
      id?: string;
      label?: string;
      trainType?: string;
      product?: string;
      serviceName?: string;
      routeShortName?: string;
      line?: string;
    };
  };
}

function records(value: unknown): FeedEntity[] {
  if (typeof value !== "object" || value === null) return [];
  const entity = (value as { entity?: unknown }).entity;
  return Array.isArray(entity)
    ? entity.filter((item): item is FeedEntity =>
      typeof item === "object" && item !== null
    )
    : [];
}

function numberValue(value: unknown): number | null {
  const result = typeof value === "number" ? value : Number(value);
  return Number.isFinite(result) ? result : null;
}

function stationName(code: string | undefined): string | null {
  if (!code) return null;
  return STATIONS[code] ?? (/^\d+$/.test(code) ? null : code);
}

function normalize(entity: FeedEntity, source: "longDistance" | "cercanias") {
  const vehicle = entity.vehicle;
  const position = vehicle?.position;
  const lat = numberValue(position?.latitude);
  const lng = numberValue(position?.longitude);
  if (lat == null || lng == null || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return null;
  }

  const label = vehicle?.vehicle?.label?.trim() ?? "";
  const trainNumber = vehicle?.vehicle?.id?.trim() || label.match(/\d{4,6}/)?.[0];
  if (!trainNumber) return null;
  const tripId = vehicle?.trip?.tripId ?? "";
  const line = source === "cercanias"
    ? vehicle?.vehicle?.line ?? label.match(/^([A-Z0-9]+)/)?.[1]
    : entity.line ?? vehicle?.vehicle?.line ?? null;
  const commuterLine = /^(?:C(?:[1-9]|10)|R(?:[1-9]|1[0-7])|RAM)(?:$|[-\s])/i
    .test(line ?? "");
  const serviceBrand = source === "cercanias" || commuterLine ||
      /(?:C(?:[1-9]|10)|R(?:[1-9]|1[0-7])|RAM)$/i.test(tripId)
    ? "RENFE CERCANÍAS"
    : "RENFE";
  const stopCode = vehicle?.stopId;
  const currentStatus = vehicle?.currentStatus ?? "";
  const platform = label.match(/PLATF\.\(([^)]+)\)/)?.[1] ?? null;
  const timestamp = numberValue(vehicle?.timestamp);
  const trainType = entity.trainType ?? vehicle?.trip?.trainType ??
    vehicle?.vehicle?.trainType;
  const product = entity.product ?? vehicle?.trip?.product ??
    vehicle?.vehicle?.product;
  const serviceName = entity.serviceName ?? vehicle?.trip?.serviceName ??
    vehicle?.vehicle?.serviceName;
  const routeShortName = entity.routeShortName ??
    vehicle?.trip?.routeShortName ?? vehicle?.vehicle?.routeShortName;

  return {
    id: entity.id ?? `${source}-${tripId}-${trainNumber}`,
    trainNumber,
    tripId: tripId || null,
    serviceBrand,
    trainType: trainType ?? null,
    product: product ?? null,
    serviceName: serviceName ?? null,
    routeShortName: routeShortName ?? null,
    line: line ?? null,
    operator: "RENFE",
    source,
    lat,
    lng,
    speedKmh: position?.speed == null ? null : Math.round(position.speed * 3.6),
    bearingDegrees: numberValue(position?.bearing),
    delayMinutes: null,
    status: currentStatus || null,
    currentStation: currentStatus === "STOPPED_AT" ? stationName(stopCode) : null,
    nextStop: currentStatus !== "STOPPED_AT" ? stationName(stopCode) : null,
    origin: null,
    destination: null,
    platform,
    updatedAt: timestamp == null ? null : new Date(timestamp * 1000).toISOString(),
  };
}

async function fetchFeed(url: string): Promise<FeedEntity[]> {
  const response = await fetch(url, {
    headers: { "Accept": "application/json" },
    signal: AbortSignal.timeout(8000),
  });
  if (!response.ok) throw new Error(`Renfe devolveu HTTP ${response.status}`);
  return records(await response.json());
}

serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const feeds = await Promise.allSettled(SOURCES.map(fetchFeed));
    const uniquePositions = new Map<
      string,
      Exclude<ReturnType<typeof normalize>, null>
    >();
    for (const [index, result] of feeds.entries()) {
      if (result.status !== "fulfilled") continue;
      const source = index === 0 ? "longDistance" : "cercanias";
      for (const entity of result.value) {
        const train = normalize(entity, source);
        if (train == null) continue;
        uniquePositions.set(
          `${train.trainNumber}:${train.lat}:${train.lng}`,
          train,
        );
      }
    }
    const trains = [...uniquePositions.values()];

    if (feeds.every((result) => result.status === "rejected")) {
      return Response.json(
        { trains: [], updatedAt: new Date().toISOString(), error: "Non foi posible obter posicións de Renfe." },
        { headers: { ...corsHeaders, "Cache-Control": "no-store" }, status: 200 },
      );
    }
    return Response.json(
      { trains, updatedAt: new Date().toISOString(), sources: ["Renfe Data · CC BY 4.0"] },
      { headers: { ...corsHeaders, "Cache-Control": "public, max-age=10" } },
    );
  } catch (error) {
    return Response.json(
      {
        trains: [],
        updatedAt: new Date().toISOString(),
        error: error instanceof Error ? error.message : "Non foi posible cargar as posicións.",
      },
      { headers: corsHeaders, status: 200 },
    );
  }
});
