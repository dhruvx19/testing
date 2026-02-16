import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

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
                      'Terms & Condition',
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
                                  'Upchar-Q Terms and conditions',
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
The digital healthcare platform, including its mobile application, website, dashboards, and related services (collectively, the “Platform”), is owned, operated, and managed by Bloomevera Solutions LLP, a limited liability partnership incorporated under the laws of India, having its registered office at:
 
Bloomevera Solutions LLP
Registered Address: House no 69, Nisarg Garden, near Gajanan temple, Geeta nagar, akola , Maharashtra, India 444001
 
All references to “we”, “us”, “our”, “Company”, or “Platform Owner” in these Terms refer to Bloomevera Solutions LLP, unless the context requires otherwise.

1. Introduction & Acceptance
 
1.1 Introduction
These Terms and Conditions (“Terms”) govern access to and use of the Platform operated by Bloomevera Solutions LLP. The Platform facilitates appointment booking, digital token generation, queue management, and related healthcare support services between patients and healthcare providers, including doctors, clinics, hospitals, and allied healthcare service providers (“Providers”).
The Platform acts solely as a technology facilitator and does not provide medical advice, diagnosis, or treatment.
 
1.2 Scope of Services
The Platform enables users to:
View healthcare providers and their availability
Book appointments and obtain digital tokens
Manage walk-in and scheduled consultations
Receive notifications related to queue status and appointments
Access ancillary healthcare-related information and services as may be introduced from time to time
 
The scope of services may be modified, expanded, restricted, or discontinued at the sole discretion of the Platform, without prior notice.
 
1.3 Acceptance of Terms
By accessing, registering on, or using the Platform in any manner, the user (“User”, which includes patients, caregivers, and providers, as applicable) acknowledges that they have read, understood, and agreed to be bound by these Terms, along with the Privacy Policy and any other policies referenced herein.
If the User does not agree to these Terms, they must immediately discontinue use of the Platform.
 
1.4 Electronic Acceptance
Acceptance occurs when the User:
Registers on the Platform
Logs in using OTP-based authentication
Clicks “I Agree” or similar consent
Continues using the Platform after Terms updates
Such acceptance constitutes a valid electronic agreement under the Information Technology Act, 2000.
 
1.5 Amendments to Terms
The Platform reserves the right to modify, amend, or update these Terms at any time to reflect changes in services, legal requirements, or operational practices. Updated Terms will be made available on the Platform and shall become effective upon publication, unless otherwise specified.
Continued use of the Platform after such changes constitutes the User’s acceptance of the revised Terms.
 
1.6 Supplemental Policies
These Terms shall be read in conjunction with other policies published on the Platform, including but not limited to:
Privacy Policy
Token Booking, Cancellation & Rescheduling Policy
Payment and Refund Policy
Provider-Specific Policies
In the event of any conflict, the specific policy applicable to the service shall prevail.
 
2. DEFINITIONS & INTERPRETATIONS

2.1 Definitions
Unless the context otherwise requires, the following terms shall have the meanings assigned to them below:

“Platform”
Means the digital technology system owned and operated by Bloomevera Solutions LLP, including its mobile applications, website, dashboards, APIs, and related digital interfaces, that facilitates healthcare appointment booking, token generation, queue management, notifications, and other allied digital services.

“User” / “Patient”
Means any individual who accesses or uses the Platform for the purpose of booking appointments, obtaining tokens, managing healthcare visits, or availing related services for themselves or on behalf of a dependent, including caregivers or authorized representatives.

“Provider”
Means any healthcare service provider registered on the Platform, including but not limited to:
Doctors (individual medical practitioners),
Clinics,
Hospitals, and
Diagnostic Labs or allied healthcare facilities,
who offer healthcare services and make their availability accessible through the Platform.

“Token”
Means a digital queue identifier generated through the Platform that represents a user’s position in a consultation or service queue for a specific Provider, service, date, and time slot. A Token does not guarantee consultation outcome, medical advice, or exact consultation time.

“Appointment”
Means a scheduled healthcare consultation or service booking made through the Platform, which may be time-based or token-based, subject to Provider availability, operational constraints, and Platform rules.
 
“Walk-in”
Means a healthcare visit initiated by a Patient without a prior scheduled appointment, which may be recorded, managed, or tokenized through the Platform at the Provider’s discretion.

