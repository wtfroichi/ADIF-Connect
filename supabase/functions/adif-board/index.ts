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
  codEstAnt?: string;
  codEstSig?: string;
  horaLlegadaSigEst?: string;
  ultRetraso?: string | number;
  p?: string;
  via?: string;
  via_real?: string;
  via_planificada?: string;
  anden?: string;
  track?: string;
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

interface CachedBoard {
  items: StationBoardItem[];
  error?: string;
  updatedAt: string;
  timestamp: number;
}

const station_boards_cache = new Map<string, CachedBoard>();
const CACHE_TTL_MS = 30 * 1000; // 30 seconds

const ADIF_STATIONS: Record<string, { code: string; name: string }> = {
  "22100": { code: "22100", name: "Ourense" },
  "31400": { code: "31400", name: "Santiago de Compostela" },
  "31412": { code: "31412", name: "A Coruña" },
  "22308": { code: "22308", name: "Vigo-Urzáiz" },
  "22300": { code: "22300", name: "Vigo-Guixar" },
  "22200": { code: "22200", name: "Pontevedra" },
  "22204": { code: "22204", name: "Vilagarcía de Arousa" },
  "31308": { code: "31308", name: "Padrón-Barbanza" },
  "22303": { code: "22303", name: "Redondela" },
  "22301": { code: "22301", name: "O Porriño" },
  "22112": { code: "22112", name: "Guillarei" },
  "22104": { code: "22104", name: "Ribadavia" },
  "31206": { code: "31206", name: "O Carballiño" },
  "31212": { code: "31212", name: "Lalín" },
  "20200": { code: "20200", name: "Lugo" },
  "20105": { code: "20105", name: "Sarria" },
  "20100": { code: "20100", name: "Monforte de Lemos" },
  "20006": { code: "20006", name: "O Barco de Valdeorras" },
  "20004": { code: "20004", name: "A Rúa-Petín" },
  "31500": { code: "31500", name: "Ferrol" },
  "31418": { code: "31418", name: "Betanzos" },
  "05440": { code: "05440", name: "Ortigueira" },
  "05425": { code: "05425", name: "Viveiro" },
  "05400": { code: "05400", name: "Ribadeo" },
  "17000": { code: "17000", name: "Madrid-Chamartín" },
  "18000": { code: "18000", name: "Madrid-Puerta de Atocha" },
  "71801": { code: "71801", name: "Barcelona-Sants" },
  "03216": { code: "03216", name: "Valencia Joaquín Sorolla" },
  "51003": { code: "51003", name: "Sevilla-Santa Justa" },
  "54413": { code: "54413", name: "Málaga-María Zambrano" },
  "70600": { code: "70600", name: "Zaragoza-Delicias" },
  "10600": { code: "10600", name: "Valladolid-Campo Grande" },
  "15100": { code: "15100", name: "León" },
  "30100": { code: "30100", name: "Zamora" },
  "08004": { code: "08004", name: "Segovia-Guiomar" },
  "08240": { code: "08240", name: "Medina del Campo AV" },
  "30200": { code: "30200", name: "Sanabria AV" },
  "30204": { code: "30204", name: "A Gudiña-Porta de Galicia" },
  "60911": { code: "60911", name: "Alicante" },
  "61200": { code: "61200", name: "Murcia" },
  "13200": { code: "13200", name: "Bilbao-Abando" },
  "11511": { code: "11511", name: "Donostia-San Sebastián" },
  "11208": { code: "11208", name: "Vitoria-Gasteiz" },
  "15211": { code: "15211", name: "Oviedo" },
  "15410": { code: "15410", name: "Xixón" },
  "14223": { code: "14223", name: "Santander" },
  "11014": { code: "11014", name: "Burgos-Rosa Manzano" },
  "14100": { code: "14100", name: "Palencia" },
  "30000": { code: "30000", name: "Salamanca" },
  "50500": { code: "50500", name: "Córdoba" },
  "05000": { code: "05000", name: "Granada" },
  "51405": { code: "51405", name: "Cádiz" },
  "43019": { code: "43019", name: "Huelva" },
  "37606": { code: "37606", name: "Badajoz" },
  "35400": { code: "35400", name: "Cáceres" },
  "80100": { code: "80100", name: "Pamplona" },
  "81100": { code: "81100", name: "Logroño" },
  "71500": { code: "71500", name: "Tarragona" },
  "79300": { code: "79300", name: "Girona" },
  "79316": { code: "79316", name: "Figueres-Vilafant" },
  "78400": { code: "78400", name: "Lleida-Pirineus" },
  "65300": { code: "65300", name: "Castelló" },
  "60600": { code: "60600", name: "Albacete-Los Llanos" },
  "03208": { code: "03208", name: "Cuenca-Fernando Zóbel" },
  "37200": { code: "37200", name: "Ciudad Real" },
  "37300": { code: "37300", name: "Puertollano" },
  "92103": { code: "92103", name: "Toledo" },
};

