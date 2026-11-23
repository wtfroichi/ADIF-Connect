// Supabase Edge Function: live Renfe/ADIF station board.
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface StationBoardItem {
  id: string;
  scheduledTime: string;
  estimatedTime?: string;
  operator: string;
  trainType: string;
  trainNumber: string;
  destination: string;
  origin: string;
  stops: string[];
  platform?: string;
  status: string;
  delayMinutes?: number;
}

interface RenfeFleetTrain {
  codComercial?: string;
  codProduct?: number | string;
  codOrigen?: string;
  codDestino?: string;
  codEstSig?: string;
  horaLlegadaSigEst?: string;
  ultRetraso?: string | number;
  p?: string;
  codTren?: string;
  codLinea?: string;
  codEstAct?: string;
  codEstOrig?: string;
  codEstDest?: string;
  retrasoMin?: string | number;
  nextVia?: string;
  tripId?: string;
}

interface RenfeSchedule {
  idTren?: string;
  estaciones?: Array<{ p?: string; h?: string; hs?: string }>;
}

const station_boards_cache = new Map<string, { data: StationBoardItem[]; timestamp: number }>();
const CACHE_TTL_MS = 30 * 1000; // 30 seconds

const ADIF_STATIONS: Record<string, { code: string; name: string }> = {
  "OUR": { code: "22100", name: "Ourense" },
  "SCQ": { code: "31400", name: "Santiago de Compostela" },
  "LC": { code: "15200", name: "A Coruña" },
  "VGO-U": { code: "22308", name: "Vigo-Urzáiz" },
  "VGO-G": { code: "22300", name: "Vigo-Guixar" },
  "PO": { code: "22200", name: "Pontevedra" },
  "LU": { code: "20200", name: "Lugo" },
  "ML": { code: "20100", name: "Monforte de Lemos" },
  "MAD-CH": { code: "10000", name: "Madrid-Chamartín-Clara Campoamor" },
  "MAD-AT": { code: "60000", name: "Madrid-Puerta de Atocha" },
  "BCN": { code: "71801", name: "Barcelona-Sants" },
  "LE": { code: "15100", name: "León" },
  "ZA": { code: "30100", name: "Zamora" },
};

const RENFE_LONG_DISTANCE_FLEET =
  "https://tiempo-real.largorecorrido.renfe.com/renfe-visor/flotaLD.json";
const RENFE_LONG_DISTANCE_SCHEDULES =
  "https://tiempo-real.largorecorrido.renfe.com/renfe-visor/trenesConEstacionesLD.json";
const RENFE_SUBURBAN_FLEET =
  "https://tiempo-real.renfe.com/renfe-visor/flota.json";

async function fetchJson(url: string): Promise<unknown> {
  const response = await fetch(url, {
    headers: {
      "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
      "Accept": "application/json",
    },
    signal: AbortSignal.timeout(8000),
  });
  if (!response.ok) throw new Error(`Upstream returned HTTP ${response.status}`);
  return await response.json();
}

function records(value: unknown): Record<string, unknown>[] {
  return Array.isArray(value)
    ? value.filter((item): item is Record<string, unknown> =>
      typeof item === "object" && item !== null
    )
    : [];
}

function stationName(code: string | undefined, fallback: string): string {
  if (!code) return fallback;
  return Object.values(ADIF_STATIONS).find((station) => station.code === code)?.name ?? code;
}

function localTime(value: string | undefined): string | null {
  if (!value) return null;
  const match = value.match(/(?:T|^)(\d{2}:\d{2})/);
  return match?.[1] ?? null;
}

function estimatedTime(scheduledTime: string, delayMinutes: number): string | undefined {
  if (delayMinutes <= 0 || !/^\d{2}:\d{2}$/.test(scheduledTime)) return undefined;
  const [hours, minutes] = scheduledTime.split(":").map(Number);
  const totalMinutes = (hours * 60 + minutes + delayMinutes) % (24 * 60);
  return `${String(Math.floor(totalMinutes / 60)).padStart(2, "0")}:${String(totalMinutes % 60).padStart(2, "0")}`;
}

