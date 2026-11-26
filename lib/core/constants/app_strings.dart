/// Centralized UI copy in Standard Galician (Galego normativo RAG/ILG).
/// Zero-boilerplate localization without code generation.
abstract final class AppStrings {
  // App General
  static const String appName = 'ADIF Connect';

  // Bottom Navigation Bar
  static const String navHome = 'Inicio';
  static const String navTickets = 'Billetes';
  static const String navStations = 'Tempo real';
  static const String navSettings = 'Axustes';

  // Tab 1: Import / Home
  static const String importTitle = 'Importar billete';
  static const String homeGreeting = 'Ola, onde viaxas hoxe?';
  static const String homeWelcome = 'Benvido a ADIF Connect';
  static const String homeUpcomingTrip = 'A túa próxima viaxe';
  static const String homeDepartureIn = 'Saída en';
  static const String homeTripNow = 'A viaxe comeza agora';
  static const String homeTripInProgress = 'En curso';
  static const String homeDeparturePlatform = 'Vía';
  static const String homeAddTicket = 'Engadir billete';
  static const String homeAddTicketHint =
      'Escolle como queres engadir o billete.';
  static const String homeImportPkpass = 'Importar billete (.pkpass)';
  static const String homeImportPdf = 'Importar billete (.pdf)';
  static const String homePkpassDescription = 'Ficheiro de Apple Wallet';
  static const String homePdfDescription =
      'Documento PDF de Renfe, Iryo ou Ouigo';
  static const String homeAddManual = 'Engadir manualmente';
  static const String homeAddManualDescription =
      'Introducir os datos e xerar un código Aztec';
  static const String homeLiveDepartures = 'Saídas en tempo real';
  static const String homeTravelTipsTitle = 'Formatos admitidos';
  static const String homePkpassTip =
      'Importa billetes directamente desde Apple Wallet (.pkpass).';
  static const String homePdfTip =
      'Escolle un documento PDF de Renfe, Iryo ou Ouigo.';
  static const String homeShareTip =
      'Tamén podes compartir un billete coa folla de compartir de iOS.';
  static const String homeStationLoading = 'Consultando circulacións…';
  static const String homeStationLoadError = 'Non se puideron cargar as saídas';
  static const String homeStationNoDepartures =
      'Sen saídas dispoñibles neste momento';
  static String homeStationDepartureCount(int count) => count == 1
      ? '1 circulación dispoñible'
      : '$count circulacións dispoñibles';
  static const String importSubtitle =
      'Importa o teu billete ou engade os datos da viaxe.';
  static const String importActionBtn = 'Seleccionar .pkpass';
  static const String importManualFallback =
      'Ou introduce os datos manualmente';
  static const String importManualBtn = 'Entrada manual de billete';
  static const String importManualTitle = 'Novo billete manual';
  static const String ticketNumber = 'Número de billete';
  static const String importManualOrigin = 'Orixe';
  static const String importManualDestination = 'Destino';
  static const String importManualTrain = 'Número de tren';
  static const String importManualTicketNumber = ticketNumber;
  static const String importManualTrainType = 'Tipo de tren';
  static const String importManualCoach = 'Coche';
  static const String importManualSeat = 'Asento';
  static const String importManualPlatform = 'Vía (opcional)';
  static const String importManualLocalizer = 'Localizador (opcional)';
  static const String datePickerChooseDate = 'Escoller data';
  static const String datePickerChooseTime = 'Escoller hora';
  static const String actionConfirm = 'Confirmar';
  static const String importManualPassenger = 'Nome do pasaxeiro';
  static const String importManualSubmit = 'Gardar billete';
  static const String importManualCancel = 'Cancelar';
  static const String importManualOperator = 'Operador';
  static const String importManualRequired = 'Obrigatorio';
  static const String importManualDateRequired = 'Indica a saída e a chegada';
  static const String importRecentTitle = 'Importados recentemente';
  static const String importSuccess = 'Billete importado correctamente';
  static const String importError =
      'Non se puido procesar o ficheiro seleccionado';
  static const String importInvalidFormat = 'Formato de ficheiro non válido';
  static const String importSelectPkpass =
      'Escolle un ficheiro de Apple Wallet coa extensión .pkpass.';
  static const String importSelectPdf =
      'Escolle un documento coa extensión .pdf.';
  static const String pdfMissingStations =
      'Non se puideron identificar a orixe e o destino no PDF.';
  static const String pdfMissingDate =
      'Non se puido identificar a data da viaxe no PDF.';
  static const String pdfMissingTimes =
      'Non se puideron identificar as horas de saída e chegada no PDF.';
  static const String pdfTextUnavailable =
      'Non se puido extraer texto do PDF. Comproba que o documento se le con claridade.';
  static const String walletLinkInvalid =
      'A ligazón de Google Wallet non contén un billete válido.';
  static const String pkpassInvalidArchive =
      'O ficheiro seleccionado non é un arquivo .pkpass ou ZIP válido';
  static const String pkpassMissingPassJson =
      'O ficheiro .pkpass non contén pass.json';
  static const String pkpassMissingTravelDate =
      'O billete non contén a data da viaxe';
  static const String pkpassMissingDepartureTime =
      'O billete non contén a hora de saída';
  static const String pkpassMissingArrivalTime =
      'O billete non contén a hora de chegada';
  static const String pkpassInvalidDepartureTime =
      'O billete contén unha hora de saída non válida';
  static const String pkpassInvalidArrivalTime =
      'O billete contén unha hora de chegada non válida';

