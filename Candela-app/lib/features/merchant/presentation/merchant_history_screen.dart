import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/merchant_provider.dart';

/// Read-Only Redemption History Ledger Dashboard for Store Owners & Staff
/// Displays permanent audit records filtered by assigned store branches.
class MerchantHistoryScreen extends StatefulWidget {
  const MerchantHistoryScreen({super.key});

  @override
  State<MerchantHistoryScreen> createState() => _MerchantHistoryScreenState();
}

class _MerchantHistoryScreenState extends State<MerchantHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MerchantProvider>(context, listen: false).fetchRedemptionHistory();
      Provider.of<MerchantProvider>(context, listen: false).fetchDashboardMetrics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Consumer<MerchantProvider>(
      builder: (context, merchant, _) {
        final summary = merchant.historySummary;
        final history = merchant.redemptionHistory;

        final filtered = history.where((item) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          final cName = (item['customer_name'] ?? '').toString().toLowerCase();
          final cPhone = (item['customer_phone'] ?? '').toString().toLowerCase();
          final cTitle = (item['coupon_title'] ?? '').toString().toLowerCase();
          final cCode = (item['coupon_code'] ?? '').toString().toLowerCase();
          final bName = (item['branch_name'] ?? '').toString().toLowerCase();
          return cName.contains(q) || cPhone.contains(q) || cTitle.contains(q) || cCode.contains(q) || bName.contains(q);
        }).toList();

        final totalCount = summary['total_redemptions'] ?? history.length;
        final double totalFees = (summary['total_charged_fees'] as num?)?.toDouble() ??
            history.fold<double>(0.0, (double sum, dynamic i) => sum + (((i['charged_fee'] as num?)?.toDouble()) ?? 0.0));
        final todayCount = summary['today_redemptions'] ?? 0;

        return RefreshIndicator(
          onRefresh: () async {
            await merchant.fetchRedemptionHistory();
            await merchant.fetchDashboardMetrics();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header & Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.darkAmberAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: AppColors.darkSlateSurface,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              loc.tr('redemption_ledger_title'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.darkSlateCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.darkSlateBorder),
                          ),
                          child: Text(
                            '$totalCount ${loc.tr('total_redemptions')}',
                            style: const TextStyle(
                              color: AppColors.darkAmberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Metrics Banner Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: loc.tr('total_redemptions'),
                            value: '$totalCount',
                            icon: Icons.check_circle_outline_rounded,
                            accentColor: AppColors.successGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: loc.tr('total_fees_charged'),
                            value: '${totalFees.toStringAsFixed(2)} د.ل',
                            icon: Icons.account_balance_wallet_rounded,
                            accentColor: AppColors.darkAmberAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: loc.tr('today_redemptions'),
                            value: '$todayCount',
                            icon: Icons.today_rounded,
                            accentColor: AppColors.primaryAmber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: loc.tr('wallet_balance'),
                            value: '${merchant.walletBalance.toStringAsFixed(2)} د.ل',
                            icon: Icons.account_balance_rounded,
                            accentColor: AppColors.copperOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search & Filter Box
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkSlateCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.darkSlateBorder),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppColors.darkTextSecondary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: loc.isArabic ? 'ابحث باسم العميل، الهاتف، أو كود الكوبون...' : 'Search by customer, phone, or coupon code...',
                                hintStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.trim();
                                });
                              },
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Audit Ledger List
                    if (merchant.isLoadingHistory)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: AppColors.darkAmberAccent),
                        ),
                      )
                    else if (filtered.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: AppColors.darkSlateCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.darkSlateBorder),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.history_toggle_off_rounded, color: AppColors.darkTextSecondary, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              loc.isArabic ? 'لا توجد سجلات استرداد مسجلة' : 'No redemption records found',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              loc.isArabic ? 'ستظهر هنا تفاصيل الكوبونات المستردة فور مسحها في الفروع.' : 'Redemptions will appear here after customers scan at your branches.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final cName = item['customer_name'] ?? 'عميل كانديلا';
                          final cPhone = item['customer_phone'] ?? '—';
                          final couponTitle = item['coupon_title'] ?? 'كوبون توفير';
                          final couponCode = item['coupon_code'] ?? 'CPN';
                          final branchName = item['branch_name'] ?? 'الفرع الرئيسي';
                          final fee = (item['charged_fee'] as num?)?.toDouble() ?? 5.00;
                          final points = (item['points_awarded'] as num?)?.toInt() ?? 50;
                          final timestamp = item['redeemed_at_formatted'] ?? item['redeemed_at'] ?? 'الآن';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.darkSlateCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.darkSlateBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Customer Name & Timestamp
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppColors.darkSlateSurface,
                                          child: Text(
                                            cName.isNotEmpty ? cName[0].toUpperCase() : 'U',
                                            style: const TextStyle(
                                              color: AppColors.darkAmberAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              cPhone,
                                              style: const TextStyle(
                                                color: AppColors.darkTextSecondary,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkSlateSurface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, color: AppColors.darkTextSecondary, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            timestamp.toString().length > 16 ? timestamp.toString().substring(0, 16) : timestamp.toString(),
                                            style: const TextStyle(
                                              color: AppColors.darkTextSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: AppColors.darkSlateBorder, height: 1),
                                const SizedBox(height: 12),

                                // Middle Row: Coupon details & Branch
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            couponTitle,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.darkAmberAccent.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  couponCode,
                                                  style: const TextStyle(
                                                    color: AppColors.darkAmberAccent,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.store_rounded, color: AppColors.darkTextSecondary, size: 13),
                                              const SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  branchName,
                                                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Fee & Points Badges
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.successGreen.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '+$points PTS',
                                            style: const TextStyle(
                                              color: AppColors.successGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '-${fee.toStringAsFixed(2)} د.ل',
                                          style: const TextStyle(
                                            color: AppColors.darkAmberAccent,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSlateCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkSlateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11.5),
              ),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
