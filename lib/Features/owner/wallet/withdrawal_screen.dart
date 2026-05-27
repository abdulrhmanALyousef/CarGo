import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/owner/wallet/wallet_controller.dart';
import 'package:cargo/core/theme/light_color.dart';

class WithdrawalScreen extends StatelessWidget {
  const WithdrawalScreen({super.key, required this.availableBalance});
  final double availableBalance;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WalletController(),
      child: _Body(availableBalance: availableBalance),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.availableBalance});
  final double availableBalance;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _bankCtrl.dispose();
    _ibanCtrl.dispose();
    _holderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    setState(() => _submitting = true);

    final success =
        await context.read<WalletController>().requestWithdrawal(
              context: context,
              amount: amount,
              bankName: _bankCtrl.text.trim(),
              iban: _ibanCtrl.text.trim().toUpperCase(),
              accountHolderName: _holderCtrl.text.trim(),
            );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Withdrawal request submitted. Funds will be transferred within 1-3 business days.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text(
          'Withdraw Funds',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: LightColors.textColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvailableBalanceBanner(balance: widget.availableBalance),
              const SizedBox(height: 20),
              const _SectionLabel('WITHDRAWAL AMOUNT'),
              const SizedBox(height: 10),
              _AmountField(
                controller: _amountCtrl,
                maxAmount: widget.availableBalance,
              ),
              const SizedBox(height: 6),
              Text(
                'Minimum withdrawal: SAR 100',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('BANK DETAILS'),
              const SizedBox(height: 10),
              _FormCard(
                children: [
                  _InputField(
                    controller: _bankCtrl,
                    label: 'Bank Name',
                    hint: 'e.g. Al Rajhi Bank',
                    icon: Icons.account_balance_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const _FormDivider(),
                  _InputField(
                    controller: _ibanCtrl,
                    label: 'IBAN',
                    hint: 'SA00 0000 0000 0000 0000 0000',
                    icon: Icons.numbers_rounded,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final clean = v.replaceAll(' ', '');
                      if (clean.length < 15) return 'Invalid IBAN';
                      return null;
                    },
                  ),
                  const _FormDivider(),
                  _InputField(
                    controller: _holderCtrl,
                    label: 'Account Holder Name',
                    hint: 'Full name as on bank account',
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _WithdrawalNote(),
              const SizedBox(height: 24),
              _SubmitButton(
                onTap: _submitting ? null : _submit,
                isLoading: _submitting,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Available Balance Banner ───────────────────────────────────────────────────

class _AvailableBalanceBanner extends StatelessWidget {
  const _AvailableBalanceBanner({required this.balance});
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004B09), Color(0xFF006B0E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white70,
            size: 28,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available for Withdrawal',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'SAR ${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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

// ── Amount Field ───────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.maxAmount});
  final TextEditingController controller;
  final double maxAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'SAR',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: LightColors.textColor,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 10, vertical: 16),
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Invalid amount';
                if (n < 100) return 'Minimum withdrawal is SAR 100';
                if (n > maxAmount) return 'Exceeds available balance';
                return null;
              },
            ),
          ),
          TextButton(
            onPressed: () =>
                controller.text = maxAmount.toStringAsFixed(2),
            child: const Text(
              'Max',
              style: TextStyle(
                color: LightColors.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Form Card ──────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _FormDivider extends StatelessWidget {
  const _FormDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 52,
      endIndent: 0,
      color: Color(0xFFF0F0F0),
    );
  }
}

// ── Input Field ────────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: LightColors.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              textCapitalization: textCapitalization,
              validator: validator,
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: label,
                hintText: hint,
                labelStyle:
                    const TextStyle(fontSize: 12, color: Colors.grey),
                hintStyle: TextStyle(
                    fontSize: 13, color: Colors.grey.shade400),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(
                  fontSize: 14, color: LightColors.textColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Note ───────────────────────────────────────────────────────────────────────

class _WithdrawalNote extends StatelessWidget {
  const _WithdrawalNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFFE65100)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Withdrawals are processed within 1-3 business days. '
              'Only earnings from completed bookings are withdrawable. '
              'A 10% platform fee has already been deducted from your earnings.',
              style: TextStyle(fontSize: 11, color: Color(0xFF5D4037)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Submit Button ──────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.onTap, required this.isLoading});
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: LightColors.primaryColor,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Request Withdrawal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
