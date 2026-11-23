import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/glass_container.dart';
import 'features/1_import/import_screen.dart';
import 'features/2_tickets/tickets_screen.dart';
import 'features/3_station_board/station_board_screen.dart';
import 'features/4_settings/settings_screen.dart';
import 'services/adif_live_repository.dart';
import 'services/settings_service.dart';
import 'services/sharing_service.dart';
import 'services/supabase_adif_repository.dart';
import 'services/ticket_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
    _sharingService = SharingService(
      ticketRepository: widget.ticketRepository,
      onTicketImported: () {
        if (mounted) {
          setState(() => _currentIndex = 1);
        }
      },
    );
    _sharingService.init();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final navBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final navBorder = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      extendBody: true,
      appBar: AppBar(
        title: Text(
          _tabTitles[_currentIndex],
          style: TextStyle(
            color: AppTheme.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 1: Import
          ImportScreen(
            ticketRepository: widget.ticketRepository,
            onTicketImported: () => setState(() => _currentIndex = 1),
          ),
          // Tab 2: Tickets Wallet
          TicketsScreen(
            ticketRepository: widget.ticketRepository,
          ),
          // Tab 3: Station Board (Pantallas ADIF)
          StationBoardScreen(
            adifRepository: widget.adifRepository,
          ),
          // Tab 4: Settings
          SettingsScreen(
            settingsService: widget.settingsService,
            adifRepository: widget.adifRepository,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            borderRadius: 32,
            backgroundColor: navBg,
            borderColor: navBorder,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, AppStrings.navHome, isDark),
                _buildNavItem(1, Icons.confirmation_number_rounded, AppStrings.navTickets, isDark),
                _buildNavItem(2, Icons.train_rounded, AppStrings.navStations, isDark),
                _buildNavItem(3, Icons.settings_rounded, AppStrings.navSettings, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;

    final activeBg = isDark ? AppTheme.darkNavActiveHighlight : AppTheme.lightNavActiveHighlight;
    final activeColor = isDark ? AppTheme.darkNavActiveText : AppTheme.lightNavActiveText;
    final inactiveColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    final color = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
