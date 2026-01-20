import 'package:ecliniq/ecliniq_api/models/hospital.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';

class AboutHospital extends StatelessWidget {
  final HospitalDetail? hospital;

  const AboutHospital({super.key, this.hospital});

  @override
  Widget build(BuildContext context) {
    final aboutText = hospital != null
        ? '${hospital!.name} is a ${hospital!.type} located in ${hospital!.city}, ${hospital!.state}. Established in ${hospital!.establishmentYear}, it has ${hospital!.noOfBeds} beds and ${hospital!.numberOfDoctors} doctors serving the community.'
        : 'Hospital information not available.';

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(0xFF96BFFF),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      'About',
                      style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
             
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aboutText,
                  maxLines: 8,
                  style:  EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                
                    fontWeight: FontWeight.w400,
                    color: Color(0xff626060),
                  ),
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}
