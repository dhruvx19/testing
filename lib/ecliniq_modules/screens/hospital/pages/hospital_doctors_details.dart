import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';

import '../../profile/my_doctors/dummy_doctor.dart';
import '../widgets/doctor_detail_view_widget.dart';

class HospitalDoctorsDetails extends StatelessWidget {
  const HospitalDoctorsDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
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
            'manipal Hospital Doctor',
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          _searchBar(),
          _filterSection(),
          SizedBox(height: 10,),
          Expanded(
            child: ListView.builder(
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                return DoctorDetailView(doctor: doctors[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _filterSection(){
  return SingleChildScrollView(
    child: Row(

      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(EcliniqIcons.sort.assetPath),
              Text('Sort'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
              height: 13,
              width: 1,
              color: Colors.grey.shade400
          ),
        ),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(EcliniqIcons.filter.assetPath),
              Text('Filter'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
              height: 13,
              width: 1,
              color: Colors.grey.shade400
          ),
        ),
        Container(
          width: 125,
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 0.5)
          ),

          child: Row(

            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Speciality'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                    height: 13,
                    width: 1,
                    color: Colors.grey.shade400
                ),
              ),
              SvgPicture.asset(EcliniqIcons.angleDown.assetPath, width: 16, height: 16,),
            ],
          ),
        ),
        Container(
          width: 125,
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 0.5)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Availability'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                    height: 13,
                    width: 1,
                    color: Colors.grey.shade400
                ),
              ),
              SvgPicture.asset(EcliniqIcons.angleDown.assetPath,  width: 16, height: 16,),
            ],
          ),
        )
      ],
    ),
  );
}

Widget _searchBar(){
  return Container(
    margin: EdgeInsets.all(16),
    height: 50,
    padding: EdgeInsets.symmetric(horizontal: 10),
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey, width: 1),
    ),
    child: Row(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SvgPicture.asset(
          'lib/ecliniq_icons/assets/Magnifer.svg',
          height: 32,
          width: 32,
        ),
        Expanded(
          child: TextField(
            cursorColor: Colors.black,
            decoration: InputDecoration(
              hintText: 'Search Doctor',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
        ),
        SvgPicture.asset(
          'lib/ecliniq_icons/assets/Microphone.svg',
          height: 32,
          width: 32,
        ),
      ],
    ),
  );
}
