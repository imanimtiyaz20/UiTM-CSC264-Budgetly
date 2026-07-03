import 'package:flutter/material.dart';
import '../core/currencies.dart';
import '../core/theme.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final String currency;
  final TextStyle? style;

  const AmountText({
    super.key,
    required this.amount,
    this.currency = 'MYR',
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final color = amount >= 0
        ? AppTheme.incomeColorFor(context)
        : AppTheme.expenseColorFor(context);
    final sign = amount >= 0 ? '+' : '';
    final formatted = formatCurrency(amount.abs(), currency);

    return Text(
      '$sign$formatted',
      style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
