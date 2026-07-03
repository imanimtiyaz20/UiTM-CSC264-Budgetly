import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart' as tx;
import '../core/theme.dart';
import 'amount_text.dart';
import 'category_icon.dart';

class TransactionTile extends StatefulWidget {
  final tx.Transaction transaction;
  final String? label;
  final bool isJarTopup;
  final String? categoryIcon;
  final String? categoryColor;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.label,
    this.isJarTopup = false,
    this.categoryIcon,
    this.categoryColor,
    this.onTap,
    this.onDelete,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final displayLabel =
        widget.label ??
        (widget.transaction.description.isNotEmpty
            ? widget.transaction.description
            : (widget.isJarTopup ? 'Jar Top-up' : 'Transaction'));

    final showExtra =
        widget.transaction.description.isNotEmpty &&
        widget.transaction.description != displayLabel;

    final leadingIcon = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: widget.isJarTopup
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : widget.transaction.isExpense
            ? AppTheme.expenseColorFor(context).withValues(alpha: 0.1)
            : AppTheme.incomeColorFor(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: widget.isJarTopup
          ? const Icon(Icons.savings, color: AppTheme.primaryColor, size: 22)
          : CategoryIcon(
              iconName: widget.categoryIcon ?? 'more_horiz',
              colorHex: widget.categoryColor ?? '#607D8B',
              size: 22,
            ),
    );

    final trailingAmount = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AmountText(
              amount: widget.transaction.isExpense
                  ? -widget.transaction.amount
                  : widget.transaction.amount,
              currency: widget.transaction.currency,
              style: const TextStyle(fontSize: 15),
            ),
            if (widget.transaction.currency != 'MYR')
              Text(
                widget.transaction.currency,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
          ],
        ),
      ],
    );

    final card = Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: widget.onTap,
        leading: leadingIcon,
        title: Text(
          displayLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          showExtra
              ? '${widget.transaction.description} • ${dateFormat.format(widget.transaction.date)}'
              : dateFormat.format(widget.transaction.date),
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: trailingAmount,
      ),
    );

    if (widget.onDelete != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Dismissible(
            key: ValueKey(widget.transaction.id ?? UniqueKey()),
            direction: DismissDirection.endToStart,

            dismissThresholds: const {DismissDirection.endToStart: 0.9},

            movementDuration: const Duration(milliseconds: 250),
            resizeDuration: const Duration(milliseconds: 180),

            background: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28,
              ),
            ),

            confirmDismiss: (_) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete transaction?'),
                  content: Text(
                    'Are you sure you want to delete "$displayLabel"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              return confirmed ?? false;
            },

            onDismissed: (_) => widget.onDelete?.call(),

            child: card,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: card,
    );
  }
}
