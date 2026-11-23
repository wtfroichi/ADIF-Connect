/// Centralized UI copy in Standard Galician (Galego normativo RAG/ILG).
/// Zero-boilerplate localization without code generation.
abstract final class AppStrings {
  // App General
  static const String appName = 'ADIF Connect';

  // Bottom Navigation Bar
  static const String navHome = 'Inicio';
  static const String navTickets = 'Billetes';
  static const String navStations = 'Estación';
  static const String navSettings = 'Axustes';

  // Tab 1: Import / Home
  static const String importTitle = 'Importar billete';
  static const String importSubtitle =
      'Selecciona ou arrastra o teu ficheiro .pkpass';
  static const String importActionBtn = 'Seleccionar .pkpass';
  static const String importManualFallback =
      'Ou introduce os datos manualmente';
  static const String importManualBtn = 'Entrada manual de billete';
  static const String importManualTitle = 'Novo billete manual';
  static const String importManualOrigin = 'Orixe';
  static const String importManualDestination = 'Destino';
  static const String importManualTrain = 'Número de tren';
  static const String importManualTrainType = 'Tipo de tren';
  static const String importManualCoach = 'Coche';
  static const String importManualSeat = 'Asento';
  static const String importManualPlatform = 'Vía (opcional)';
  static const String importManualLocalizer = 'Localizador (ex. ABC123)';
  static const String importManualPassenger = 'Nome do pasaxeiro';
  static const String importManualSubmit = 'Gardar billete';
  static const String importManualCancel = 'Cancelar';
  static const String importManualOperator = 'Operador';
  static const String importManualRequired = 'Requirido';
  static const String importManualDateRequired = 'Indica a saída e a chegada';
  static const String importRecentTitle = 'Importados recentemente';
  static const String importSuccess = 'Billete importado correctamente';
  static const String importError = 'Non se puido procesar o ficheiro .pkpass';
  static const String importInvalidFormat = 'Formato de ficheiro non válido';

  // Tab 2: Tickets Wallet & Pass View
  static const String ticketsTitle = 'As miñas viaxes';
  static const String ticketsEmpty = 'Aínda non tes billetes gardados';
  static const String ticketsEmptySub =
      'Importa un ficheiro .pkpass para comezar a viaxar';
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
  static const String ticketDeleteConfirm = 'Eliminar este billete';
  static const String ticketBrightnessHint =
      'Brillo maximizado para lectura rápida';

  // Tab 3: Station Board (Pantallas ADIF)
  static const String stationsTitle = 'Paneis ADIF';
  static const String stationsDepartures = 'Saídas';
  static const String stationsArrivals = 'Chegadas';
  static const String stationsSearchHint = 'Buscar estación...';
  static const String stationStatusOnTime = 'En hora';
  static const String stationStatusDelayed = 'Demorado';
  static const String stationStatusBoarding = 'Embarque';
  static const String stationStatusDeparted = 'Saíu';
  static const String stationStatusCancelled = 'Cancelado';
  static const String stationVia = 'Vía';
  static const String stationDestination = 'Destino';
  static const String stationTime = 'Hora';
  static const String stationTrain = 'Tren';
  static const String stationStops = 'Paradas';
  static const String stationLiveClock = 'Hora oficial ADIF';
  static const String stationNoTrains =
      'Sen circulacións dispoñibles neste momento';
  static const String stationErrorRetry = 'Tentar de novo';

  // Tab 4: Settings
  static const String settingsTitle = 'Configuración';
  static const String settingsLiveActivities =
      'Live Activities (Actividades en vivo)';
  static const String settingsLiveActivitiesDesc =
      'Amosa o progreso e a vía na pantalla de bloqueo e na Illa Dinámica';
  static const String settingsDefaultStation = 'Estación por defecto';
  static const String settingsSave = 'Gardar axustes';
  static const String settingsSavedSuccess = 'Axustes gardados correctamente';
  static const String settingsConnectionTest = 'Probar conexión';
  static const String settingsConnectionSuccess =
      'Conexión con Supabase correcta';
  static const String settingsConnectionError =
      'Non se puido conectar co servizo';
  static const String settingsAbout = 'Acerca de';
  static const String settingsVersion = 'Versión';
}
