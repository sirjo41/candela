import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../models/merchant_offer_item.dart';
import '../providers/merchant_provider.dart';
import 'launch_offer_screen.dart';

/// Manage Offers & Analytics Screen (إدارة العروض والتحليلات)
/// Optimized for mobile phone screens with responsive horizontal scrolling and touch-friendly controls.
class ManageOffersScreen extends StatefulWidget {
  final VoidCallback? onCreateNewOffer;

  const ManageOffersScreen({
    super.key,
    this.onCreateNewOffer,
  });

  @override
  State<ManageOffersScreen> createState() => _ManageOffersScreenState();
}

class _ManageOffersScreenState extends State<ManageOffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openLaunchOffer() {
    if (widget.onCreateNewOffer != null) {
      widget.onCreateNewOffer!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LaunchOfferScreen()),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, MerchantOfferItem offer) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.errorRed),
              SizedBox(width: 8),
              Text('حذف العرض الترويجي'),
            ],
          ),
          content: Text('هل أنت تأكد من رغبتك في حذف العرض "${offer.title}"؟ لن يتمكن العملاء من استخدام هذا الكوبون بعد الآن.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
              onPressed: () {
                Provider.of<MerchantProvider>(context, listen: false).deleteOffer(offer.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف العرض بنجاح.')),
                );
              },
              child: const Text('حذف الآن', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context, MerchantOfferItem offer) {
    final titleController = TextEditingController(text: offer.title);
    final origPriceController = TextEditingController(text: offer.originalPrice.toString());
    final discPriceController = TextEditingController(text: offer.discountedPrice.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.darkSlate,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('تعديل العرض الترويجي', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'عنوان العرض',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.title, color: AppColors.primaryAmber),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: origPriceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'السعر الأصلي (د.ل)',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: discPriceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'السعر بعد الخصم (د.ل)',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAmber,
                        foregroundColor: AppColors.darkSlate,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تحديث بيانات العرض بنجاح.')),
                        );
                      },
                      child: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkSlate,
          elevation: 0,
          title: const Text(
            'إدارة العروض والتحليلات',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAmber,
                  foregroundColor: AppColors.darkSlate,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('عرض جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _openLaunchOffer,
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryAmber,
            labelColor: AppColors.primaryAmber,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'جميع العروض'),
              Tab(text: 'النشطة'),
              Tab(text: 'المتوقفة'),
            ],
          ),
        ),
        body: Consumer<MerchantProvider>(
          builder: (context, merchant, _) {
            final allOffers = merchant.merchantOffers;
            final activeOffers = allOffers.where((o) => o.status == 'active').toList();
            final pausedOffers = allOffers.where((o) => o.status != 'active').toList();

            final totalSales = allOffers.fold(0.0, (sum, item) => sum + item.totalSalesGenerated);
            final totalViews = allOffers.fold(0, (sum, item) => sum + item.viewsCount);
            final totalRedemptions = allOffers.fold(0, (sum, item) => sum + item.redemptionsCount);

            return RefreshIndicator(
              onRefresh: () async {
                await merchant.fetchMerchantOffers();
              },
              child: Column(
                children: [
                  // Top Summary Performance Bar (Scrollable for Mobile)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    color: AppColors.darkSlate,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildHeaderStat('العروض', '${allOffers.length}', AppColors.primaryAmber),
                          const SizedBox(width: 24),
                          _buildHeaderStat('المشاهدات', '$totalViews', Colors.white),
                          const SizedBox(width: 24),
                          _buildHeaderStat('الاستخدامات', '$totalRedemptions', AppColors.successGreen),
                          const SizedBox(width: 24),
                          _buildHeaderStat('الأرباح', CurrencyFormatter.format(totalSales, isArabic: true), AppColors.primaryAmberDark),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOffersList(context, allOffers, merchant),
                        _buildOffersList(context, activeOffers, merchant),
                        _buildOffersList(context, pausedOffers, merchant),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryAmber,
          foregroundColor: AppColors.darkSlate,
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('إطلاق عرض جديد', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _openLaunchOffer,
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String title, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13.5),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildOffersList(BuildContext context, List<MerchantOfferItem> offers, MerchantProvider merchant) {
    if (offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'لا توجد عروض ترويجية في هذه الفئة.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAmber,
                foregroundColor: AppColors.darkSlate,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إطلاق أول عرض الآن'),
              onPressed: _openLaunchOffer,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        final isActive = offer.status == 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: isActive ? AppColors.primaryAmber.withValues(alpha: 0.4) : AppColors.borderGrey),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkSlate,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.darkSlate.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  offer.category,
                                  style: const TextStyle(fontSize: 11, color: AppColors.darkSlate, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  offer.branches.first,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Discount Ribbon Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAmber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        offer.discountBadge,
                        style: const TextStyle(
                          color: AppColors.darkSlate,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pricing Row
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.format(offer.originalPrice, isArabic: true),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(offer.discountedPrice, isArabic: true),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkSlate,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.successGreenLight : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: isActive ? AppColors.successGreen : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'نشط' : 'متوقف',
                            style: TextStyle(
                              color: isActive ? AppColors.successGreen : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Real Usage & Redemptions Surface
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.darkSlate,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricTile('الكوبونات المحجوزة', '${offer.claimedCount}', Icons.confirmation_num_rounded, AppColors.primaryAmber),
                      Container(height: 24, width: 1, color: Colors.white24),
                      _buildMetricTile('الاستخدامات الفعلية', '${offer.redemptionsCount}', Icons.qr_code_scanner_rounded, AppColors.successGreen),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Action Buttons Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Toggle
                    Row(
                      children: [
                        Switch(
                          value: isActive,
                          activeThumbColor: AppColors.primaryAmber,
                          onChanged: (_) {
                            merchant.toggleOfferStatus(offer.id);
                          },
                        ),
                        Text(
                          isActive ? 'إيقاف' : 'تفعيل',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            side: const BorderSide(color: AppColors.darkSlate),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 15, color: AppColors.darkSlate),
                          label: const Text('تعديل', style: TextStyle(fontSize: 11.5, color: AppColors.darkSlate)),
                          onPressed: () => _showEditModal(context, offer),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                          tooltip: 'حذف العرض',
                          onPressed: () => _showDeleteDialog(context, offer),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11.5),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }
}
