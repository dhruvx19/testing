import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/relation_selection.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../ecliniq_utils/responsive_helper.dart';
import '../../../details/widgets/date_picker_sheet.dart';
import '../provider/dependent_provider.dart';
import 'blood_group_selection.dart';
import 'gender_selection.dart';

class PersonalDetailsWidget extends StatefulWidget {
  const PersonalDetailsWidget({super.key});

  @override
  State<PersonalDetailsWidget> createState() => _PersonalDetailsWidgetState();
}

class _PersonalDetailsWidgetState extends State<PersonalDetailsWidget> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers after first frame to get provider values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  void _initializeControllers() {
    if (!_controllersInitialized && mounted) {
      final provider = Provider.of<AddDependentProvider>(
        context,
        listen: false,
      );
      _firstNameController = TextEditingController(text: provider.firstName);
      _lastNameController = TextEditingController(text: provider.lastName);
      _contactController = TextEditingController(text: provider.contactNumber);
      _emailController = TextEditingController(text: provider.email);

      _controllersInitialized = true;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? selectedDate;
    final initialDate =
        selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25));
    final provider = Provider.of<AddDependentProvider>(context, listen: false);
    final DateTime? picked = await EcliniqBottomSheet.show<DateTime>(
      context: context,
      child: DatePickerBottomSheet(initialDate: initialDate),
    );
    if (picked != null) {
      provider.setDateOfBirth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveHelper.getScreenSize(context);
    final provider = Provider.of<AddDependentProvider>(context);

    // Initialize controllers if not done yet
    if (!_controllersInitialized) {
      _initializeControllers();
    }

    // Sync controllers with provider values if they differ
    if (_controllersInitialized) {
      if (_firstNameController.text != provider.firstName) {
        _firstNameController.text = provider.firstName;
      }
      if (_lastNameController.text != provider.lastName) {
        _lastNameController.text = provider.lastName;
      }
      if (_contactController.text != provider.contactNumber) {
        _contactController.text = provider.contactNumber;
      }
      if (_emailController.text != provider.email) {
        _emailController.text = provider.email;
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: screenSize.getResponsiveValue(
          mobile: 8.0,
          mobileSmall: 6.0,
          mobileMedium: 8.0,
          mobileLarge: 10.0,
        ),
      ),
      decoration: BoxDecoration(
        color: Color(0xffF9F9F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          screenSize.getResponsiveValue(
            mobile: 8.0,
            mobileSmall: 6.0,
            mobileMedium: 8.0,
            mobileLarge: 10.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.symmetric(
                vertical: screenSize.getResponsiveValue(
                  mobile: 8.0,
                  mobileSmall: 6.0,
                  mobileMedium: 8.0,
                  mobileLarge: 10.0,
                ),
              ),
              height: screenSize.getResponsiveValue(
                mobile: 30.0,
                mobileSmall: 28.0,
                mobileMedium: 30.0,
                mobileLarge: 32.0,
              ),
              child: _controllersInitialized
                  ? _buildTextField(
                     context:   context,
                      label: 'First Name',
                      isRequired: true,
                      hint: 'Enter First Name',
                      controller: _firstNameController,
                      onChanged: (value) {
                        provider.setFirstName(value);
                      },
                    )
                  : const SizedBox.shrink(),
            ),
            Divider(
              color: Color(0xffD6D6D6),
              thickness: 0.5,
              height: 0,
            ),

            Container(
              margin: EdgeInsets.symmetric(
                vertical: screenSize.getResponsiveValue(
                  mobile: 8.0,
                  mobileSmall: 6.0,
                  mobileMedium: 8.0,
                  mobileLarge: 10.0,
                ),
              ),
              height: screenSize.getResponsiveValue(
                mobile: 30.0,
                mobileSmall: 28.0,
                mobileMedium: 30.0,
                mobileLarge: 32.0,
              ),
              child: _controllersInitialized
                  ? _buildTextField(
                     context:   context,
                      label: 'Last Name',
                      isRequired: true,
                      hint: 'Enter Last Name',
                      controller: _lastNameController,
                      onChanged: (value) {
                        provider.setLastName(value);
                      },
                    )
                  : const SizedBox.shrink(),
            ),

          Divider(
              color: Color(0xffD6D6D6),
              thickness: 0.5,
              height: 0,
            ),
            // Gender
            Container(
              margin: EdgeInsets.symmetric(
                vertical: screenSize.getResponsiveValue(
                  mobile: 8.0,
                  mobileSmall: 6.0,
                  mobileMedium: 8.0,
                  mobileLarge: 10.0,
                ),
              ),
              height: screenSize.getResponsiveValue(
                mobile: 30.0,
                mobileSmall: 28.0,
                mobileMedium: 30.0,
                mobileLarge: 32.0,
              ),
              child: _buildSelectField(
                 context:   context,
                label: 'Gender',
                isRequired: true,
                hint: 'Select Gender',
                value: provider.gender ?? provider.selectedGender,
                onTap: () async {
                  print('🔵 Opening gender selection sheet');
                  final selected = await EcliniqBottomSheet.show(
                    context: context,
                    child: GenderSelectionSheet(provider: provider),
                  );
                  // showModalBottomSheet<String>(
                  //   context: context,
                  //   isScrollControlled: true,
                  //   backgroundColor: Colors.transparent,
                  //   builder: (_) => GenderSelectionSheet(provider: provider),
                  // );
                  print('🔵 Gender selected: $selected');
                  if (selected != null) {
                    print('🔵 Setting gender to: $selected');
                    provider.setGender(selected);
                    provider.selectGender(selected); // Sync both
                    print(
                      '🔵 Gender after setting: ${provider.gender}, selectedGender: ${provider.selectedGender}',
                    );
                  } else {
                    print('🔵 No gender selected (null)');
                  }
                },
              ),
            ),

            Divider(
              color: Color(0xffD6D6D6),
              thickness: 0.5,
              height: 0,
            ),
            // Date of Birth
            Container(
              margin: EdgeInsets.symmetric(
                vertical: screenSize.getResponsiveValue(
                  mobile: 8.0,
                  mobileSmall: 6.0,
                  mobileMedium: 8.0,
                  mobileLarge: 10.0,
                ),
              ),
              height: screenSize.getResponsiveValue(
                mobile: 30.0,
                mobileSmall: 28.0,
                mobileMedium: 30.0,
                mobileLarge: 32.0,
              ),
              child: _buildSelectField(
                 context:   context,
                label: 'Date of Birth',
                isRequired: true,
                hint: 'Select Date',
                value: provider.dateOfBirth != null
                    ? DateFormat('dd MMM yyyy').format(provider.dateOfBirth!)
                    : null,
                onTap: () => _selectDate(context),
              ),
            ),
 Divider(
              color: Color(0xffD6D6D6),
              thickness: 0.5,
              height: 0,
            ),

            Container(
              margin: EdgeInsets.symmetric(
                vertical: screenSize.getResponsiveValue(
                  mobile: 8.0,
                  mobileSmall: 6.0,
                  mobileMedium: 8.0,
                  mobileLarge: 10.0,
                ),
              ),
              height: screenSize.getResponsiveValue(
                mobile: 30.0,
                mobileSmall: 28.0,
                mobileMedium: 30.0,
                mobileLarge: 32.0,
              ),
              child: _buildSelectField(
                 context:   context,
                label: 'Relation',
                isRequired: true,
                hint: 'Select Relation',
                value: provider.relation ?? provider.selectedRelation,
                onTap: () async {
                  print('🟢 Opening relation selection sheet');
                  final selected = await EcliniqBottomSheet.show(
                    context: context,
                    child: RelationSelectionSheet(provider: provider),
                  );

                  print('🟢 Relation selected: $selected');
                  if (selected != null) {
                    print('🟢 Setting relation to: $selected');
                    provider.setRelation(selected);
                    provider.selectRelation(selected); // Sync both
                    print(
                      '🟢 Relation after setting: ${provider.relation}, selectedRelation: ${provider.selectedRelation}',
                    );
                  } else {
                    print('🟢 No relation selected (null)');
                  }
                },
              ),
            ),

            Divider(
              color: Color(0xffD6D6D6),
              thickness: 0.5,
              height: 0,
            ),
            Container(
              margin: EdgeInsets.symmetric(
                vertical: screenSize.getResponsiveValue(
                  mobile: 8.0,
                  mobileSmall: 6.0,
                  mobileMedium: 8.0,
                  mobileLarge: 10.0,
                ),
              ),
              height: screenSize.getResponsiveValue(
                mobile: 30.0,
                mobileSmall: 28.0,
                mobileMedium: 30.0,
                mobileLarge: 32.0,
              ),
              child: _controllersInitialized
                  ? _buildTextField(
                     context:   context,
                      label: 'Contact Number',
                      isRequired: true,
                      hint: 'Enter Phone Number',
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        provider.setContactNumber(value);
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            Divider(
              color: Color(0xffD6D6D6),
              thickness: 0.5,
              height: 0,
            ),
            Container(
              margin: EdgeInsets.symmetric(
                vertical: screenSize.getResponsiveValue(
                  mobile: 8.0,
                  mobileSmall: 6.0,
                  mobileMedium: 8.0,
                  mobileLarge: 10.0,
                ),
              ),
              height: screenSize.getResponsiveValue(
                mobile: 30.0,
                mobileSmall: 28.0,
                mobileMedium: 30.0,
                mobileLarge: 32.0,
              ),
              child: _controllersInitialized
                  ? _buildTextField(
                     context:   context,
                      label: 'Email',
                      isRequired: false,
                      hint: 'Enter Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        provider.setEmail(value);
                      },
                    )
                  : const SizedBox.shrink(),
            ),

            Divider(
              color: Color(0xffD6D6D6),
              thickness: 0.5,
              height: 0,
            ),
            Container(
              margin: EdgeInsets.symmetric(
                vertical: screenSize.getResponsiveValue(
                  mobile: 8.0,
                  mobileSmall: 6.0,
                  mobileMedium: 8.0,
                  mobileLarge: 10.0,
                ),
              ),
              height: screenSize.getResponsiveValue(
                mobile: 30.0,
                mobileSmall: 28.0,
                mobileMedium: 30.0,
                mobileLarge: 32.0,
              ),
              child: _buildSelectField(
                 context:   context,
                label: 'Blood Group',
                isRequired: false,
                hint: 'Select Blood Group',
                value: provider.bloodGroup,
                onTap: () async {
                  final selected = await EcliniqBottomSheet.show(
                    context: context,
                    child: BloodGroupSelectionSheet(),
                  );
                  if (selected != null) {
                    provider.setBloodGroup(selected);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTextField({
  required String label,
  required bool isRequired,
  required String hint,
  required TextEditingController controller,
  TextInputType? keyboardType,
  required Function(String) onChanged,
  List<TextInputFormatter>? inputFormatters,
  required BuildContext context,
}) {
  return Row(
    children: [
      Expanded(
        flex: 1,
        child: Row(
          children: [
            Text(
              label,
              style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                color: Color(0xff626060),
              ),
            ),
            if (isRequired)
              Text('•', style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(color: Colors.red)),
          ],
        ),
      ),

      Expanded(
        flex: 1,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          textAlign: TextAlign.right,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
              color: Color(0xffB8B8B8),
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
            color: Color(0xff424242)
          ),
        ),
      ),
    ],
  );
}

Widget _buildSelectField({
  required String label,
  required bool isRequired,
  required String hint,
  required String? value,
  required VoidCallback onTap,
  required BuildContext context,
}) {
  return InkWell(
    onTap: onTap,
    child: Row(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Text(
                label,
                style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                  color: Color(0xff626060),
                ),
              ),
              if (isRequired)
                Text('•', style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(color: Colors.red)),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value ?? hint,
              textAlign: TextAlign.right,
              style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                color: value != null
                    ? Color(0xff424242)
                    : Color(0xffB8B8B8),
                fontWeight: value != null ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
