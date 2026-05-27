import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/owner/wallet/wallet_controller.dart';
import 'package:cargo/Features/owner/wallet/withdrawal_screen.dart';
import 'package:cargo/Features/owner/earnings/earnings_screen.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/models/wallet_model.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WalletController(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<WalletController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text(
          'Wallet',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: LightColors.textColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: LightColors.textColor),
            onPressed: ctrl.refresh,
          ),
        ],
      ),
      body: ctrl.isLoading && ctrl.wallet == null
          ? const Center(
              child: CircularProgressIndicator(
                  color: LightColors.primaryColor))
          : RefreshIndicator(
              color: LightColors.primaryColor,
              onRefresh: ctrl.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BalanceCard(wallet: ctrl.wallet),
                    const SizedBox(height: 16),
                    _ActionRow(wallet: ctrl.wallet),
                    const SizedBox(height: 24),
                    if (ctrl.withdrawals.isNotEmpty) ...[
                        const _SectionLabel('WITHDRAWAL HISTORY'),
                      const SizedBox(height: 10),
                      ...ctrl.withdrawals.map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _WithdrawalTile(w: w),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const _SectionLabel('TRANSACTION HISTORY'),
                    const SizedBox(height: 10),
                    if (ctrl.transactions.isEmpty)
                      _EmptyHistory()
                    else
                      ...ctrl.transactions.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TransactionTile(t: t),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Balance Card ───────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet});
  final WalletModel? wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF004B09), Color(0xFF006B0E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004B09).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white70, size: 18),
              SizedBox(width: 6),
              Text(
                'Available Balance',
                style:
                    TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'SAR ${wallet != null ? _fmt(wallet!.availableBalance) : '0.00'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _BalanceStat(
                  label: 'Pending',
                  value: wallet != null
                      ? 'SAR ${_fmt(wallet!.pendingBalance)}'
                      : 'SAR 0',
                  icon: Icons.pending_outlined,
                ),
              ),
              Container(
                  width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: _BalanceStat(
                  label: 'Total Earned',
                  value: wallet != null
                      ? 'SAR ${_fmt(wallet!.totalEarnings)}'
                      : 'SAR 0',
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+\.)'),
            (m) => '${m[1]},',
          );
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 15),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }
}

// ── Action Row ─────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.wallet});
  final WalletModel? wallet;

  @override
  Widget build(BuildContext context) {
    final canWithdraw =
        wallet != null && wallet!.availableBalance >= 100;

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.upload_rounded,
            label: 'Withdraw',
            color: canWithdraw
                ? LightColors.primaryColor
                : Colors.grey,
            onTap: canWithdraw
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WithdrawalScreen(
                          availableBalance:
                              wallet!.availableBalance,
                        ),
                      ),
                    )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.receipt_long_outlined,
            label: 'Earnings',
            color: LightColors.primaryColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EarningsScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: onTap != null
                ? color.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Withdrawal Tile ────────────────────────────────────────────────────────────

class _WithdrawalTile extends StatelessWidget {
  const _WithdrawalTile({required this.w});
  final WithdrawalModel w;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (w.status) {
      'completed' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };
    final statusLabel = switch (w.status) {
      'completed' => 'Completed',
      'rejected' => 'Rejected',
      _ => 'Pending',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.upload_rounded,
                color: Colors.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdrawal – ${w.bankName}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LightColors.textColor,
                  ),
                ),
                Text(
                  'IBAN: ${_maskIban(w.iban)}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
                Text(
                  _fmtDate(w.createdAt),
                  style: const TextStyle(
                      fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '- SAR ${w.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _maskIban(String iban) {
    if (iban.length <= 6) return iban;
    return '${iban.substring(0, 4)}...${iban.substring(iban.length - 4)}';
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ── Transaction Tile ───────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.t});
  final TransactionModel t;

  @override
  Widget build(BuildContext context) {
    final isPayout = t.type == 'booking_payout';
    final color = isPayout ? Colors.green : Colors.red;
    final icon = isPayout
        ? Icons.download_rounded
        : Icons.upload_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPayout ? 'Booking Payout' : 'Withdrawal',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LightColors.textColor,
                  ),
                ),
                Text(
                  _fmtDate(t.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '${isPayout ? '+' : '-'} SAR ${t.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No transactions yet',
            style: TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text(
            'Earnings from completed bookings will appear here.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
