import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String ownerId;
  final double availableBalance;
  final double pendingBalance;
  final double totalEarnings;
  final double thisMonthRevenue;
  final DateTime updatedAt;

  const WalletModel({
    required this.ownerId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarnings,
    required this.thisMonthRevenue,
    required this.updatedAt,
  });

  factory WalletModel.empty(String ownerId) => WalletModel(
        ownerId: ownerId,
        availableBalance: 0,
        pendingBalance: 0,
        totalEarnings: 0,
        thisMonthRevenue: 0,
        updatedAt: DateTime.now(),
      );

  factory WalletModel.fromMap(Map<String, dynamic> map, String ownerId) =>
      WalletModel(
        ownerId: ownerId,
        availableBalance: (map['availableBalance'] as num?)?.toDouble() ?? 0,
        pendingBalance: (map['pendingBalance'] as num?)?.toDouble() ?? 0,
        totalEarnings: (map['totalEarnings'] as num?)?.toDouble() ?? 0,
        thisMonthRevenue: (map['thisMonthRevenue'] as num?)?.toDouble() ?? 0,
        updatedAt: map['updatedAt'] is Timestamp
            ? (map['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'availableBalance': availableBalance,
        'pendingBalance': pendingBalance,
        'totalEarnings': totalEarnings,
        'thisMonthRevenue': thisMonthRevenue,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class TransactionModel {
  final String transactionId;
  final String ownerId;
  final String bookingId;
  final double amount;
  final String type; // booking_payout | withdrawal
  final String status; // completed | pending | failed
  final DateTime createdAt;

  const TransactionModel({
    required this.transactionId,
    required this.ownerId,
    required this.bookingId,
    required this.amount,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) =>
      TransactionModel(
        transactionId: id,
        ownerId: map['ownerId'] as String? ?? '',
        bookingId: map['bookingId'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        type: map['type'] as String? ?? '',
        status: map['status'] as String? ?? '',
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'bookingId': bookingId,
        'amount': amount,
        'type': type,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class WithdrawalModel {
  final String withdrawalId;
  final String ownerId;
  final double amount;
  final String bankName;
  final String iban;
  final String accountHolderName;
  final String status; // pending | completed | rejected
  final DateTime createdAt;

  const WithdrawalModel({
    required this.withdrawalId,
    required this.ownerId,
    required this.amount,
    required this.bankName,
    required this.iban,
    required this.accountHolderName,
    required this.status,
    required this.createdAt,
  });

  factory WithdrawalModel.fromMap(Map<String, dynamic> map, String id) =>
      WithdrawalModel(
        withdrawalId: id,
        ownerId: map['ownerId'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        bankName: map['bankName'] as String? ?? '',
        iban: map['iban'] as String? ?? '',
        accountHolderName: map['accountHolderName'] as String? ?? '',
        status: map['status'] as String? ?? 'pending',
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'amount': amount,
        'bankName': bankName,
        'iban': iban,
        'accountHolderName': accountHolderName,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
