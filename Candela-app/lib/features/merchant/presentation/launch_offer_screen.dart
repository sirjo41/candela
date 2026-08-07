import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../models/merchant_offer_form.dart';
import '../providers/merchant_provider.dart';
import 'widgets/live_offer_preview_card.dart';

/// Launch New Offer Form Screen matching reference screenshot IMG-20260725-WA0014.jpg
/// Includes live preview card, category selector, branch checkboxes, price inputs & creation fee badge in RTL mode.
class LaunchOfferScreen extends StatefulWidget {
  const LaunchOfferScreen({super.key});

  @override
  State<LaunchOfferScreen> createState() => _LaunchOfferScreenState();
}

class _LaunchOfferScreenState extends State<LaunchOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final MerchantOfferForm _form = MerchantOfferForm();

  final TextEditingController _titleController = TextEditingController(text: 'اشتري 2 واحصل على 1 مجاناً');
  final TextEditingController _descriptionController = TextEditingController(text: 'احصل على قطعة مجانية عند شراء قطعتين من أي قسم.');
  final TextEditingController _discountValueController = TextEditingController(text: '20');
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _discountedPriceController = TextEditingController();

  final List<String> _availableCategories = [
    'المطاعم',
    'الملابس',
    'الإلكترونيات',
    'الجمال',
    'الرياضة',
    'أطفال',
    'سفر',
    'سيارات',
  ];

  final List<String> _allBranches = [
    'الفرع الرئيسي - وسط المدينة',
    'فرع شارع عمر المختار',
  ];

  final List<String> _quickPresetDeals = [
    'اشتري 2 واحصل على 1 مجاناً',
    'خصم 20% للطلبات فوق 50 د.ل',
    'كب كيك مجاني مع كل قهوة',
    'مشروب مجاني مع أي وجبة',
  ];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateFormState);
    _descriptionController.addListener(_updateFormState);
    _discountValueController.addListener(_updateFormState);
    _originalPriceController.addListener(_updateFormState);
    _discountedPriceController.addListener(_updateFormState);
    _updateFormState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    setState(() {
      _form.title = _titleController.text;
      _form.description = _descriptionController.text;
      _form.discountValue = double.tryParse(_discountValueController.text);
      _form.originalPrice = double.tryParse(_originalPriceController.text);
      _form.discountedPrice = double.tryParse(_discountedPriceController.text);
    });
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _form.endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _form.endDate = picked;
      });
    }
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;

    final merchant = Provider.of<MerchantProvider>(context, listen: false);
    final success = await merchant.createOffer(_form);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تم إطلاق العرض بنجاح! خصم ${CurrencyFormatter.format(_form.creationFee, isArabic: true)} رسوم إنشاء.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            merchant.errorMessage ?? 'فشل إطلاق العرض. يرجى التأكد من رصيد المحفظة.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchant = Provider.of<MerchantProvider>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkSlate,
          title: const Text(
            'إطلاق عرض جديد',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
          ),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Live Preview Card Widget at the top
                    LiveOfferPreviewCard(
                      form: _form,
                      storeName: merchant.storeName,
                    ),
                    const SizedBox(height: 24),

                    // 2. Form Inputs Header
                    const Text(
                      'بيانات العرض الترويجي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Offer Title Input
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان العرض (مثال: اشتري 2 واحصل على 1 مجاناً)',
                        prefixIcon: Icon(Icons.title_rounded, color: AppColors.darkSlate),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال عنوان العرض' : null,
                    ),
                    const SizedBox(height: 8),

                    // Quick Preset Deal Buttons
                    SizedBox(
                      height: 34,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickPresetDeals.length,
                        itemBuilder: (ctx, idx) {
                          final preset = _quickPresetDeals[idx];
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ActionChip(
                              backgroundColor: AppColors.darkSlate.withValues(alpha: 0.06),
                              side: const BorderSide(color: AppColors.borderGrey),
                              label: Text(preset, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkSlate)),
                              onPressed: () {
                                _titleController.text = preset;
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description Input
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'تفاصيل وشروط العرض',
                        prefixIcon: Icon(Icons.description_outlined, color: AppColors.darkSlate),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown Selector
                    DropdownButtonFormField<String>(
                      initialValue: _form.category,
                      decoration: const InputDecoration(
                        labelText: 'القسم الرئيسي للعرض',
                        prefixIcon: Icon(Icons.category_outlined, color: AppColors.darkSlate),
                      ),
                      items: _availableCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _form.category = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campaign Participation Dropdown Selector (Optional or Null)
                    DropdownButtonFormField<int?>(
                      initialValue: _form.campaignId,
                      decoration: const InputDecoration(
                        labelText: 'المشاركة في حملة ترويجية (اختياري / Null)',
                        hintText: 'اختر حملة لتضمين العرض بها أو اتركه فارغاً',
                        prefixIcon: Icon(Icons.campaign_rounded, color: AppColors.copperOrange),
                      ),
                      items: const [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('بدون مشاركة في حملة (عرض مستقل)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                        ),
                        DropdownMenuItem<int?>(
                          value: 1,
                          child: Text('مهرجان الصيف للتسوق 2026 ✦ (حملة نشطة)', style: TextStyle(color: AppColors.darkSlate, fontWeight: FontWeight.bold)),
                        ),
                        DropdownMenuItem<int?>(
                          value: 2,
                          child: Text('حملة العودة للمدارس والجامعات', style: TextStyle(color: AppColors.darkSlate, fontWeight: FontWeight.bold)),
                        ),
                        DropdownMenuItem<int?>(
                          value: 3,
                          child: Text('مهرجان التخفيضات الكبرى', style: TextStyle(color: AppColors.darkSlate, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _form.campaignId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Discount Type Choice Header (Percentage vs Fixed Price)
                    const Text(
                      'نوع الخصم والتخفيض:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkSlate),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _form.discountType = 'percentage';
                                  if (_discountValueController.text == '10' || _discountValueController.text.isEmpty) {
                                    _discountValueController.text = '20';
                                  }
                                  _updateFormState();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _form.discountType == 'percentage' ? AppColors.copperOrange : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'نسبة مئوية (%)',
                                    style: TextStyle(
                                      color: _form.discountType == 'percentage' ? Colors.white : AppColors.darkSlate,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _form.discountType = 'fixed';
                                  if (_discountValueController.text == '20' || _discountValueController.text.isEmpty) {
                                    _discountValueController.text = '10';
                                  }
                                  _updateFormState();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _form.discountType == 'fixed' ? AppColors.copperOrange : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'مبلغ ثابت (د.ل)',
                                    style: TextStyle(
                                      color: _form.discountType == 'fixed' ? Colors.white : AppColors.darkSlate,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Discount Value Input (e.g. 20% or 10 D.L)
                    TextFormField(
                      controller: _discountValueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: _form.discountType == 'fixed' ? 'قيمة الخصم بالدينار (مثال: 10)' : 'نسبة الخصم مئوية (مثال: 20)',
                        hintText: _form.discountType == 'fixed' ? '10' : '20',
                        prefixIcon: Icon(
                          _form.discountType == 'fixed' ? Icons.attach_money_rounded : Icons.percent_rounded,
                          color: AppColors.copperOrange,
                        ),
                        suffixText: _form.discountType == 'fixed' ? 'د.ل' : '%',
                      ),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'يرجى إدخال قيمة الخصم';
                        if (_form.discountType == 'percentage' && val > 100) return 'لا يمكن أن تتجاوز النسبة 100%';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Badge Live Display Callout
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.copperOrange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'الشارة الظاهرة للعميل: ${_form.discountBadgeText}',
                              style: const TextStyle(
                                color: AppColors.darkSlate,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Branch Picker Checkboxes
                    const Text(
                      'الفروع المتاحة للعرض:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkSlate),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Column(
                        children: _allBranches.map((branch) {
                          final isSelected = _form.selectedBranches.contains(branch);
                          return CheckboxListTile(
                            activeColor: AppColors.primaryAmber,
                            checkColor: AppColors.darkSlate,
                            title: Text(branch, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            value: isSelected,
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked == true) {
                                  _form.selectedBranches.add(branch);
                                } else {
                                  _form.selectedBranches.remove(branch);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date Expiry Picker
                    InkWell(
                      onTap: () => _selectExpiryDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, color: AppColors.darkSlate, size: 18),
                                SizedBox(width: 10),
                                Text(
                                  'تاريخ انتهاء صلاحية العرض',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ],
                            ),
                            Text(
                              '${_form.endDate.year}-${_form.endDate.month.toString().padLeft(2, '0')}-${_form.endDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryAmberDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Creation Fee Notice Badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkSlate,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryAmber, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'رسوم إطلاق العرض الترويجي',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'سيتم خصم ${CurrencyFormatter.format(_form.creationFee, isArabic: true)} تلقائياً من محفظة التاجر عند الإطلاق.',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Launch Action Button
                    merchant.isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAmber))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAmber,
                              foregroundColor: AppColors.darkSlate,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _submitOffer,
                            child: const Text(
                              'إطلاق العرض الآن وتطبيقه للعملاء',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
