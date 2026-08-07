import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
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
    final badgeController = TextEditingController(text: offer.discountBadge);
    final descController = TextEditingController(text: offer.description);
    String selectedCategory = offer.category.isNotEmpty ? offer.category : 'المطاعم';
    bool isSaving = false;

    final categories = ['المطاعم', 'الملابس', 'الإلكترونيات', 'الجمال', 'الرياضة', 'أطفال', 'سفر', 'سيارات'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 580),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1E26),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28), bottom: Radius.circular(28)),
                      border: Border.all(color: Colors.white12, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle & Close Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryAmber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.edit_note_rounded, color: AppColors.primaryAmber, size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'تعديل العرض الترويجي',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white60),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.white12),

                          // 1. Title Field
                          const Text(
                            'عنوان العرض',
                            style: TextStyle(color: AppColors.primaryAmber, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleController,
                            style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'أدخل عنوان العرض...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFF262A36),
                              prefixIcon: const Icon(Icons.subtitles_rounded, color: AppColors.primaryAmber, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.white12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.white12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primaryAmber, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Category Dropdown
                          const Text(
                            'فئة العرض',
                            style: TextStyle(color: AppColors.primaryAmber, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF262A36),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: categories.contains(selectedCategory) ? selectedCategory : categories.first,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF262A36),
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryAmber),
                                items: categories.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      selectedCategory = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. Discount Badge Field
                          const Text(
                            'شارة ونسبة الخصم',
                            style: TextStyle(color: AppColors.primaryAmber, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: badgeController,
                            style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'مثال: وفر حتى 20% أو وفر حتى 10 د.ل',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFF262A36),
                              prefixIcon: const Icon(Icons.stars_rounded, color: AppColors.primaryAmber, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.white12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.white12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primaryAmber, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Quick Preset Badge Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              'وفر حتى 20%',
                              'وفر حتى 30%',
                              'وفر حتى 50%',
                              'وفر حتى 5 د.ل',
                              'وفر حتى 10 د.ل',
                              'عرض خاص',
                            ].map((preset) {
                              return ActionChip(
                                backgroundColor: const Color(0xFF262A36),
                                side: BorderSide(color: badgeController.text == preset ? AppColors.primaryAmber : Colors.white12),
                                label: Text(
                                  preset,
                                  style: TextStyle(
                                    color: badgeController.text == preset ? AppColors.primaryAmber : Colors.white70,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    badgeController.text = preset;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // 4. Description Field
                          const Text(
                            'وصف العرض والشروط',
                            style: TextStyle(color: AppColors.primaryAmber, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descController,
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'أدخل التفاصيل الشروط والتفاصيل المتاحة...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFF262A36),
                              prefixIcon: const Icon(Icons.description_rounded, color: AppColors.primaryAmber, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.white12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.white12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primaryAmber, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 5. Expiry Date (Locked / Read-Only Field)
                          const Text(
                            'تاريخ الانتهاء',
                            style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_clock_rounded, color: Colors.white38, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'ينتهي في ${offer.validUntil.toIso8601String().substring(0, 10)}',
                                  style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'مقفول (غير قابل للتعديل)',
                                    style: TextStyle(color: Colors.white38, fontSize: 10.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Save Action Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAmber,
                              foregroundColor: AppColors.darkSlate,
                              minimumSize: const Size.fromHeight(50),
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: isSaving ? null : () async {
                              final newTitle = titleController.text.trim();
                              final newBadge = badgeController.text.trim();
                              final newDesc = descController.text.trim();

                              if (newTitle.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('يرجى كتابة عنوان العرض.')),
                                );
                                return;
                              }

                              setModalState(() {
                                isSaving = true;
                              });

                              final merchant = Provider.of<MerchantProvider>(context, listen: false);
                              final success = await merchant.updateOffer(offer.id, {
                                'title': newTitle,
                                'category': selectedCategory,
                                'discount_badge': newBadge.isNotEmpty ? newBadge : 'عرض خاص',
                                'description': newDesc,
                              });

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(success ? 'تم تحديث كافة بيانات العرض بنجاح وبقائه متزامناً مع قاعدة البيانات.' : 'حدث خطأ أثناء تعديل العرض.'),
                                  ),
                                );
                              }
                            },
                            child: isSaving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.darkSlate),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text('حفظ التعديلات والتزامن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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

            final totalClaimed = allOffers.fold(0, (sum, item) => sum + item.claimedCount);
            final totalRedeemed = allOffers.fold(0, (sum, item) => sum + item.redemptionsCount);

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
                          _buildHeaderStat('المحجوزة', '$totalClaimed', Colors.white),
                          const SizedBox(width: 24),
                          _buildHeaderStat('عدد الاستعمالات', '$totalRedeemed', AppColors.primaryAmberDark),
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

                // Coupon Metrics Analytics Row (الكوبونات المحجوزة & الكوبونات المستعملة)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.darkSlate.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bookmark_added_rounded, color: AppColors.copperOrange, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'المحجوزات: ',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            '${offer.claimedCount}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: AppColors.successGreen, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'عدد الاستعمالات: ',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            '${offer.redemptionsCount}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Active Status Badge Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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

                // Real Usage Surface
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.darkSlate,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _buildMetricTile('الكوبونات المحجوزة', '${offer.claimedCount}', Icons.confirmation_num_rounded, AppColors.primaryAmber),
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
