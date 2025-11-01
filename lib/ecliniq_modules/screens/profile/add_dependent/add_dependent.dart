import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/blood_group_selection.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/gender_selection.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/relation_selection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../ecliniq_ui/lib/tokens/colors.g.dart';
import '../../../../ecliniq_ui/lib/tokens/styles.dart';


class AddDependentBottomSheet extends StatefulWidget {
  const AddDependentBottomSheet({super.key});

  @override
  State<AddDependentBottomSheet> createState() =>
      _AddDependentBottomSheetState();
}

class _AddDependentBottomSheetState extends State<AddDependentBottomSheet> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isExpanded = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? EcliniqColors.light.bgContainerInteractiveSuccess : EcliniqColors.light.bgContainerInteractiveDestructive,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final provider = Provider.of<AddDependentProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      provider.setDateOfBirth(picked);
    }
  }

  void _uploadPhoto() {
    // TODO: Implement photo upload
    final provider = Provider.of<AddDependentProvider>(context, listen: false);
    provider.setPhotoUrl('https://example.com/photo.jpg');
    _showSnackBar('Photo uploaded successfully', true);
  }

  Future<void> _saveDependent() async {
    final provider = Provider.of<AddDependentProvider>(context, listen: false);
    final success = await provider.saveDependent();

    if (success) {
      _showSnackBar('Dependent added successfully', true);
      Navigator.pop(context);
    } else {
      _showSnackBar(provider.errorMessage ?? 'Failed to add dependent', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddDependentProvider(),
      child: Consumer<AddDependentProvider>(
        builder: (context, provider, child) {
          return Container(
            decoration: BoxDecoration(
              color: EcliniqColors.light.bgBaseOverlay,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EcliniqColors.light.strokeNeutralSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Add Dependent',
                    style: EcliniqTextStyles.headlineLarge.copyWith(
                      color: EcliniqColors.light.textPrimary,
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _uploadPhoto,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: EcliniqColors.light.strokeNeutralSubtle,
                                width: 2,
                              ),
                            ),
                            child: provider.photoUrl == null
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: EcliniqColors.light.textBrand,
                                  size: 32,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Upload\nPhoto',
                                  textAlign: TextAlign.center,
                                  style: EcliniqTextStyles.bodyXSmall.copyWith(
                                    color: EcliniqColors.light.textBrand,
                                  ),
                                ),
                              ],
                            )
                                : ClipOval(
                              child: Image.network(
                                provider.photoUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),


                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Personal Details',
                                    style: EcliniqTextStyles.titleXBLarge.copyWith(
                                      color: EcliniqColors.light.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    ' *',
                                    style: EcliniqTextStyles.titleXBLarge.copyWith(
                                      color: EcliniqColors.light.textDestructive,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: EcliniqColors.light.textTertiary,
                              ),
                            ],
                          ),
                        ),

                        if (_isExpanded) ...[

                          Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: EcliniqColors.light.bgContainerNonInteractiveNeutralExtraSubtle,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      height: 30,

                                      child: _buildTextField(
                                        label: 'First Name',
                                        isRequired: true,
                                        hint: 'Enter First Name',
                                        controller: _firstNameController,
                                        onChanged: provider.setFirstName,
                                      ),
                                    ),
                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,

                                    ),


                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      height: 30,

                                      child: _buildTextField(
                                        label: 'Last Name',
                                        isRequired: true,
                                        hint: 'Enter Last Name',
                                        controller: _lastNameController,
                                        onChanged: provider.setLastName,
                                      ),
                                    ),

                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,

                                    ),

                                    // Gender
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      height: 30,

                                      child: _buildSelectField(
                                        label: 'Gender',
                                        isRequired: true,
                                        hint: 'Select Gender',
                                        value: provider.gender,
                                        onTap: () async {
                                          final selected = await showModalBottomSheet<String>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => const GenderSelectionSheet(),
                                          );
                                          if (selected != null) {
                                            provider.setGender(selected);
                                          }
                                        },
                                      ),
                                    ),

                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,

                                    ),


                                    // Date of Birth
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      height: 30,

                                      child: _buildSelectField(
                                        label: 'Date of Birth',
                                        isRequired: true,
                                        hint: 'Select Date',
                                        value: provider.dateOfBirth != null
                                            ?'25-09-2005'
                                        // ? DateFormat('dd MMM yyyy')
                                        // .format(provider.dateOfBirth!)
                                            : null,
                                        onTap: () => _selectDate(context),
                                      ),
                                    ),

                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,

                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      height: 30,

                                      child: _buildSelectField(
                                        label: 'Relation',
                                        isRequired: true,
                                        hint: 'Select Relation',
                                        value: provider.relation,
                                        onTap: () async {
                                          final selected = await showModalBottomSheet<String>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => const RelationSelectionSheet(),
                                          );
                                          if (selected != null) {
                                            provider.setRelation(selected);
                                          }
                                        },
                                      ),
                                    ),




                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,

                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      height: 30,

                                      child: _buildTextField(
                                        label: 'Contact Number',
                                        isRequired: true,
                                        hint: 'Enter Phone Number',
                                        controller: _contactController,
                                        keyboardType: TextInputType.phone,
                                        onChanged: provider.setContactNumber,
                                      ),
                                    ),




                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,

                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      height: 30,

                                      child: _buildTextField(
                                        label: 'Email',
                                        isRequired: false,
                                        hint: 'Enter Email',
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        onChanged: provider.setEmail,
                                      ),
                                    ),



                                    // Email

                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,

                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      height: 30,

                                      child: _buildSelectField(
                                        label: 'Blood Group',
                                        isRequired: false,
                                        hint: 'Select Blood Group',
                                        value: provider.bloodGroup,
                                        onTap: () async {
                                          final selected = await showModalBottomSheet<String>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => const BloodGroupSelectionSheet(),
                                          );
                                          if (selected != null) {
                                            provider.setBloodGroup(selected);
                                          }
                                        },
                                      ),
                                    ),


                                  ],
                                ),
                              )
                          ),

                        ],

                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _saveDependent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EcliniqColors.light.bgContainerInteractiveBrand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: provider.isLoading
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: EcliniqColors.light.textFixedLight,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        'Save',
                        style: EcliniqTextStyles.titleXBLarge.copyWith(
                          color: EcliniqColors.light.textFixedLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required bool isRequired,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Text(
                label,
                style: EcliniqTextStyles.headlineXMedium.copyWith(
                  color: EcliniqColors.light.textSecondary,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: EcliniqTextStyles.headlineXMedium.copyWith(
                    color: EcliniqColors.light.textDestructive,
                  ),
                ),
            ],
          ),
        ),

        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: EcliniqTextStyles.headlineXMedium.copyWith(
                  color: EcliniqColors.light.textPlaceholder,
                ),
                border: InputBorder.none,
              ),
              style: EcliniqTextStyles.headlineXMedium.copyWith(
                color: EcliniqColors.light.textPrimary,
              ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: EcliniqTextStyles.headlineXMedium.copyWith(
                color: EcliniqColors.light.textSecondary,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: EcliniqTextStyles.headlineXMedium.copyWith(
                  color: EcliniqColors.light.textDestructive,
                ),
              ),
            const Spacer(),
            InkWell(
              onTap: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value ?? hint,
                    style: EcliniqTextStyles.headlineXMedium.copyWith(
                      color: value != null ? EcliniqColors.light.textSecondary : EcliniqColors.light.textPlaceholder,
                      fontWeight: value != null ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

      ],
    );
  }
}