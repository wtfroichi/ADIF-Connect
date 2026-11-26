import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/liquid_glass_container.dart';
import 'features/1_import/import_screen.dart';
import 'features/2_tickets/tickets_screen.dart';
import 'features/3_station_board/station_board_screen.dart';
import 'features/4_settings/settings_screen.dart';
import 'services/adif_live_repository.dart';
import 'services/settings_service.dart';
import 'services/sharing_service.dart';
import 'services/supabase_adif_repository.dart';
import 'services/ticket_repository.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final settingsService = SettingsService();
  await settingsService.init();

  final ticketRepo = LocalTicketRepository();
  await ticketRepo.init();

  final adifRepo = SupabaseAdifRepository(settingsService: settingsService);

  runApp(AdifConnectApp(
    ticketRepository: ticketRepo,
    adifRepository: adifRepo,
    settingsService: settingsService,
  ));
}

class AdifConnectApp extends StatelessWidget {
  final TicketRepository ticketRepository;
  final AdifLiveRepository adifRepository;
  final SettingsService settingsService;

  const AdifConnectApp({
    super.key,
    required this.ticketRepository,
    required this.adifRepository,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: MainNavigationShell(
        ticketRepository: ticketRepository,
        adifRepository: adifRepository,
        settingsService: settingsService,
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final TicketRepository ticketRepository;
  final AdifLiveRepository adifRepository;
  final SettingsService settingsService;

  const MainNavigationShell({
    super.key,
    required this.ticketRepository,
    required this.adifRepository,
    required this.settingsService,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  late final SharingService _sharingService;

  static const List<String> _tabTitles = [
    AppStrings.importTitle,
    AppStrings.ticketsTitle,
    AppStrings.stationsTitle,
    AppStrings.settingsTitle,
  ];

  @override
  void initState() {
    super.initState();
    widget.settingsService.addListener(_onSettingsChanged);
    _sharingService = SharingService(
      ticketRepository: widget.ticketRepository,
      onTicketImported: () {
        if (mounted) {
          setState(() => _currentIndex = 1);
        }
      },
      onImportError: (message) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
    _sharingService.init();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final overlayStyle =
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        extendBody: true,
        appBar: AppBar(
          centerTitle: Platform.isIOS,
          toolbarHeight: Platform.isIOS ? 44 : null,
          systemOverlayStyle: overlayStyle,
          title: Text(
            _tabTitles[_currentIndex],
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            ImportScreen(
              ticketRepository: widget.ticketRepository,
              adifRepository: widget.adifRepository,
              onTicketImported: () => setState(() => _currentIndex = 1),
              onShowDepartures: () => setState(() => _currentIndex = 2),
              defaultStationCode: widget.settingsService.defaultStationCode,
            ),
            TicketsScreen(ticketRepository: widget.ticketRepository),
            StationBoardScreen(
              adifRepository: widget.adifRepository,
              settingsService: widget.settingsService,
              initialStationCode: widget.settingsService.defaultStationCode,
            ),
            SettingsScreen(
              settingsService: widget.settingsService,
              adifRepository: widget.adifRepository,
            ),
          ],
        ),
        bottomNavigationBar: Platform.isIOS
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: LiquidGlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    borderRadius: 28,
                    blurSigma: 12,
                    child: Row(
                      children: [
                        _buildNavItem(
                          0,
                          CupertinoIcons.house_fill,
                          AppStrings.navHome,
                          isDark,
                        ),
                        _buildNavItem(
                          1,
                          CupertinoIcons.ticket_fill,
                          AppStrings.navTickets,
                          isDark,
                        ),
                        _buildNavItem(
                          2,
                          CupertinoIcons.train_style_one,
                          AppStrings.navStations,
                          isDark,
                        ),
                        _buildNavItem(
                          3,
                          CupertinoIcons.gear_alt_fill,
                          AppStrings.navSettings,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) =>
                    setState(() => _currentIndex = index),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: AppStrings.navHome,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.confirmation_number_outlined),
                    selectedIcon: Icon(Icons.confirmation_number),
                    label: AppStrings.navTickets,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.train_outlined),
                    selectedIcon: Icon(Icons.train),
                    label: AppStrings.navStations,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: AppStrings.navSettings,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final selected = _currentIndex == index;
    final activeColor =
        isDark ? AppTheme.adifPlatformDarkText : AppTheme.adifPrimary;
    final inactiveColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 54),
          onPressed: () => setState(() => _currentIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: selected
                  ? (isDark
                      ? AppTheme.adifNavDarkSurface.withValues(alpha: 0.88)
                      : AppTheme.adifMint.withValues(alpha: 0.62))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(21),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 19, color: selected ? activeColor : inactiveColor),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? activeColor : inactiveColor,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