  // Tab 2: Tickets Wallet & Pass View
  static const String ticketsTitle = 'As miñas viaxes';
  static const String ticketsEmpty = 'Aínda non tes billetes gardados';
  static const String ticketsEmptySub =
      'Importa un ficheiro .pkpass para comezar a viaxar';
  static const String ticketsUpcoming = 'Viaxes vindeiras';
  static const String ticketsPast = 'Viaxes pasadas';
  static const String ticketsAllDates = 'Todas as datas';
  static const String ticketsThisMonth = 'Este mes';
  static const String ticketsChooseDate = 'Escoller data';
  static const String ticketsNoFilteredTrips =
      'Non hai viaxes para esta selección.';
  static const String ticketOrigin = 'Orixe';
  static const String ticketDestination = 'Destino';
  static const String ticketDeparture = 'Saída';
  static const String ticketArrival = 'Chegada';
  static const String ticketDate = 'Data';
  static const String ticketTrain = 'Tren';
  static const String ticketCar = 'Coche';
  static const String ticketSeat = 'Asento';
  static const String ticketClass = 'Clase';
  static const String ticketPlatform = 'Vía';
  static const String ticketPlatformPending = 'Por asignar';
  static const String ticketPassenger = 'Pasaxeiro';
  static const String ticketLocalizer = 'Localizador';
  static const String ticketClose = 'Pechar';
  static const String ticketNoBarcodeBadge = 'Billete sen código dixital';
  static const String ticketNoBarcodeDesc =
      'Amosa o teu documento de identidade e o localizador no control de acceso da estación.';
  static const String ticketLiveActivityBtn =
      'Seguir viaxe na pantalla de bloqueo';
  static const String ticketLiveActivityActive =
      'Actividade en directo activada no bloqueo';
  static const String liveActivityPermissionDisabled =
      'Activa as actividades en directo en Axustes de iOS para seguir a viaxe.';
  static const String liveActivitySetupError =
      'Non se puido iniciar a actividade en directo. Comproba que a extensión estea asinada e incluída na aplicación.';
  static const String liveActivityEndError =
      'Non se puido deter a actividade en directo.';
  static const String liveActivityUnavailableValue = 'ND';
  static const String ticketDeleteConfirm = 'Eliminar este billete';
  static const String ticketBrightnessHint =
      'Brillo maximizado para lectura rápida';

