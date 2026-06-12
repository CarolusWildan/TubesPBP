import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/hotel_model.dart';
import '../../../../shared/models/room_model.dart';
import 'booking_summary_screen.dart';

class BookingDateScreen extends StatefulWidget {
  final HotelModel hotel;
  final RoomModel? room;

  const BookingDateScreen({
    super.key,
    required this.hotel,
    this.room,
  });

  @override
  State<BookingDateScreen> createState() => _BookingDateScreenState();
}

class _BookingDateScreenState extends State<BookingDateScreen> {
  DateTime _checkIn = _dateOnly(DateTime.now());
  late DateTime _checkOut = _checkIn.add(const Duration(days: 1));
  bool _selectingCheckOut = false;

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime get _activeCalendarDate => _selectingCheckOut ? _checkOut : _checkIn;

  int get _nights {
    final nights = _checkOut.difference(_checkIn).inDays;
    return nights <= 0 ? 1 : nights;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.maybePop(context),
              onReset: () {
                final today = DateTime.now();
                setState(() {
                  _checkIn = _dateOnly(today);
                  _checkOut = _checkIn.add(const Duration(days: 1));
                  _selectingCheckOut = false;
                });
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hotel.namaHotel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Trip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _TripSelector(
                      checkIn: _checkIn,
                      checkOut: _checkOut,
                      nights: _nights,
                      selectingCheckOut: _selectingCheckOut,
                      onSelectCheckIn: () {
                        setState(() => _selectingCheckOut = false);
                      },
                      onSelectCheckOut: () {
                        setState(() => _selectingCheckOut = true);
                      },
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          datePickerTheme: DatePickerThemeData(
                            todayBorder: BorderSide.none,
                            todayForegroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.white;
                              }
                              if (states.contains(WidgetState.disabled)) {
                                return Colors.black38;
                              }
                              return Colors.black87;
                            }),
                            todayBackgroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFF0EA554);
                              }
                              return Colors.transparent;
                            }),
                          ),
                        ),
                        child: CalendarDatePicker(
                          key: ValueKey(_activeCalendarDate),
                          initialDate: _activeCalendarDate,
                          firstDate: _dateOnly(DateTime.now()),
                          lastDate: DateTime(DateTime.now().year + 2),
                          onDateChanged: _handleDateChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BottomBar(
              nights: _nights,
              onConfirm: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingSummaryScreen(
                      hotel: widget.hotel,
                      room: widget.room,
                      checkIn: _checkIn,
                      checkOut: _checkOut,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleDateChanged(DateTime selectedDate) {
    final date = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    setState(() {
      if (_selectingCheckOut) {
        _checkOut = date.isAfter(_checkIn)
            ? date
            : _checkIn.add(const Duration(days: 1));
      } else {
        _checkIn = date;
        if (!_checkOut.isAfter(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
        _selectingCheckOut = true;
      }
    });
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onReset;

  const _Header({
    required this.onBack,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      color: const Color(0xFF0EA554),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Back',
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Choose Date',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onReset,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reset date',
          ),
        ],
      ),
    );
  }
}

class _TripSelector extends StatelessWidget {
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final bool selectingCheckOut;
  final VoidCallback onSelectCheckIn;
  final VoidCallback onSelectCheckOut;

  const _TripSelector({
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.selectingCheckOut,
    required this.onSelectCheckIn,
    required this.onSelectCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _DatePill(
              label: 'CHECK IN',
              value: _formatDate(checkIn),
              isSelected: !selectingCheckOut,
              onTap: onSelectCheckIn,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                '$nights Nights',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: _DatePill(
              label: 'CHECK OUT',
              value: _formatDate(checkOut),
              isSelected: selectingCheckOut,
              onTap: onSelectCheckOut,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return DateFormat('EEE, dd MMM').format(date);
  }
}

class _DatePill extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final bool alignEnd;
  final VoidCallback onTap;

  const _DatePill({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment:
              alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: alignEnd ? TextAlign.end : TextAlign.start,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              alignEnd ? '12:00 PM' : '14:00 PM',
              textAlign: alignEnd ? TextAlign.end : TextAlign.start,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int nights;
  final VoidCallback onConfirm;

  const _BottomBar({
    required this.nights,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Duration',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              Text(
                '$nights Nights',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA554),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Confirm Date',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
