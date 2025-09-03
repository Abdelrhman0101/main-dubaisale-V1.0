import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';

// تأكد من استيراد هذه الملفات من مشروعك
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';

class PaymentScreen extends StatelessWidget {
  final Function(Locale) onLanguageChange;

  const PaymentScreen({Key? key, required this.onLanguageChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final primaryColor = Color.fromRGBO(1, 84, 126, 1);
    final borderColor = Color.fromRGBO(8, 194, 201, 1);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 25.h),

              // Back Button (مثل الشاشات السابقة)
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    SizedBox(width: 5.w),
                    Icon(Icons.arrow_back_ios, color: KTextColor, size: 20.sp),
                    Transform.translate(
                      offset: Offset(-3.w, 0),
                      child: Text(
                        s.back,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: KTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 7.h),

              Center(
                child: Text(
                  s.payment,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 24.sp,
                    color: KTextColor,
                  ),
                ),
              ),
              SizedBox(height: 25.h),

              // Total Section
              _buildTotalSection(s),
              SizedBox(height: 5.h),

              // Payment Form Section
              _buildPaymentForm(s, borderColor, currentLocale),
              SizedBox(height: 10.h),

              // Pay Now Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/manage');
                  },
                  child: Text(s.payNow,
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- الدوال المساعدة ---

  Widget _buildTotalSection(S s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [
              Color.fromRGBO(228, 248, 246, 1),
              Color.fromRGBO(201, 248, 254, 1)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
            )
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(s.total,
              style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: KTextColor)),
          Text("AED 1000",
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Color.fromRGBO(227, 34, 17, 1))),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(S s, Color borderColor, String currentLocale) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/ri_visa-fill.png',
                  width: 40.w), // تأكد من وجود صورة الشعار هنا
              SizedBox(width: 4.w),
              Text(s.payWithCreditCard,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: KTextColor)),
            ],
          ),
          SizedBox(height: 13.h),
          _buildTitledTextField(
              s.cardNumber, '1234567891011111', borderColor, currentLocale,
              isNumber: true),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _buildTitledTextField2(
                      s.expireDate, '09/2024', borderColor, currentLocale)),
              SizedBox(width: 15.w),
              Expanded(
                  child: _buildTitledTextField2(
                      s.cvv, '123', borderColor, currentLocale,
                      isNumber: true)),
            ],
          ),
          SizedBox(height: 12.h),
          _buildTitledTextField(
              s.cardHolderName, 'Ahmed Ali', borderColor, currentLocale),
        ],
      ),
    );
  }

  Widget _buildTitledTextField(String title, String initialValue,
      Color borderColor, String currentLocale,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(0, 30, 91, 1),
                fontSize: 16.sp)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color.fromRGBO(0, 30, 91, 1),
              fontSize: 12.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: Color.fromRGBO(1, 84, 126, 1), width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTitledTextField2(String title, String initialValue,
      Color borderColor, String currentLocale,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(0, 30, 91, 1),
                fontSize: 14.sp)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color.fromRGBO(0, 30, 91, 1),
              fontSize: 12.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: Color.fromRGBO(1, 84, 126, 1), width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }
}