const LEGACY_STATION_CODES: Record<string, string> = {
  "OUR": "22100", "SCQ": "31400", "LC": "31412", "VGO-U": "22308",
  "VGO-G": "22300", "PO": "22200", "LU": "20200", "ML": "20100",
  "MAD-CH": "17000", "MAD-AT": "18000", "BCN": "71801", "LE": "15100",
  "ZA": "30100", "08223": "22308",
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
      "Accept-Language": "es-ES,es;q=0.9",
      "Referer": "https://www.renfe.com/",
    },
    signal: AbortSignal.timeout(8000),
  });
  if (!response.ok) throw new Error(`Upstream returned HTTP ${response.status}`);
  return await response.json();
}

function trainRecords<T>(value: unknown): T[] {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new Error("Invalid Renfe train feed");
  }
  const trains = (value as Record<string, unknown>).trenes;
  if (!Array.isArray(trains)) throw new Error("Invalid Renfe train feed");
  return records(trains) as T[];
}

function records(value: unknown): Record<string, unknown>[] {
  return Array.isArray(value)
    ? value.filter((item): item is Record<string, unknown> =>
      typeof item === "object" && item !== null && !Array.isArray(item)
    )
    : [];
}

function isBoardResponse(value: unknown): value is StationBoardItem[] {
  return Array.isArray(value) && value.every((item) =>
    typeof item === "object" &&
    item !== null &&
    typeof item.id === "string" &&
    typeof item.scheduledTime === "string" &&
    typeof item.trainNumber === "string"
  );
}

function cacheResponse(board: CachedBoard, source: "live" | "cache") {
  return board.items.length > 0
    ? {
      items: board.items,
      source,
      updatedAt: board.updatedAt,
    }
    : {
      items: [],
      error: board.error ?? "Sen circulacións dispoñibles neste momento",
    };
}

async function readPersistentCache(
  stationCode: string,
  type: string,
): Promise<CachedBoard | null> {
  const baseUrl = Deno.env.get("SUPABASE_URL")?.replace(/\/+$/, "");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!baseUrl || !serviceRoleKey) {
    console.error("A caché persistente de circulacións non está configurada.");
    return null;
  }

  const cacheUrl = new URL(`${baseUrl}/rest/v1/station_boards_cache`);
  cacheUrl.searchParams.set("select", "items,error,updated_at");
  cacheUrl.searchParams.set("station_code", `eq.${stationCode}`);
  cacheUrl.searchParams.set("board_type", `eq.${type}`);
  cacheUrl.searchParams.set("expires_at", `gt.${new Date().toISOString()}`);
  cacheUrl.searchParams.set("limit", "1");

  try {
    const response = await fetch(cacheUrl, {
      headers: {
        "apikey": serviceRoleKey,
        "Authorization": `Bearer ${serviceRoleKey}`,
        "Accept": "application/json",
      },
      signal: AbortSignal.timeout(2000),
    });
    if (!response.ok) throw new Error(`Cache read returned HTTP ${response.status}`);
    const rows = await response.json();
    if (!Array.isArray(rows) || rows.length === 0) return null;
    const row = rows[0] as Record<string, unknown>;
    if (!isBoardResponse(row.items) || typeof row.updated_at !== "string") {
      throw new Error("Invalid station cache response");
    }
    const timestamp = Date.parse(row.updated_at);
    if (!Number.isFinite(timestamp)) throw new Error("Invalid station cache timestamp");
    return {
      items: row.items,
      error: typeof row.error === "string" ? row.error : undefined,
      updatedAt: row.updated_at,
      timestamp,
    };
  } catch (error) {
    console.error(`Non se puido ler a caché da estación ${stationCode}:`, error);
    return null;
  }
}

