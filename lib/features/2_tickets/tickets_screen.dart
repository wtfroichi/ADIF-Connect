import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/ticket_model.dart';
import '../../services/ticket_repository.dart';
import 'ticket_card.dart';
import 'ticket_detail_sheet.dart';

class TicketsScreen extends StatelessWidget {
  final TicketRepository ticketRepository;

  const TicketsScreen({
    super.key,
    required this.ticketRepository,
  });

  void _showTicketDetails(BuildContext context, TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TicketDetailSheet(
        ticket: ticket,
        onDelete: () => ticketRepository.deleteTicket(ticket.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return ValueListenableBuilder<List<TicketModel>>(
      valueListenable: ticketRepository.ticketsListenable,
      builder: (context, tickets, _) {
        if (tickets.isEmpty) {
          return Center(
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
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return TicketCard(
              ticket: ticket,
              onTap: () => _showTicketDetails(context, ticket),
            );
          },
        );
      },
    );
  }
}
