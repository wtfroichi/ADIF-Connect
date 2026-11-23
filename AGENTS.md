# AGENTS.md — ADIF Connect (iOS Edition)

## 1. Project Identity & Core Goal
- **App Name:** ADIF Connect (working title)
- **Target Platform:** iOS only (optimized for iOS 26/27 *Liquid Glass / Crystal* translucent aesthetics & Dynamic Island / Lock Screen Live Activities).
- **Language & Localization Strategy:**
  - **Code, comments, git commits, variable names:** Strictly **English** (saves tokens and follows standards).
  - **Active UI Language:** **Standard Galician (Galego normativo RAG/ILG) ONLY for now.**
  - **Future-Proofing (Zero-Boilerplate):** Do NOT use `flutter_localizations`, `.arb` files, or `intl` code generation (to save tokens and avoid `build_runner`). Instead, centralize 100% of UI strings as `static const String` inside `lib/core/constants/app_strings.dart` (never hardcode user-facing strings inside widgets). This keeps the app purely in Galician now while making future multi-language expansion trivial.
- **Core Purpose:** A multimodal-ready rail companion app (inspired by SNCF Connect UX + `mariomnts/pantallas-estaciones` station boards + *Trenecitos* Live Activities) focused on importing `.pkpass` tickets, viewing live ADIF station/train status, and displaying Lock Screen Live Activities.

---

## 2. Token-Saving & Agent Execution Rules (CRITICAL)
To preserve free-tier token limits in Antigravity, you MUST obey these rules strictly:
1. **Atomic Edits Only:** NEVER rewrite entire files when modifying existing code. Output ONLY the exact modified functions/widgets or unified diffs, or edit one small file per turn.
2. **No Boilerplate / No Chitchat:** Skip introductory explanations, summaries, and apologies. Output code and file paths directly.
3. **One Phase Per Prompt:** Never build multiple features at once. Wait for user confirmation before moving to the next phase.
4. **Minimal Dependencies:** Use only essential, lightweight packages. Avoid heavy state-management code-generation (`freezed`, `build_runner`, `riverpod_generator` are FORBIDDEN to save tokens and build time). Use `flutter_riverpod` (manual providers) or `provider` + `go_router`.
5. **Mock-First Data Layer:** Define clean abstract repositories (`TicketRepository`, `AdifLiveRepository`) with realistic JSON mock data first, then wire Supabase/ADIF endpoints without touching UI code.

---

## 3. Tech Stack & Architecture
- **Framework:** Flutter (latest stable) targeting iOS (`ios/` deployment target >= 18.0, adaptive styling for iOS 26/27 Liquid Glass).
- **Backend (Free Tier):** Supabase (PostgreSQL + Edge Functions as a lightweight proxy/cache for ADIF station boards to avoid rate-limiting and feed background Live Activities).
- **Local Storage:** `shared_preferences` or `sqflite` (keep local JSON persistence simple for imported `.pkpass` items).
- **Key Packages:**
  - `archive` (to unzip `.pkpass` files and read `pass.json`)
  - `pretty_qr_code` or `barcode_widget` (to render Aztec/QR codes cleanly on bright cards)
  - `live_activities` (to bridge Flutter with native Swift `ActivityKit` / `WidgetKit` for Lock Screen & Dynamic Island)
  - `file_picker` & `receive_sharing_intent` (to import `.pkpass` from Files, Mail, Safari, or WhatsApp)
  - `flutter_lucide` or `cupertino_icons`

### Folder Structure
```text
lib/
├── core/
│   ├── constants/
│   │   └── app_strings.dart       # Centralized UI copy (Galego normativo only, ready for future locales)
│   ├── theme/
│   │   ├── app_theme.dart         # iOS Liquid Glass / Crystal materials & blur
│   │   └── operator_themes.dart   # Dynamic palettes (Renfe, ADIF, Iryo, Ouigo)
│   └── router/
│       └── app_router.dart        # 4-tab Cupertino/Glass bottom navigation
├── models/
│   ├── ticket_model.dart          # Unified model parsed from .pkpass or manual entry
│   └── station_board_model.dart   # ADIF departure/arrival board item
├── services/
│   ├── pkpass_parser_service.dart # Unzips .pkpass, extracts pass.json, barcode, operator
│   ├── adif_live_service.dart     # Fetches station boards (inspired by mariomnts/pantallas-estaciones)
│   └── live_activity_service.dart # Updates iOS Lock Screen widget ("Trenecitos" style)
├── features/
│   ├── 1_import/                  # Tab 1: Home / Import .pkpass & quick manual fallback
│   ├── 2_tickets/                 # Tab 2: Ticket wallet & full-screen dynamic operator pass
│   ├── 3_station_board/           # Tab 3: Mobile-adapted ADIF station screen + new train vector/icons
│   └── 4_settings/                # Tab 4: Settings (Live Activities toggle, Supabase/cache config)
└── main.dart
ios/
└── TrainLiveActivity/             # Native SwiftUI WidgetKit + ActivityKit extension
```

