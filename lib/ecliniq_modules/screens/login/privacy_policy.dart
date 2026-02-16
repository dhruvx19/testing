import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EcliniqScaffold(
      backgroundColor: EcliniqScaffold.primaryBlue,
      body: SizedBox.expand(
        child: Column(
          children: [
            const SizedBox(height: 45),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Text(
                      'Privacy Policy',
                      style:
                          EcliniqTextStyles.responsiveHeadlineBMedium(
                            context,
                          ).copyWith(
                            color: Colors.white,

                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),

                const SizedBox(width: 48),
              ],
            ),

            Expanded(
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upchar-Q Privacy Policy',
                                  style:
                                      EcliniqTextStyles.responsiveHeadlineXLarge(
                                        context,
                                      ).copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xff424242),
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Read Carefully',
                                  style:
                                      EcliniqTextStyles.responsiveTitleXLarge(
                                            context,
                                          )
                                          .copyWith(fontWeight: FontWeight.w400)
                                          .copyWith(color: Color(0xff424242)),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            width: 80,
                            height: 80,

                            child: Image.asset(
                              EcliniqIcons.termsConditions.assetPath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const Divider(height: 1),

                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(children: [
                                  
                                ],
                              ),
                              Text(
                                '''
1. INTRODUCTION
Purpose of This Privacy Policy
This Privacy Policy explains how Bloomevera Solutions LLP (“Company”, “we”, “us”, “our”) collects, uses, stores, shares, and protects personal and sensitive information of users of its digital healthcare platform (the “Platform”).
 
Applicability
This Privacy Policy applies to all users of the Platform, including patients, dependents, doctors, clinics, hospitals, and other registered users accessing the Platform through mobile applications, websites, dashboards, or related digital services operated by Bloomevera Solutions LLP.
 
Consent
We request you to carefully read this Privacy Policy and the Terms of Use before sharing any personal information with us.
This Privacy Policy applies to current and former users of the Platform. By visiting, accessing, or using the Platform, you expressly consent to the collection, receipt, storage, use, processing, disclosure, and transfer of your personal information in accordance with this Privacy Policy and applicable laws.
By providing your personal information directly or by using services offered through the Platform or integrated third-party service providers, you acknowledge and agree that:
Bloomevera Solutions LLP shall rely on the information provided by you;
No liability shall arise on Bloomevera Solutions LLP for the authenticity, accuracy, misrepresentation, fraud, or negligence relating to information disclosed by you; and
Bloomevera Solutions LLP is not obligated to independently verify such information.
 
Sensitive Personal Data Consent
Collection, use, and disclosure of Sensitive Personal Information under the Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011 require explicit consent.
By accepting this Privacy Policy, you expressly consent to Bloomevera Solutions LLP collecting, using, processing, and disclosing such information solely for the purposes of providing services through the Platform.
 
2. INFORMATION COLLECTED 
Personal Information
Name, age, gender, date of birth, profile details, and relationship details (for dependents).
 
Contact Details
Mobile number, email address, and communication preferences.
 
Medical Information
Symptoms, consultation details, prescriptions, medical history, reports, and other health-related information shared by the user or provider.
 
Device & Usage Data
IP address, device identifiers, operating system, app usage logs, timestamps, and interaction data.
 
Payment-Related Data
Transaction IDs, payment status, subscription/package details.
 (Note: The Platform does not store full card or banking details.)
 
Location Data (if applicable)
Approximate location data may be collected for service availability, provider discovery, or fraud prevention, subject to user consent.
  
3. HOW INFORMATION IS COLLECTED
User Input
Information provided during registration, booking, onboarding, communication, or support interactions.
 
Automatic Collection
Data collected automatically through app or website usage, cookies, logs, and analytics tools.
 
Third-Party Integrations
Information received from integrated services such as payment gateways, messaging providers, analytics platforms, or verification partners.
  
4.  PURPOSE OF DATA COLLECTION
Data is collected and processed by Bloomevera Solutions LLP for:
Account creation and authentication
Appointment and token management
Queue tracking and real-time updates
Communication and notifications
Customer support and grievance handling
Legal, regulatory, and compliance obligations
Analytics, reporting, and service improvement
 
5. DATA SHARING & DISCLOSURE
With Doctors / Hospitals
Relevant personal and medical information is shared with authorized providers strictly for consultation and service delivery.
 
With Labs / Pharmacy (Future Integrations)
Data may be shared with third-party service providers only upon user request or consent.
 
With Payment Gateways
Payment-related information is shared with secure, RBI-compliant payment processors to complete transactions.
 
With Government Authorities
Information may be disclosed if required by law, court order, or government authority. 
 
6. DATA SECURITY MEASURES
The Platform implements reasonable security practices, including:
Secure cloud infrastructure
Role-based access controls
Audit logs and monitoring
Periodic security reviews and updates
 
7.  DATA RETENTION POLICY
Retention Duration
Data is retained only for as long as necessary to fulfill stated purposes or as required by law.
 
Deletion Rules
Users may request deletion of their accounts and data, subject to legal or regulatory retention requirements.
 
Backup Policies
Data backups may be retained for disaster recovery and compliance purposes for a limited duration.
  
8. USER RIGHTS
Users have the right to:
Access their personal data
Correct inaccurate information
Request deletion of accounts
Withdraw consent (where legally permissible)
Request data portability (subject to feasibility and law)
Requests may be submitted via designated support channels.
  
9. COOKIES & TRACKING
Cookie Usage
The Platform may use cookies or similar technologies to enhance user experience and performance.
 
Analytics Tools
Analytics tools may be used to understand usage patterns and improve services.
 
Opt-Out Options
Users may manage cookie preferences through device or browser settings where applicable.
 
10. CHILDREN’S PRIVACY
Age Restrictions
The Platform is not intended for independent use by minors without guardian supervision.
 
Guardian Consent
Accounts for minors must be created and managed by a parent or legal guardian.
 
Data Handling for Minors
Children’s data is processed only with guardian consent and with heightened safeguards.
 
11. POLICY UPDATES
Notification of Changes
The Platform may update this Privacy Policy from time to time.
 
Effective Date
Updated policies will be effective from the date mentioned and continued use of the Platform constitutes acceptance.
 
12. CONTACT INFORMATION
Privacy Officer
For privacy-related concerns, users may contact the official email. (contact@bloomeverasolutions.com)
 
Support Contact
Queries regarding this Privacy Policy can be raised via the support email. (support@bloomeverasolutions.com)
 
13. CONFIDENTIALITY
All user information is treated as confidential by Bloomevera Solutions LLP and shall not be disclosed except:
as required by law,
as outlined in this Privacy Policy, or
with user consent.
Bloomevera Solutions LLP does not sell personal information or send unsolicited communications. Emails sent by us are limited to service-related communications, and users may opt out where applicable.
''',
                                style:
                                    EcliniqTextStyles.responsiveTitleXLarge(
                                      context,
                                    ).copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Rubik',
                                      color: Color((0xff424242)),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