“Digital Services”
Means all technology-enabled services offered by the Platform, including but not limited to appointment booking, token management, notifications, dashboards, data records, analytics, reports, and communication tools.

“Third-Party Services”
Means services, content, systems, or platforms provided by external entities and integrated with the Platform, including but not limited to payment gateways, messaging services, cloud infrastructure, verification services, or analytics tools. The Platform does not control or assume responsibility for such Third-Party Services.

“Subscription” / “Package”
Means a paid or free service plan offered by the Platform to Providers or Users, granting access to specific features, limits, duration, or service levels, subject to applicable fees, terms, and renewal conditions.

“Personal Data”
Means any information that relates to an identified or identifiable individual, including but not limited to name, contact details, age, gender, and other demographic information provided or generated through the Platform.

“Sensitive Personal Data”
Means personal data of a sensitive nature, including but not limited to health-related information, medical history, consultation details, prescriptions, diagnostic data, and any other information classified as sensitive under applicable data protection laws.
 
2.2 Interpretation
Unless the context otherwise requires:
Words importing the singular shall include the plural and vice versa.
Words importing any gender shall include all genders.
Headings are for convenience only and shall not affect interpretation.
References to statutes or laws shall include amendments and replacements thereto.
The terms “include” or “including” shall be construed without limitation.
 
3. ELIGIBILITY TO USE
 
3.1 Minimum Age Requirement
Use of the Platform is permitted only to individuals who are legally competent to enter into binding contracts under applicable laws.
Users must be at least 18 years of age to register and use the Platform independently.
By accessing or using the Platform, the User represents and warrants that they meet the minimum age and legal capacity requirements.
 
3.2 Use by Dependents (Parent / Guardian Consent)
The Platform permits booking and management of healthcare services on behalf of dependents, including minors, elderly individuals, or persons unable to operate the Platform independently.
Any User acting on behalf of a dependent represents that they are the parent, legal guardian, or duly authorized caregiver of such dependent.
The User agrees to obtain and provide all necessary consents and authorizations, including consent for collection, use, and sharing of the dependent’s Personal and Sensitive Personal Data.
The Platform shall not be responsible for verifying the authenticity of such authorization and shall rely on the representations made by the User.
 
3.3 Provider Eligibility & Verification
Only duly qualified, licensed, and legally authorized healthcare Providers may register on the Platform.
Providers must submit accurate and complete information, including professional credentials, registrations, licenses, clinic or hospital details, and any other documentation required by the Platform.
The Platform reserves the right to verify, approve, reject, or request additional information during or after Provider onboarding.
Registration on the Platform does not constitute endorsement, employment, or partnership between the Platform and any Provider.
Providers remain solely responsible for ensuring compliance with all applicable medical, professional, and regulatory requirements.
 
3.4 Right to Deny, Suspend, or Terminate Access
The Platform reserves the right, at its sole discretion and without prior notice, to deny, suspend, restrict, or terminate access to any User or Provider who:
violates these Terms & Conditions;
provides false, misleading, or incomplete information;
engages in fraudulent, abusive, or unlawful activity;
compromises Platform security or integrity; or
poses a risk to other Users, Providers, or the Platform.
Suspension or termination may include disabling accounts, restricting features, withholding access to data, or revoking tokens, appointments, or subscriptions.
The Platform shall not be liable for any loss or inconvenience arising from such actions taken in accordance with these Terms.
  
4. ACCOUNT REGISTRATION & ACCESS

4.1 Account Creation Process
To access the Platform and its services, Users and Providers must complete the account registration process as prescribed by the Platform.
Registration may require submission of personal, contact, and professional information, as applicable.
The Platform reserves the right to modify registration requirements from time to time.
 
4.2 Accuracy of Information
Users and Providers agree to provide true, accurate, current, and complete information during registration and thereafter.
Any change in registered information must be promptly updated through the Platform.
The Platform shall not be responsible for consequences arising from inaccurate, outdated, or misleading information provided by the User or Provider.
 
4.3 Mobile Number-Based Login
Access to the Platform is primarily enabled through mobile number-based login.
The registered mobile number shall be treated as the unique identifier for the account.
Users are responsible for ensuring continued access to their registered mobile number.
 
4.4 OTP Authentication
Login and authentication may be conducted through One-Time Passwords (OTP) sent via SMS, WhatsApp, or other approved communication channels.
OTPs are system-generated, time-bound, and confidential.
Users agree not to share OTPs with any third party.
The Platform shall not be liable for unauthorized access resulting from OTP misuse or compromise.
 