  // Tab 3: Station Board (Pantallas ADIF)
  static const String stationsTitle = 'Tempo real';
  static const String stationsDepartures = 'Saídas';
  static const String stationsArrivals = 'Chegadas';
  static const String stationsSearchHint = 'Buscar estación...';
  static const String stationSelectorLabel = 'Estación';
  static const String stationStatusOnTime = 'En hora';
  static const String stationStatusDelayed = 'Con atraso';
  static const String stationStatusBoarding = 'Embarque';
  static const String stationStatusDeparted = 'Saíu';
  static const String stationStatusCancelled = 'Cancelado';
  static const String stationStatusUnknown = 'Estado non dispoñible';
  static const String stationPickerHint = 'Escolle unha estación';
  static const String stationUnknownName = 'Estación non recoñecida';
  static const String stationsNoResults = 'Non se atoparon estacións';
  static const String stationVia = 'Vía';
  static const String stationNearestAction = 'Usar a estación máis próxima';
  static const String stationNearestLoading = 'Buscando estación máis próxima…';
  static const String stationSetAsDefault = 'Usar como predeterminada';
  static const String stationIsDefault = 'Predeterminada';
  static const String stationDefaultUpdated =
      'Estación por defecto actualizada';
  static const String stationLocationServiceDisabled =
      'Activa a localización do dispositivo e téntao de novo.';
  static const String stationLocationPermissionDenied =
      'Permite o acceso á localización para buscar a estación máis próxima.';
  static const String stationLocationPermissionDeniedForever =
      'Activa o permiso de localización nos Axustes do dispositivo.';
  static const String stationNearestUnavailable =
      'Non se puido determinar a estación máis próxima.';
  static const String stationCoordinatesCredit =
      'Coordenadas: © OpenStreetMap contributors (ODbL).';
  static const String stationDestination = 'Destino';
  static const String stationTime = 'Hora';
  static const String stationTrain = 'Tren';
  static const String stationStops = 'Paradas';
  static const String stationLiveClock = 'Hora local';
  static const String stationNoTrains =
      'Sen circulacións dispoñibles neste momento';
  static const String stationErrorRetry = 'Tentar de novo';
  static const String stationBoardLoadError =
      'Non se puideron cargar as circulacións. Comproba a conexión e téntao de novo.';
  static const String stationNoCommercialBrand = 'RENFE';

  // Tab 4: Settings
  static const String settingsTitle = 'Configuración';
  static const String settingsLiveActivities = 'Actividades en directo';
  static const String settingsLiveActivitiesDesc =
      'Amosa o progreso e a vía na pantalla de bloqueo e na Illa Dinámica';
  static const String settingsDefaultStation = 'Estación por defecto';
  static const String settingsNearestStationDescription =
      'Usa a localización actual para escoller unha estación do catálogo.';
  static const String settingsSave = 'Gardar axustes';
  static const String settingsSavedSuccess = 'Axustes gardados correctamente';
  static const String settingsConnectionTest = 'Probar conexión';
  static const String settingsConnectionSuccess =
      'Conexión con Supabase correcta';
  static const String settingsConnectionError =
      'Non se puido conectar co servizo';
  static const String settingsAbout = 'Sobre a aplicación';
  static const String settingsVersion = 'Versión';
  static const String settingsRealtimeSources = 'Fontes de datos en tempo real';
  static const String settingsAdifSources =
      'ADIF Infoestacións e Elixe · RENFE: flota e horarios públicos';
  static const String settingsAdifSourcesDescription =
      'A función consulta os feeds públicos de flota e horarios de Renfe. ADIF Infoestacións/Elixe e GTFS-RT aínda non están conectados nesta versión.';
  static const String settingsSupabaseCache = 'Caché de Supabase Edge';
  static const String settingsSupabaseCacheDescription =
      'Actualización cada 30 segundos con validación en directo.';
  static const String settingsWalletPrivacy = 'Apple Wallet (.pkpass)';
  static const String settingsWalletPrivacyDescription =
      'Os billetes analízanse no dispositivo; os datos persoais non se envían a servidores externos.';
}