async function writePersistentCache(
  stationCode: string,
  type: string,
  board: CachedBoard,
): Promise<void> {
  const baseUrl = Deno.env.get("SUPABASE_URL")?.replace(/\/+$/, "");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!baseUrl || !serviceRoleKey) return;

  try {
    const response = await fetch(
      `${baseUrl}/rest/v1/station_boards_cache?on_conflict=station_code,board_type`,
      {
        method: "POST",
        headers: {
          "apikey": serviceRoleKey,
          "Authorization": `Bearer ${serviceRoleKey}`,
          "Content-Type": "application/json",
          "Prefer": "resolution=merge-duplicates,return=minimal",
        },
        body: JSON.stringify({
          station_code: stationCode,
          board_type: type,
          items: board.items,
          error: board.error ?? null,
          source: "live",
          updated_at: board.updatedAt,
          expires_at: new Date(board.timestamp + CACHE_TTL_MS).toISOString(),
        }),
        signal: AbortSignal.timeout(2000),
      },
    );
    if (!response.ok) throw new Error(`Cache write returned HTTP ${response.status}`);
  } catch (error) {
    console.error(`Non se puido gardar a caché da estación ${stationCode}:`, error);
  }
}

function stationName(code: string | undefined, fallback: string): string {
  const normalizedCode = code?.trim().toUpperCase();
  if (!normalizedCode) return fallback;
  const canonicalCode = canonicalStationCode(normalizedCode)!;
  const resolved = ADIF_STATIONS[canonicalCode]?.name ??
    Object.values(ADIF_STATIONS).find((station) =>
      station.code === canonicalCode
    )?.name;
  if (resolved) return resolved;
  return /^\d+$/.test(normalizedCode) ? "Estación non recoñecida" : normalizedCode;
}