4.5 Responsibility for Account Security
Users and Providers are solely responsible for maintaining the confidentiality and security of their account credentials, devices, and access details.
Any activity conducted through a registered account shall be deemed to have been authorized by the account holder.
Users must immediately notify the Platform of any suspected unauthorized access or security breach.
 
4.6 One Account per User Rule
Each User or Provider is permitted to maintain only one active account on the Platform.
Creation of multiple accounts using different mobile numbers, identities, or credentials is prohibited.
The Platform reserves the right to merge, suspend, or terminate duplicate accounts without prior notice.
  
4.7 Deactivation / Termination Conditions
Users or Providers may request deactivation of their account subject to completion of any ongoing obligations, appointments, or payments.
The Platform may suspend or terminate accounts in cases including but not limited to:
violation of Terms & Conditions;
fraudulent or abusive activity;
repeated misuse of the token or booking system;
regulatory or legal non-compliance;
prolonged inactivity, where applicable.
Upon termination, access to Platform services may be restricted or permanently disabled, and associated data may be retained or deleted in accordance with applicable laws and the Privacy Policy.
  
5. TOKEN & APPOINTMENT SYSTEM
 
5.1 Nature of Token
A token issued through the Platform represents a queue position for consultation and does not guarantee a fixed or exact consultation time.
Tokens are issued based on availability displayed at the time of booking and are subject to real-time changes at the Provider’s premises.
The Platform does not guarantee uninterrupted consultation flow or adherence to estimated schedules.
 
5.2 Estimated vs Actual Consultation Time
Any consultation time shown on the Platform is an estimated time only.
Actual consultation may occur earlier or later due to factors including but not limited to:
consultation duration variability;
emergency cases;
provider delays;
walk-in patients;
operational constraints.
Users acknowledge that delays do not constitute a service deficiency or entitlement to compensation.
 
5.3 Walk-In vs Online Token Rules
Providers may accept walk-in patients, either manually or via Platform entry.
Walk-in tokens may be interleaved with online tokens based on Provider-defined rules.
Online token holders acknowledge that walk-in priority or emergency cases may affect queue movement.
The Platform shall not be liable for changes arising from walk-in management decisions.
 
5.4 Token Validity
Each token is valid only for the specific doctor, service, date, and session for which it is issued.
Tokens are non-transferable and cannot be reused across sessions or providers.
A token becomes invalid once marked as completed, cancelled, expired, or no-show.
 
5.5 Token Expiry Rules
Tokens automatically expire upon but not limited to:
session completion;
doctor session closure;
explicit cancellation by User or Provider.
Expired tokens cannot be reinstated and require fresh booking.
 
5.6 No-Show Handling
Failure to arrive within the session period without prior cancellation may result in no-show status.
The Platform or Provider may apply penalties including:
loss of consultation fee (if applicable);
restriction on future bookings;
downgrade of booking privileges.
Repeated no-shows may lead to temporary or permanent account suspension.
 
5.7 Priority Cases
Providers reserve the right to prioritize:
emergency cases;
senior citizens;
differently-abled patients;
critical medical conditions;
government-mandated priority categories.
Priority handling may result in queue hold without prior notice.
Such prioritization shall not be treated as discrimination or service failure.
 
5.8 Doctor Delay or Absence Handling
a) In case of provider delay, Users may experience changes in estimated consultation time.
 b) In case of provider unavailability or session cancellation:
     i) tokens may be rescheduled, cancelled, or refunded as applicable;
     ii) alternative providers may be suggested, where available.
 c) The Platform shall not be liable for losses arising from provider unavailability beyond reasonable facilitation.
  
6. PLATFORM ROLE & DISCLAIMER
 
6.1 Platform as a Facilitator
Bloomevera Solutions LLP, through the Platform, acts solely as a technology-enabled facilitator that enables Users to discover, book, and manage tokens, appointments, and related digital healthcare services.
The Platform does not provide medical advice, diagnosis, treatment, or healthcare services of any kind.
All medical services are provided independently by Providers, and the Platform does not control or influence medical decisions or practices.
 
6.2 No Guarantee of Medical Outcomes
The Platform makes no representation or warranty regarding the accuracy, effectiveness, quality, or outcome of any medical service provided by a Provider.
Medical outcomes depend on multiple factors beyond the Platform’s control, including patient condition, provider expertise, and clinical judgment.
Users acknowledge that healthcare involves inherent risks and uncertainties.
 
