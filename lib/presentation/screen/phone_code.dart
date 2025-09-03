import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../router/local_notifier.dart';

class VerifyPhoneCode extends StatefulWidget {
  final LocaleChangeNotifier notifier;

  const VerifyPhoneCode({super.key, required this.notifier});

  @override
  State<VerifyPhoneCode> createState() => _VerifyPhoneCodeState();
}

class _VerifyPhoneCodeState extends State<VerifyPhoneCode> {
  final String phoneNumber = "+971 5737357344";

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.notifier,
      builder: (context, _) {
        final locale = widget.notifier.locale;
        final isArabic = locale.languageCode == 'ar';

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ListView(
                children: [
                  const SizedBox(height: 20),

                  /// Back + Language in one row
                  Row(
                    children: [
                      Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(8), // لجعل التأثير دائريًا
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios, color: KTextColor, size: 16.sp),
                             Transform.translate(
                              offset: Offset(-5.w, 0), // قربنا النص من السهم
                              child: Text(
                                S.of(context).back,
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: KTextColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
        // --- هذا هو التصحيح ---
        // 1. نحدد اللغة الجديدة. إذا كانت الحالية 'en'، نغيرها إلى 'ar' والعكس.
        final currentLocale = widget.notifier.locale;
        final newLocale = currentLocale.languageCode == 'en'
            ? const Locale('ar')
            : const Locale('en');

        // 2. نستدعي الدالة الصحيحة باللغة الجديدة
        widget.notifier.changeLocale(newLocale);
    },
                        child: Text(
                          locale.languageCode == 'ar'
                              ? S.of(context).arabic : S.of(context).english,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: KTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 98,
                      width: 125,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// Title
                  Text(
                    S.of(context).verifnum,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: KTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// Message
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      "${S.of(context).phoneverify} $phoneNumber",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: KTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Code Field
                  PinCodeTextField(
                    length: 4,
                    appContext: context,
                    onChanged: (value) {},
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 70,
                      fieldWidth: 70,
                      activeFillColor: Colors.white,
                      selectedColor: Colors.blue,
                      activeColor: const Color.fromRGBO(8, 194, 201, 1),
                      inactiveColor: const Color.fromRGBO(8, 194, 201, 1),
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 18),

                  /// Button
                  CustomButton(
                    ontap: () {
                      context.push('/resetpass');
                    },
                    text: S.of(context).verify,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}