function canonicalStationCode(code: string | undefined): string | undefined {
  const normalized = code?.trim().toUpperCase();
  return normalized
    ? LEGACY_STATION_CODES[normalized] ?? normalized
    : undefined;
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

function sanitizePlatform(value: unknown): string | undefined {
  const platform = String(value ?? "").trim();
  if (!platform || platform === "-" || platform.toLowerCase() === "null") {
    return undefined;
  }
  const numeric = Number(platform);
  if (Number.isFinite(numeric) && numeric <= 0) return undefined;
  return platform;
}

function platformFromTrain(
  train: RenfeFleetTrain,
  preferNextStop: boolean,
): string | undefined {
  const candidates = preferNextStop
    ? [
      train.nextVia,
      train.via_real,
      train.via_planificada,
      train.anden,
      train.track,
      train.p,
    ]
    : [
      train.via_real,
      train.via_planificada,
      train.via,
      train.anden,
      train.track,
      train.p,
      train.nextVia,
    ];
  return candidates.map(sanitizePlatform).find((value) => value != null);
}

function madridMinuteOfDay(now: Date): number {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Europe/Madrid",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(now);
  const hour = Number(parts.find((part) => part.type === "hour")?.value);
  const minute = Number(parts.find((part) => part.type === "minute")?.value);
  return hour * 60 + minute;
}

function filterAndSortByTime(
  items: StationBoardItem[],
  now: Date,
): StationBoardItem[] {
  const nowMinutes = madridMinuteOfDay(now);
  return items
    .filter((item) => {
      const match = /^([01]\d|2[0-3]):([0-5]\d)$/.exec(item.scheduledTime);
      if (!match) return false;
      const scheduledMinutes = Number(match[1]) * 60 + Number(match[2]);
      const offset = scheduledMinutes - nowMinutes;
      return offset >= -10 && offset <= 24 * 60;
    })
    .sort((a, b) =>
      a.scheduledTime.localeCompare(b.scheduledTime) ||
      a.trainNumber.localeCompare(b.trainNumber)
    );
}

function productName(product: unknown): string {
  const raw = String(product ?? "").trim();
  return normalizeProduct(raw);
}

function parseLongDistance(
  fleet: RenfeFleetTrain[],
  schedules: RenfeSchedule[],
  stationCode: string,
  type: string,
): StationBoardItem[] {
  const liveTrains = new Map(
    fleet
      .filter((train) => train.codComercial)
      .map((train) => [train.codComercial!.trim(), train]),
  );
  const items: StationBoardItem[] = [];

  for (const schedule of schedules) {
    const trainNumber = schedule.idTren?.trim();
    const route = schedule.estaciones;
    if (!trainNumber || !Array.isArray(route)) continue;

    const stopIndex = route.findIndex((stop) =>
      canonicalStationCode(stop.p) === stationCode
    );
    if (stopIndex < 0) continue;
    const stop = route[stopIndex];
    const scheduledTime = localTime(type === "departures" ? stop.hs ?? stop.h : stop.h);
    if (!scheduledTime) continue;

    const train = liveTrains.get(trainNumber);
    const rawDelay = Number.parseInt(String(train?.ultRetraso ?? ""), 10);
    const hasLiveDelay = Number.isFinite(rawDelay);
    const delay = hasLiveDelay ? Math.max(0, rawDelay) : 0;
    const originCode = train?.codOrigen ?? route[0]?.p;
    const destinationCode = train?.codDestino ?? route.at(-1)?.p;
    const trainAtStation = train != null &&
      [train.codEstAnt, train.codEstAct, train.codEstSig].some((code) =>
        canonicalStationCode(code) === stationCode
      );
    const platform = trainAtStation
      ? platformFromTrain(
        train,
        canonicalStationCode(train.codEstSig) === stationCode,
      )
      : undefined;
    const product = productName(train?.codProduct);
    items.push({
      id: `${trainNumber}-${stationCode}-${type}`,
      scheduledTime,
      estimatedTime: type === "arrivals" && train?.codEstSig === stationCode
        ? localTime(train.horaLlegadaSigEst) ?? estimatedTime(scheduledTime, delay)
        : estimatedTime(scheduledTime, delay),
      operator: "renfe",
      trainType: product,
      trainNumber,
      destination: stationName(destinationCode, "---"),
      origin: stationName(originCode, "---"),
      stops: [],
      platform,
      status: !hasLiveDelay ? "unknown" : delay > 0 ? "delayed" : "onTime",
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
    if (canonicalStationCode(train.codEstSig) !== stationCode ||
      !train.horaLlegadaSigEst) return [];
    const arrivalTime = localTime(train.horaLlegadaSigEst);
    if (!arrivalTime) return [];
    const trainNumber = train.codTren?.trim();
    const rawDelay = Number.parseInt(String(train.retrasoMin ?? ""), 10);
    if (!trainNumber) return [];
    const hasLiveDelay = Number.isFinite(rawDelay);
    const delay = hasLiveDelay ? Math.max(0, rawDelay) : 0;
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
      platform: platformFromTrain(train, true),
      status: !hasLiveDelay ? "unknown" : delay > 0 ? "delayed" : "onTime",
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
    const requestedStation = (url.searchParams.get("station") ?? "22100").toUpperCase();
    const stationParam = canonicalStationCode(requestedStation) ?? requestedStation;
    const type = (url.searchParams.get("type") ?? "departures").toLowerCase();
    if (type !== "departures" && type !== "arrivals") {
      return new Response(JSON.stringify({ items: [], error: "Tipo de circulación non válido" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    const station = ADIF_STATIONS[stationParam] ??
      (/^\d{3,5}$/.test(stationParam)
        ? { code: stationParam, name: stationParam }
        : undefined);
    if (!station) {
      return new Response(JSON.stringify({ items: [], error: "Estación non recoñecida" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    const cacheKey = `${station.code}_${type}`;
    const now = Date.now();
    let cached = station_boards_cache.get(cacheKey);
    if (!cached || now - cached.timestamp >= CACHE_TTL_MS) {
      cached = await readPersistentCache(station.code, type) ?? undefined;
      if (cached) station_boards_cache.set(cacheKey, cached);
    }
    if (cached && now - cached.timestamp < CACHE_TTL_MS) {
      return new Response(JSON.stringify(cacheResponse(cached, "cache")), {
        headers: { ...corsHeaders, "Content-Type": "application/json", "X-Cache": "HIT" },
        status: 200,
      });
    }

    const results = await Promise.allSettled([
      fetchJson(RENFE_LONG_DISTANCE_FLEET)
        .then((value) => trainRecords<RenfeFleetTrain>(value)),
      fetchJson(RENFE_LONG_DISTANCE_SCHEDULES)
        .then((value) => trainRecords<RenfeSchedule>(value)),
      fetchJson(RENFE_SUBURBAN_FLEET)
        .then((value) => trainRecords<RenfeFleetTrain>(value)),
    ]);
    const longDistanceFleet = results[0].status === "fulfilled"
      ? results[0].value
      : [];
    const schedules = results[1].status === "fulfilled"
      ? results[1].value
      : [];
    const suburbanFleet = results[2].status === "fulfilled"
      ? results[2].value
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
    items = filterAndSortByTime(items, new Date(now));

    const sourceAvailable = type === "arrivals"
      ? results[1].status === "fulfilled" || results[2].status === "fulfilled"
      : results[1].status === "fulfilled";
    const board: CachedBoard = {
      items,
      error: items.length === 0
        ? sourceAvailable
          ? "Sen circulacións dispoñibles neste momento"
          : "Non foi posible obter datos en directo das fontes ferroviarias"
        : undefined,
      updatedAt: new Date(now).toISOString(),
      timestamp: now,
    };

    if (sourceAvailable) {
      station_boards_cache.set(cacheKey, board);
      await writePersistentCache(station.code, type, board);
    }
    return new Response(JSON.stringify(cacheResponse(board, "live")), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
        "X-Cache": "MISS",
      },
      status: 200,
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        items: [],
        error: error instanceof Error
          ? error.message
          : "Non foi posible obter datos en directo",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  }
});

function normalizeProduct(raw: string): string {
  const value = raw.toUpperCase()
    .replaceAll("Á", "A")
    .replaceAll("É", "E")
    .replaceAll("Í", "I")
    .replaceAll("Ó", "O")
    .replaceAll("Ú", "U")
    .replace(/[^A-Z0-9 ]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  const productCodes: Record<string, string> = {
    "2": "AVE",
    "3": "AVANT",
    "11": "INTERCITY",
    "13": "INTERCITY",
    "16": "REGIONAL",
    "18": "REGIONAL",
    "19": "REGIONAL",
    "28": "AVLO",
  };
  if (productCodes[value]) return productCodes[value];
  if (value.includes("CERCAN") || value.includes("RODALIES") || value.includes("FEVE")) {
    return "CERCANÍAS";
  }
  if (value.includes("AVLO")) return "AVLO";
  if (value.includes("AVANT") || value === "AVA") return "AVANT";
  if (value.includes("INTERCITY") ||
    value.includes("ICITY") ||
    value.includes("INTC") ||
    value.includes("ALVIA") ||
    value.includes("EUROMED") ||
    value.includes("TALGO") ||
    value.includes("TRENHOTEL")) return "INTERCITY";
  if (value.includes("AVE")) return "AVE";
  if (value.includes("REGIONAL") ||
    value.includes("REG EXP") ||
    value === "MD" ||
    value.includes("MEDIA DISTANCIA")) return "REGIONAL";
  if (value.includes("IRYO") || value === "IRY") return "IRYO";
  if (value.includes("OUIGO") || value === "OUI") return "OUIGO";
  return "";
}