6.3 No Emergency Services Disclaimer
The Platform does not offer emergency or life-saving medical services.
Users must not rely on the Platform for urgent or emergency medical situations.
In case of medical emergencies, Users are advised to immediately contact local emergency services or visit the nearest emergency healthcare facility.
 
6.4 Provider Responsibility for Diagnosis & Treatment
Providers are solely responsible for:
medical diagnosis;
treatment decisions;
prescriptions;
clinical advice;
compliance with applicable medical laws, guidelines, and ethical standards.
The Platform does not verify the medical accuracy of diagnoses, prescriptions, or treatment plans.
Users are encouraged to seek second opinions where necessary.
 
6.5 Limitation of Liability for Medical Negligence
The Platform shall not be liable for any act, omission, negligence, malpractice, or misconduct of any Provider.
Any disputes, claims, or grievances related to medical care must be addressed directly with the concerned Provider.
The Platform shall not be a party to any medical dispute between Users and Providers.
The Platform’s liability, if any, shall be limited strictly to facilitating the digital service and shall not extend to clinical outcomes.
 
6.6 Third-Party & Provider Independence
Providers listed on the Platform operate as independent professionals or entities and are not employees, agents, or representatives of the Platform.
Listing or availability of a Provider does not imply endorsement or recommendation by the Platform
  
7. BOOKING, CANCELLATION & RESCHEDULING
 
7.1 Booking Confirmation Rules
Booking of an appointment or token through the Platform is subject to availability as displayed at the time of booking.
A booking shall be considered confirmed only upon receipt of a confirmation notification from the Platform.
The Platform reserves the right to reject or modify bookings in case of operational, technical, or Provider-related constraints.
 
7.2 Auto-Confirmation vs Manual Confirmation
Certain Providers may enable auto-confirmation, wherein bookings are automatically confirmed upon successful request and payment (if applicable).
Other Providers may require manual confirmation, subject to approval by the Provider or authorized staff.
Until manual confirmation is completed, such bookings shall remain in a pending state and do not guarantee consultation.
 
7.3 Cancellation Timelines
Users can not cancel a confirmed booking.
 
7.4 Rescheduling Limits
Users may reschedule bookings before the session start time subject to availability and Provider-defined rules.
The number of permitted reschedules may be limited per booking or per User.
Rescheduling beyond permitted limits may require fresh booking or may attract additional charges.
 
7.5 Refund Eligibility
Refund eligibility, if any, shall be governed by:
Source of cancellation;
mode of payment;
completion status of the service.
Refunds, where applicable, shall be processed in the terms of coins on the application which shall be redeemed for further bookings
we will credit the credit points your account within 4-5 days, you can use for future purchase.
Refunds, where applicable, shall be processed in the form of platform credits (“Coins”) issued by Bloomevera Solutions LLP and credited to the User’s account within 4–5 business days. 
 
7.6 Provider-Initiated Cancellation Rules
Providers may cancel or reschedule appointments due to emergencies, unavailability, or operational constraints.
In such cases, the Platform may:
notify affected Users;
facilitate rescheduling;
initiate refunds, where applicable.
The Platform shall not be liable for Provider-initiated cancellations beyond facilitating communication and applicable refunds.
  
8. PROVIDER-SPECIFIC TERMS
 
8.1 Provider Onboarding Conditions
All Providers must complete the onboarding process prescribed by the Platform, including submission of required documents, credentials, and business details.
Onboarding does not guarantee approval or listing on the Platform.
The Platform reserves the absolute right to accept, reject, or revoke Provider onboarding at its sole discretion.
 
8.2 Verification & Approval Rights of the Platform
The Platform may verify Provider credentials, registrations, licenses, and certifications either directly or through third-party verification agencies.
Verification by the Platform does not constitute endorsement, certification, or warranty of medical competence.
The Platform may suspend or restrict Provider access pending verification or re-verification.
 
8.3 Accuracy of Provider Information
Providers are solely responsible for ensuring that all information displayed on the Platform, including qualifications, specialization, consultation timings, fees, and services, is accurate, complete, and up to date.
The Platform shall not be liable for inaccuracies, omissions, or misrepresentations made by Providers.
Providers must promptly update any changes to their information through the Platform.
 
