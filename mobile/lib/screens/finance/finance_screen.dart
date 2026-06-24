import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/cashing_report_model.dart';
import '../../models/expenditure_model.dart';
import '../../providers/finance_provider.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<FinanceProvider>();
      prov.loadCashingReports();
      prov.loadExpenditures();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentLight,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Cashing Reports'),
            Tab(text: 'Expenditures'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              prov.loadCashingReports();
              prov.loadExpenditures();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Cashing Report',
            onPressed: () => _showNewCashingDialog(context),
          ),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Cashing Reports tab
                _CashingTab(prov: prov),
                // Expenditures tab
                _ExpenditureTab(prov: prov),
              ],
            ),
    );
  }

  void _showNewCashingDialog(BuildContext context) {
    final expectedCtrl = TextEditingController();
    final receivedCtrl = TextEditingController();
    final txCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Cashing Report',
                style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 16),
            TextField(
              controller: expectedCtrl,
              decoration: const InputDecoration(labelText: 'Expected Cashing (ZMW)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: receivedCtrl,
              decoration: const InputDecoration(labelText: 'Received Cashing (ZMW)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: txCtrl,
              decoration: const InputDecoration(
                  labelText: 'Airtel/MTN Transaction ID (optional)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final ok = await context.read<FinanceProvider>().createCashingReport({
                    'report_date': DateTime.now().toIso8601String().split('T')[0],
                    'expected_cashing': double.tryParse(expectedCtrl.text) ?? 0,
                    'received_cashing': double.tryParse(receivedCtrl.text) ?? 0,
                    'transaction_id': txCtrl.text.isNotEmpty ? txCtrl.text : null,
                    'description': descCtrl.text,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cashing report saved'),
                          backgroundColor: AppColors.success));
                  }
                },
                child: const Text('Save Report'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CashingTab extends StatelessWidget {
  final FinanceProvider prov;
  const _CashingTab({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary bar
        Container(
          color: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SumItem(label: 'Expected', value: Fmt.currency(prov.totalExpected),
                  color: Colors.white),
              _SumItem(label: 'Received', value: Fmt.currency(prov.totalReceived),
                  color: AppColors.accentLight),
              _SumItem(
                label: 'Variance',
                value: Fmt.currency(prov.totalVariance.abs()),
                color: prov.totalVariance < 0 ? Colors.redAccent : AppColors.success,
              ),
            ],
          ),
        ),
        Expanded(
          child: prov.cashingReports.isEmpty
              ? const Center(child: Text('No cashing reports yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.cashingReports.length,
                  itemBuilder: (context, i) =>
                      _CashingCard(report: prov.cashingReports[i])
                          .animate().fadeIn(delay: (i * 50).ms),
                ),
        ),
      ],
    );
  }
}

class _ExpenditureTab extends StatelessWidget {
  final FinanceProvider prov;
  const _ExpenditureTab({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SumItem(
                  label: 'Total Expenditures',
                  value: Fmt.currency(prov.totalExpenditures),
                  color: Colors.orangeAccent),
            ],
          ),
        ),
        Expanded(
          child: prov.expenditures.isEmpty
              ? const Center(child: Text('No expenditures recorded'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.expenditures.length,
                  itemBuilder: (context, i) =>
                      _ExpenditureCard(expenditure: prov.expenditures[i])
                          .animate().fadeIn(delay: (i * 50).ms),
                ),
        ),
      ],
    );
  }
}

class _SumItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SumItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

class _CashingCard extends StatelessWidget {
  final CashingReportModel report;
  const _CashingCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(Fmt.date(report.reportDate),
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(report.createdByName ?? '',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                if (report.description != null) ...[
                  const SizedBox(height: 4),
                  Text(report.description!,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _AmountCell(
                          label: 'Expected', value: report.expectedCashing,
                          color: AppColors.textPrimary),
                    ),
                    Expanded(
                      child: _AmountCell(
                          label: 'Received', value: report.receivedCashing,
                          color: AppColors.success),
                    ),
                    Expanded(
                      child: _AmountCell(
                          label: 'Variance',
                          value: report.variance,
                          color: report.isShortfall ? AppColors.error : AppColors.success,
                          prefix: report.isShortfall ? '-' : report.isSurplus ? '+' : ''),
                    ),
                  ],
                ),
                if (report.transactionId != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.receipt_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('TX: ${report.transactionId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCell extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String prefix;

  const _AmountCell({required this.label, required this.value, required this.color, this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
        Text(
          '$prefix${Fmt.currency(value.abs())}',
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    );
  }
}

class _ExpenditureCard extends StatelessWidget {
  final ExpenditureModel expenditure;
  const _ExpenditureCard({required this.expenditure});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.money_off_rounded, color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expenditure.description,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                Text('${expenditure.category} · ${Fmt.date(expenditure.date)}',
                    style: Theme.of(context).textTheme.bodySmall),
                if (expenditure.approvedBy != null)
                  Text('Approved by ${expenditure.approvedBy}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
              ],
            ),
          ),
          Text(
            Fmt.currency(expenditure.amount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
