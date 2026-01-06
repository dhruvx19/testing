import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'Widgets/transaction_widgets.dart';

class UpcharCoin extends StatefulWidget {
  const UpcharCoin({super.key});
  @override
  State<UpcharCoin> createState() => _UpcharCoinState();
}

class _UpcharCoinState extends State<UpcharCoin> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 58,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: 32,
            height: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Upchar-Q Coins',
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
        actions: [
          Row(
            children: [
              SvgPicture.asset(
                EcliniqIcons.questionCircleFilled.assetPath,
                width: 24,
                height: 24,
              ),
              Text(
                ' Help',
                style: EcliniqTextStyles.titleXBLarge.copyWith(
                  color: EcliniqColors.light.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(width: 20),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 24),
        child: Column(
          children: [
            SizedBox(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Color(0xFFBE8B00),
                      border: Border.all(color: Color(0xFFB8B8B8), width: 0.6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              '50',
                              style: EcliniqTextStyles.bodyLarge.copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            'Total Coins Balance Available',
                            style: EcliniqTextStyles.bodyXSmall.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 95,
                    bottom: 0,
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Color(0xBAFFFFFF),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '20 Coins',
                              style: EcliniqTextStyles.bodyLarge.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Total Deposited Till Date',
                              style: EcliniqTextStyles.bodyXSmall.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: SvgPicture.asset(
                      EcliniqIcons.upcharCoin.assetPath,
                      width: 153,
                      height: 158,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Row(
                children: [
                  Text(
                    'Transaction History',
                    style: EcliniqTextStyles.bodyLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff626060),
                    ),
                  ),
                  Spacer(),
                  Container(
                    width: 74,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Color(0xffF9F9F9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '2025',
                          style: EcliniqTextStyles.bodyLarge.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff424242),
                          ),
                        ),
                        SvgPicture.asset(
                          EcliniqIcons.angleDown.assetPath,
                          width: 18,
                          height: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            TransactionDetailsWidget(),
          ],
        ),
      ),
    );
  }
}