function productName(product: unknown): string {
  const raw = String(product ?? "").trim();
  return normalizeProduct(raw) || raw;
}

function parseLongDistance(
  fleet: RenfeFleetTrain[],
  schedules: RenfeSchedule[],
  stationCode: string,
  type: string,
): StationBoardItem[] {
  const schedulesByTrain = new Map(
    schedules
      .filter((schedule) => schedule.idTren && Array.isArray(schedule.estaciones))
      .map((schedule) => [schedule.idTren!, schedule.estaciones!]),
  );
  const items: StationBoardItem[] = [];

  for (const train of fleet) {
    const trainNumber = train.codComercial?.trim();
    const route = trainNumber ? schedulesByTrain.get(trainNumber) : undefined;
    if (!trainNumber || !route) continue;

    const stopIndex = route.findIndex((stop) => stop.p === stationCode);
    const nextStopIndex = route.findIndex((stop) => stop.p === train.codEstSig);
    if (stopIndex < 0 || nextStopIndex < 0 || stopIndex < nextStopIndex) continue;

    const stop = route[stopIndex];
    const scheduledTime = localTime(type === "departures" ? stop.hs ?? stop.h : stop.h);
    if (!scheduledTime) continue;

    const rawDelay = Number.parseInt(String(train.ultRetraso ?? ""), 10);
    if (!Number.isFinite(rawDelay)) continue;
    const delay = Math.max(0, rawDelay);
    const originCode = train.codOrigen ?? route[0]?.p;
    const destinationCode = train.codDestino ?? route.at(-1)?.p;
    const platform = stopIndex === nextStopIndex ? train.p : undefined;
    const product = productName(train.codProduct);
    if (!product) continue;
    items.push({
      id: `${trainNumber}-${stationCode}-${type}`,
      scheduledTime,
      estimatedTime: type === "arrivals" && stopIndex === nextStopIndex
        ? localTime(train.horaLlegadaSigEst) ?? estimatedTime(scheduledTime, delay)
        : estimatedTime(scheduledTime, delay),
      operator: "renfe",
      trainType: product,
      trainNumber,
      destination: stationName(destinationCode, "---"),
      origin: stationName(originCode, "---"),
      stops: [],
      platform: platform || undefined,
      status: delay > 0 ? "delayed" : "onTime",
      delayMinutes: delay > 0 ? delay : undefined,
    });
  }
  return items;
}

