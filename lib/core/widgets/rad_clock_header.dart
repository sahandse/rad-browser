import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

class RadClockHeader extends StatefulWidget {
  const RadClockHeader({super.key});

  @override
  State<RadClockHeader> createState() => _RadClockHeaderState();
}

class _RadClockHeaderState extends State<RadClockHeader> {
  late DateTime _now;
  Timer? _timer;

  static const _months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const _weekdays = {
    DateTime.saturday: 'شنبه',
    DateTime.sunday: 'یکشنبه',
    DateTime.monday: 'دوشنبه',
    DateTime.tuesday: 'سه‌شنبه',
    DateTime.wednesday: 'چهارشنبه',
    DateTime.thursday: 'پنج‌شنبه',
    DateTime.friday: 'جمعه',
  };

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _digits(Object value) {
    const latin = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    var text = value.toString();
    for (var i = 0; i < latin.length; i++) {
      text = text.replaceAll(latin[i], persian[i]);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final jalali = Jalali.fromDateTime(_now);
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    final weekday = _weekdays[_now.weekday] ?? '';
    final date = '$weekday، ${_digits(jalali.day)} ${_months[jalali.month - 1]} ${_digits(jalali.year)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _digits('$hour:$minute'),
          textDirection: TextDirection.ltr,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          date,
          textDirection: TextDirection.rtl,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