8.4 Service Availability & Operational Responsibility
Providers are responsible for honoring confirmed bookings, tokens, and service schedules displayed on the Platform.
Providers must ensure adequate staffing, infrastructure, and availability to manage token flow and patient consultations.
The Platform shall not be responsible for delays, cancellations, or service deficiencies arising from Provider operations.
 
8.5 Subscription / Package Terms
Access to certain Platform features may be subject to paid subscription plans or packages.
Subscription fees, duration, features, and renewal terms shall be communicated at the time of purchase.
Subscription fees are generally non-refundable unless expressly stated otherwise.
The Platform reserves the right to modify subscription pricing or features with prior notice.
 
8.6 Usage Limits (OPD Slabs)
Providers may be subject to usage limits based on subscribed plans, including but not limited to:
number of OPD tokens per day;
number of doctors or staff accounts;
access to analytics or integrations.
Exceeding defined limits may result in throttling, additional charges, or upgrade requirements.
 
8.7 Suspension & Termination Rules
The Platform may suspend or terminate Provider access, with or without notice, in cases including but not limited to:
violation of these Terms;
submission of false or misleading information;
repeated patient complaints;
non-payment of subscription fees;
regulatory or legal non-compliance.
Suspension or termination shall not affect accrued payment obligations.
 
8.8 Compliance with Laws & Medical Councils
Providers shall comply with all applicable laws, regulations, and professional standards, including but not limited to:
local healthcare regulations;
medical council rules;
data protection and patient confidentiality laws.
Providers are solely responsible for maintaining valid licenses and registrations at all times.
Any non-compliance shall be grounds for immediate suspension or termination.
 
9. PATIENT RESPONSIBILITIES

9.1 Accurate Information Disclosure
Patients shall provide true, accurate, complete, and up-to-date personal, demographic, and contact information while registering and using the Platform.
Patients are responsible for ensuring the correctness of medical details, symptoms, and consultation-related information shared with Providers.
The Platform shall not be liable for any consequences arising from inaccurate, incomplete, or misleading information provided by patients.
 
9.2 Arrival Time Responsibility
Patients are responsible for arriving at the Provider location or being available for consultation within the allocated token window, including if any applicable grace period.
Estimated consultation times are indicative only and may vary based on queue flow and clinical circumstances.
Late arrival may result in token cancellation, rescheduling, or reprioritization at the Provider’s discretion.
 
9.3 Compliance with Clinic / Hospital Policies
Patients shall comply with the operational, safety, hygiene, and administrative policies of the respective clinic, hospital, or Provider.
The Platform does not control or enforce Provider-specific rules and shall not be liable for disputes arising from such policies.
Any violation of Provider premises rules may result in denial of service.
 
9.4 Misuse or Abuse of the Platform
Patients shall not misuse the Platform, including but not limited to:
booking multiple tokens without intent to visit;
providing false information;
abusing Providers, staff, or Platform support;
attempting to manipulate token queues or system behaviour.
The Platform reserves the right to restrict, suspend, or terminate access in cases of misuse or abuse.
 
9.5 Consequences of Repeated No-Shows
Repeated failure to attend confirmed tokens without timely cancellation (“No-Shows”) may result in:
temporary booking restrictions;
reduced booking priority;
mandatory confirmation requirements; or
permanent suspension of the Patient account.
Any applicable cancellation charges or penalties, if introduced, shall be communicated in advance.
  
10. DATA USAGE & CONSENT

10.1 Consent to Collect and Process Data
By accessing or using the Platform, Users expressly consent to the collection, storage, processing, and use of their personal and sensitive personal data in accordance with these Terms and the Privacy Policy.
Consent is obtained electronically and shall be deemed valid unless expressly withdrawn by the User as per applicable law.
 
10.2 Medical Data Handling
medical information shared by Users, including symptoms, consultation details, prescriptions, and reports, shall be treated as sensitive personal data.
Such data is collected solely for facilitating healthcare services, appointment management, and related Platform functionalities.
The Platform does not independently verify or alter medical data and acts only as a secure digital facilitator.
 
10.3 Sharing Data with Providers
User data shall be shared with the relevant Provider (Doctor, Clinic, Hospital, or Lab) strictly on a need-to-know basis to enable consultation, diagnosis, treatment, or service delivery.
Providers are independently responsible for maintaining confidentiality and complying with applicable medical and data protection laws.
 