function parseSuburbanArrivals(
  fleet: RenfeFleetTrain[],
  stationCode: string,
): StationBoardItem[] {
  return fleet.flatMap((train) => {
    if (train.codEstSig !== stationCode || !train.horaLlegadaSigEst) return [];
    const arrivalTime = localTime(train.horaLlegadaSigEst);
    if (!arrivalTime) return [];
    const trainNumber = train.codTren?.trim();
    const rawDelay = Number.parseInt(String(train.retrasoMin ?? ""), 10);
    if (!trainNumber || !Number.isFinite(rawDelay)) return [];
    const delay = Math.max(0, rawDelay);
    return [{
      id: `${train.tripId ?? trainNumber}-${stationCode}-arrivals`,
      scheduledTime: arrivalTime,
      estimatedTime: arrivalTime,
      operator: "renfe",
      trainType: train.codLinea ? `Cercanías ${train.codLinea}` : "CERCANÍAS",
      trainNumber,
      destination: stationName(train.codEstDest, "---"),
      origin: stationName(train.codEstOrig, "---"),
      stops: [],
      platform: train.nextVia || undefined,
      status: delay > 0 ? "delayed" : "onTime",
      delayMinutes: delay > 0 ? delay : undefined,
    }];
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const stationParam = (url.searchParams.get("station") ?? "OUR").toUpperCase();
    const type = (url.searchParams.get("type") ?? "departures").toLowerCase();
    if (type !== "departures" && type !== "arrivals") {
      return new Response(JSON.stringify({ items: [], error: "Tipo de circulación non válido" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    const station = ADIF_STATIONS[stationParam];
    if (!station) {
      return new Response(JSON.stringify({ items: [], error: "Estación non recoñecida" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    const cacheKey = `${station.code}_${type}`;

    const cached = station_boards_cache.get(cacheKey);
    const now = Date.now();
    if (cached && now - cached.timestamp < CACHE_TTL_MS) {
      const cachedResponse = cached.data.length > 0
        ? {
          items: cached.data,
          source: "live",
          updatedAt: new Date(cached.timestamp).toISOString(),
        }
        : { items: [], error: "Sen circulacións dispoñibles neste momento" };
      return new Response(JSON.stringify(cachedResponse), {
        headers: { ...corsHeaders, "Content-Type": "application/json", "X-Cache": "HIT" },
        status: 200,
      });
    }

    const results = await Promise.allSettled([
      fetchJson(RENFE_LONG_DISTANCE_FLEET),
      fetchJson(RENFE_LONG_DISTANCE_SCHEDULES),
      fetchJson(RENFE_SUBURBAN_FLEET),
    ]);
    const longDistanceFleet = results[0].status === "fulfilled"
      ? records((results[0].value as { trenes?: unknown }).trenes) as RenfeFleetTrain[]
      : [];
    const schedules = results[1].status === "fulfilled"
      ? records((results[1].value as { trenes?: unknown }).trenes).map((entry) => entry as RenfeSchedule)
      : [];
    const suburbanFleet = results[2].status === "fulfilled"
      ? records((results[2].value as { trenes?: unknown }).trenes) as RenfeFleetTrain[]
      : [];

    let items = parseLongDistance(
      longDistanceFleet,
      schedules,
      station.code,
      type,
    );
    if (type === "arrivals") {
      items = [...items, ...parseSuburbanArrivals(suburbanFleet, station.code)];
    }
    items.sort((a, b) => a.scheduledTime.localeCompare(b.scheduledTime));

    const sourceAvailable = results.some((result) => result.status === "fulfilled");
    const responseData = items.length > 0
      ? { items, source: "live", updatedAt: new Date(now).toISOString() }
      : {
        items: [],
        error: sourceAvailable
          ? "Sen circulacións dispoñibles neste momento"
          : "Non foi posible obter datos en directo das fontes ferroviarias",
      };

    if (sourceAvailable) station_boards_cache.set(cacheKey, { data: items, timestamp: now });
    return new Response(JSON.stringify(responseData), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
        "X-Cache": "MISS",
      },
      status: 200,
    });
  } catch (error: any) {
    return new Response(
      JSON.stringify({
        items: [],
        error: error?.message ?? "Non foi posible obter datos en directo",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  }
});

function normalizeProduct(raw: string): string {
  const value = raw.toUpperCase();
  if (value.includes("AVLO")) return "AVLO";
  if (value.includes("ALVIA")) return "ALVIA";
  if (value.includes("INTERCITY") || value.includes("ICITY") || value.includes("INTC")) return "INTERCITY";
  if (value.includes("AVANT") || value.includes("AVA")) return "AVANT";
  if (value.includes("AVE")) return "AVE";
  if (value === "MD" || value.includes("MEDIA DISTANCIA")) return "MD";
  if (value.includes("REG.EXP") || (value.includes("REGIONAL") && value.includes("EXP"))) return "REG.EXP.";
  if (value.includes("REGIONAL")) return "REGIONAL";
  if (value.includes("CERCAN")) return "CERCANÍAS";
  if (value.includes("IRYO") || value === "IRY") return "IRYO";
  if (value.includes("OUIGO") || value === "OUI") return "OUIGO";
  if (value.includes("EUROMED")) return "EUROMED";
  if (value.includes("TRENHOTEL")) return "TRENHOTEL";
  return value;
}
