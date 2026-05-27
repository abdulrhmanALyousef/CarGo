// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cargo/models/wallet_model.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';

class WalletController extends ChangeNotifier {
  final _service = FirebaseService();

  WalletModel? _wallet;
  List<TransactionModel> _transactions = [];
  List<WithdrawalModel> _withdrawals = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<WalletModel>? _walletSub;

  WalletModel? get wallet => _wallet;
  List<TransactionModel> get transactions => _transactions;
  List<WithdrawalModel> get withdrawals => _withdrawals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  WalletController() {
    _init();
  }

  Future<void> _init() async {
    final ownerId = uid;
    if (ownerId == null) return;

    _isLoading = true;
    notifyListeners();

    _walletSub = _service.streamWallet(ownerId).listen(
      (w) {
        _wallet = w;
        notifyListeners();
      },
      onError: (e) => print('[WalletController] stream error: $e'),
    );

    await _loadHistory(ownerId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final ownerId = uid;
    if (ownerId == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    await _loadHistory(ownerId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadHistory(String ownerId) async {
    try {
      final results = await Future.wait([
        _service.getTransactions(ownerId),
        _service.getWithdrawals(ownerId),
      ]);
      _transactions = results[0] as List<TransactionModel>;
      _withdrawals = results[1] as List<WithdrawalModel>;
    } catch (e) {
      print('[WalletController] loadHistory error: $e');
      _error = e.toString();
    }
  }

  Future<bool> requestWithdrawal({
    required BuildContext context,
    required double amount,
    required String bankName,
    required String iban,
    required String accountHolderName,
  }) async {
    final ownerId = uid;
    if (ownerId == null) return false;

    try {
      await _service.requestWithdrawal(
        ownerId: ownerId,
        amount: amount,
        bankName: bankName,
        iban: iban,
        accountHolderName: accountHolderName,
      );
      await _loadHistory(ownerId);
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Insufficient')
                  ? 'Insufficient balance'
                  : 'Withdrawal failed. Try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    super.dispose();
  }
}
