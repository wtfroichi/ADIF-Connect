import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/ticket_model.dart';
import '../../services/ticket_repository.dart';
import 'ticket_card.dart';
import 'ticket_detail_sheet.dart';

enum _TripPeriod { upcoming, past }

enum _DateFilter { all, thisMonth, selectedDay }

class TicketsScreen extends StatefulWidget {
  final TicketRepository ticketRepository;

  const TicketsScreen({
    super.key,
    required this.ticketRepository,
  });

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  _TripPeriod _period = _TripPeriod.upcoming;
  _DateFilter _dateFilter = _DateFilter.all;
  DateTime? _selectedDate;

  void _showTicketDetails(BuildContext context, TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => TicketDetailSheet(
        ticket: ticket,
        onDelete: () => widget.ticketRepository.deleteTicket(ticket.id),
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null) {
      setState(() {
        _dateFilter = _DateFilter.selectedDay;
        _selectedDate = selected;
      });
    }
  }

  List<TicketModel> _filterTickets(List<TicketModel> tickets, DateTime now) {
    final visible = tickets.where((ticket) {
      final isUpcoming = ticket.arrivalTime.isAfter(now);
      if ((_period == _TripPeriod.upcoming) != isUpcoming) return false;

      switch (_dateFilter) {
        case _DateFilter.all:
          return true;
        case _DateFilter.thisMonth:
          return ticket.departureTime.year == now.year &&
              ticket.departureTime.month == now.month;
        case _DateFilter.selectedDay:
          final selected = _selectedDate!;
          return ticket.departureTime.year == selected.year &&
              ticket.departureTime.month == selected.month &&
              ticket.departureTime.day == selected.day;
      }
    }).toList();

    visible.sort((a, b) => _period == _TripPeriod.upcoming
        ? a.departureTime.compareTo(b.departureTime)
        : b.departureTime.compareTo(a.departureTime));
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return ValueListenableBuilder<List<TicketModel>>(
      valueListenable: widget.ticketRepository.ticketsListenable,
      builder: (context, tickets, _) {
        final visible = _filterTickets(tickets, DateTime.now());
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 12),
                  _buildDateFilters(),
                ],
              ),
            ),
            Expanded(
              child: tickets.isEmpty
                  ? Center(
                      child: GlassContainer(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(32),
                        borderRadius: 24,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.confirmation_number_outlined,
                              size: 48,
                              color: onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppStrings.ticketsEmpty,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppStrings.ticketsEmptySub,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : visible.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.ticketsNoFilteredTrips,
                            style: TextStyle(color: onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final ticket = visible[index];
                            return TicketCard(
                              ticket: ticket,
                              onTap: () => _showTicketDetails(context, ticket),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppTheme.adifMint.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _periodButton(_TripPeriod.upcoming, AppStrings.ticketsUpcoming),
          _periodButton(_TripPeriod.past, AppStrings.ticketsPast),
        ],
      ),
    );
  }

  Widget _periodButton(_TripPeriod period, String label) {
    final selected = _period == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.adifPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilters() {
    return Row(
      children: [
        _dateChip(
          AppStrings.ticketsAllDates,
          _dateFilter == _DateFilter.all,
          () => setState(() => _dateFilter = _DateFilter.all),
        ),
        const SizedBox(width: 8),
        _dateChip(
          AppStrings.ticketsThisMonth,
          _dateFilter == _DateFilter.thisMonth,
          () => setState(() => _dateFilter = _DateFilter.thisMonth),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _dateChip(
            _selectedDate == null
                ? AppStrings.ticketsChooseDate
                : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
            _dateFilter == _DateFilter.selectedDay,
            _selectDate,
          ),
        ),
      ],
    );
  }

  Widget _dateChip(String label, bool selected, VoidCallback onTap) {
    final isDark = AppTheme.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.adifTeal.withValues(alpha: isDark ? 0.28 : 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppTheme.adifTeal.withValues(alpha: 0.5)
                : AppTheme.getGlassBorder(context),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected
                ? (isDark ? AppTheme.adifMint : AppTheme.adifPrimary)
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
