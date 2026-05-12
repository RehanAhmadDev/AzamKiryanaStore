// lib/features/inventory/presentation/screens/stock_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_provider.dart';
import '../state/stock_logs_provider.dart';

class StockHistoryScreen extends ConsumerWidget {
  const StockHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final logsAsync = ref.watch(stockLogsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeState.primaryColor,
        title: const Text('Stock Audit Logs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.refresh(stockLogsProvider),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: logsAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: themeState.primaryColor)),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (logs) {
              if (logs.isEmpty) {
                return const Center(child: Text('No stock history found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final bool isIncrease = log.changeAmount > 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isIncrease ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        child: Icon(
                          isIncrease ? Icons.add_circle_outline : Icons.remove_circle_outline,
                          color: isIncrease ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(log.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reason: ${log.reason}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(DateFormat('dd MMM, hh:mm a').format(log.createdAt), style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isIncrease ? "+" : ""}${log.changeAmount}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: isIncrease ? Colors.green : Colors.red,
                            ),
                          ),
                          Text('Stock: ${log.newStock}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}