10.4 Sharing Data with Third Parties (Future Services)
The Platform may, with explicit consent, share limited data with third-party service providers such as diagnostic laboratories, pharmacies, insurance partners, or payment processors.
Such sharing shall be governed by contractual data protection obligations and applicable laws.
No medical or sensitive personal data shall be shared for marketing or commercial purposes without explicit user consent.
 
10.5 Data Retention Period
User data shall be retained only for as long as necessary to fulfil the purposes outlined in these Terms, comply with legal obligations, or resolve disputes.
Medical records may be retained as required under applicable healthcare laws and regulations.
Upon account deletion, data shall be anonymized or deleted, subject to legal retention requirements.
 
10.6 Right to Revoke Consent
Users may withdraw consent for data processing by submitting a written request through designated Platform channels.
Withdrawal of consent may limit or terminate access to certain Platform features.
Data already processed prior to withdrawal shall remain lawful.
 
11. COMMUNICATION & NOTIFICATIONS
 
11.1 Consent for Communications
Users consent to receive communications via SMS, WhatsApp, email, or in-app notifications upon registration.
Such communications are essential for Platform functionality.
 
11.2 Transactional vs Promotional Communication
Transactional communications include booking confirmations, token updates, reminders, cancellations, and system alerts.
Promotional communications, if any, shall be sent only in accordance with applicable consent laws.

11.3 Opt-Out Rules
Users may opt out of promotional communications at any time.
Transactional and system-generated communications cannot be opted out of while using the Platform.
 
11.4 System-Generated Notifications
The Platform may automatically send notifications based on real-time queue movement, delays, or Provider actions.
The Platform does not guarantee delivery of notifications due to telecom or third-party service limitations.
 
12. INTELLECTUAL PROPERTY
 
12.1 Platform Ownership
All intellectual property rights in the Platform, including software, design, workflows, and content, belong exclusively to the Platform owner.
 
12.2 Trademarks & Logos
All trademarks, logos, and brand identifiers displayed on the Platform are protected and may not be used without prior written permission.
 
12.3 Content Usage Rights
Users and Providers are granted a limited, non-exclusive, non-transferable right to use the Platform solely for intended purposes.
 
12.4 Restrictions on Copying or Reuse
No part of the Platform may be copied, modified, reverse-engineered, or commercially exploited without authorization.
  
13. THIRD-PARTY SERVICES

13.1 Integrated Third-Party Services
The Platform integrates third-party services including payment gateways, messaging providers, analytics tools, and mapping services.
 
13.2 Independent Operation
Third-party services operate independently and are governed by their respective terms and policies.
 
13.3 Disclaimer of Third-Party Failures
Bloomevera Solutions LLP shall not be liable for delays, failures, or errors caused by third-party service providers, including payment gateways, messaging services, or infrastructure partners.
Any disputes with third parties shall be resolved directly with such providers.
  
14. LIMITATION OF LIABILITY

14.1 Platform Liability Limits
The liability of Bloomevera Solutions LLP, if any, shall be limited to the fees actually paid by the User to the Platform for the relevant transaction.

14.2 Exclusion of Indirect Damages
The Platform shall not be liable for indirect, incidental, consequential, or punitive damages, including loss of profits or data.

14.3 Force Majeure
The Platform shall not be liable for failure or delay caused by events beyond reasonable control, including natural disasters, government actions, or system outages.

14.4 Service Interruptions
Temporary interruptions for maintenance, upgrades, or technical issues shall not constitute breach of service.
  
15. INDEMNITY

15.1 User Indemnification
Users agree to indemnify and hold harmless Bloomevera Solutions LLP, its partners, officers, employees, and affiliates against claims arising from misuse, false information, or violation of these Terms.
 
15.2 Provider Indemnification
Providers agree to indemnify the Platform against claims arising from medical negligence, inaccurate information, regulatory non-compliance, or service deficiencies. 
 
16. GOVERNING LAW & JURISDICTION

16.1 Applicable Law
These Terms shall be governed by and construed in accordance with the laws of India.

16.2 Jurisdiction
All disputes, claims, or legal proceedings arising out of or in connection with the use of the Platform, these Terms, or any related policies shall be subject to the exclusive jurisdiction of the competent courts at Akola-444001, Maharashtra, India.

16.3 Dispute Resolution
Disputes may be resolved through arbitration or courts, as specified, in accordance with Indian law
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
