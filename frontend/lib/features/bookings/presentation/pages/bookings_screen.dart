// Deprecated: Standalone Bookings screen removed. Use the User Dashboard ("My Bookings") instead.
import 'package:flutter/widgets.dart';

@Deprecated('Removed from navigation. Use the User Dashboard for bookings management.')
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError(
      'BookingsScreen was removed. Navigate to the User Dashboard to manage bookings.',
    );
  }
}