---

## 4. Design System & Operator Extensibility

### A. Visual Style: iOS v27 "Liquid Crystal / Glass" + Brand Identity
- **Base Surface:** Deep obsidian/slate background (`#0A0E14`) with translucent frosted glass containers (`BackdropFilter` with `ImageFilter.blur(sigmaX: 24, sigmaY: 24)`, `1px` specular white gradient borders at `0.15` opacity, and soft inner highlights).
- **Navigation Bar:** Floating translucent pill-style bottom bar with 4 tabs (strings sourced from `AppStrings`):
  1. `Inicio` (Importar)
  2. `Billetes` (As miñas viaxes)
  3. `Estación` (Paneis ADIF)
  4. `Axustes` (Configuración)

### B. Multi-Operator Dynamic Theming (`operator_themes.dart`)
When opening a ticket in Tab 2, the card and ambient background glow MUST dynamically adapt to the detected operator from `pass.json` (with an extensible `Map<RailOperator, OperatorStyle>`):
- **Renfe (New Corporate Identity - AVE / Avlo / Alvia / MD / Cercanías):**
  - Primary: Deep Renfe Purple (`#6D1D5C` / `#830065`) + Vibrant Magenta accent (`#E20074`).
  - Avlo sub-theme: Cyan (`#00A9E0`) + Purple accents.
- **ADIF (Infrastructure / Station Boards):**
  - Primary: ADIF Emerald/Teal Green (`#007A53` / `#009B77`) + High-contrast Amber/White LED typography for station boards.
- **Extensible Operators (Ready-to-use presets):**
  - **Iryo:** Crimson Red (`#C8102E`) + Dark Charcoal (`#1C1C1E`).
  - **Ouigo:** Pink (`#E6007E`) + Sky Blue (`#009EE3`).
  - *Adding a new operator must only require adding one enum value and one `OperatorStyle` entry.*

### C. Tab 3: Mobile Station Board (`pantallas-estaciones` adaptation)
- Adapt the classic ADIF departure/arrival board layout to vertical mobile screens:
  - Header with ADIF green accent, station selector (e.g., *Ourense*, *Santiago de Compostela*, *Madrid-Chamartín*), and live clock.
  - Compact rows showing: **Scheduled Time**, **Train Type + New Train Silhouette/Badge** (AVE, Avlo, Alvia, Iryo, Ouigo, Cercanías), **Destination & Stops**, **Operator Logo**, **Platform (`Vía`)** highlighted in glowing badge when assigned, and **Status (`En hora`, `+10 min`, `Saíndo`)**.

### D. iOS Lock Screen Live Activity (*Trenecitos* Style)
- Native SwiftUI `ActivityAttributes` showing:
  - Left: Origin -> Destination (`OUR → MAD`) & Departure Time.
  - Center: Minimalist progress bar with train icon moving along the route.
  - Right: Prominent **Platform (`VÍA 4`)** & **Coach/Seat (`C4 · 12A`)** + live delay badge.

---

## 5. Step-by-Step Build Roadmap (Follow Strictly)
- **Step 1:** Initialize folder structure, `app_strings.dart` (100% Galego normativo, zero hardcoded strings in widgets), `operator_themes.dart`, and Liquid Glass UI primitives (`GlassContainer`).
- **Step 2:** Build `pkpass_parser_service.dart` (unzip `.pkpass` -> parse `pass.json` -> map fields to `TicketModel`) + Tab 1 (`Import`) & Tab 2 (`Tickets` with dynamic operator card & Aztec/QR brightness boost).
- **Step 3:** Build Tab 3 (`Station Board` mobile UI with custom train silhouettes and ADIF colors) using mock data structured after `pantallas-estaciones`.
- **Step 4:** Connect Supabase Edge Function / ADIF live data service + Tab 4 (`Settings`).
- **Step 5:** Implement native iOS `WidgetKit` / `ActivityKit` Lock Screen Live Activity in `ios/TrainLiveActivity/` and connect via `live_activities` package.