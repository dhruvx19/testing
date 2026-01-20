import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';

/// A simplified copy of the OTP screen's header/appbar area for the "terms and conditions" page.
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
                      style:  EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                        color: Colors.white,
               
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Right-side placeholder to balance the left IconButton width.
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
                                  'Upchaar-Q Terms and conditions',
                                  style: EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
                            
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff424242),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Read Carefully',
                                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                          
                                    fontWeight: FontWeight.w400,
                                  ).copyWith(color: Color(0xff424242)),
                                ),
                              ],
                            ),
                          ),

                          // Right: small circular illustration placeholder
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

                      // Body content placeholder
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '1. General',
                                      style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                                        
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Rubik',
                                        color: Color(0xff424242),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '''
We, at Upcharq (“Upcharq”, “we,” “us” ‘our” “Company”) having its registered office at Mumbai Pune Road, Akurdi, Pune – 411035, Maharashtra and corporate office at Trion IT Park, 4th, 5th and 6th floors, Pune - Ahmednagar Road, Pune 411014, Maharashtra provides services to you through our app [Bajaj Finserv Health] and our website [ https://www.bajajfinservhealth.in ] subject to the notices, terms, and conditions set forth in this agreement, read with the Privacy Policy available here.
These Terms of Use constitute the agreement (the “Agreement” or “Terms of Use” or “Terms and Conditions”) between BFHL and the user of BFHL’s services. Your use of BFHL’s services and various ancillary services accessible at www.bajajfinservhealth.in, for which a subscription amount may or may not be payable for usage (hereinafter individually referred to as the “Subscription Service”/ “Services” and collectively referred to as the “Subscription Services”) is subject to the following terms and conditions.
This Agreement is an electronic record in terms of Information Technology Act, 2000 and generated by a computer system and does not require any physical or digital signatures. This Agreement is published in accordance with the provisions of Rule 3 (1) of the Information Technology (Intermediaries Guidelines and Digital Media Ethics Code) Rules, 2021 that require publishing the rules and regulations, privacy policy and Terms of Use for access or usage of the Subscription Services.
2. WHO WE ARE
The domain name [www.bajajfinservhealth.in], an internet based portal / [Bajaj Finserv Health], a mobile application (collectively referred to as “BFHL Platform/s”), is / are owned and operated by BFHL, a company duly incorporated under the provisions of the Companies Act, 2013.
BFHL is the owner/licensor of the software “Bajaj Finserv Health”, and all their variants, editions, add-ons, and ancillary Subscription Services or Services, BFHL Platforms, including all files and images contained in or generated by the software, and accompanying data (“Software”). The Software have been designed for use by individual customers and healthcare service providers, which term shall also include designated associates of the healthcare service providers who would use Software. All users of the Software are together termed as (“Users” or “you” or “your”).
Any accessing or browsing of the BFHL Platforms and using the Services indicates your consent and agreement to all the terms and conditions in this Agreement. If you disagree with any part of the Terms and Conditions, then you should discontinue access or use of the BFHL Platforms.
We may from time to time update, modify or revise these Terms and Conditions. Every time you wish to use the BFHL Platforms, please check the relevant Terms and Conditions to ensure you understand the terms, including the modified terms, if any, that apply at that time.
Your continued use of the Subscription Services after modification conveys your acceptance and consent to follow and be bound by the Terms of Use as modified. Any additional terms and conditions, disclaimers, privacy policies and other policies applicable to general and specific areas of the Subscription Services or to particular Subscription Services are also considered as Terms of Use.
Any person may have limited access to the BFHL Platforms without creating an account. In order to have access to all the features and benefits on BFHL Platforms, you must first create an account on BFHL Platforms, for which you are required to provide certain information, which is required to identify you. Other information requested on the registration page, including the ability to receive promotional offers
from BFHL, is optional. BFHL may, in future, add other optional requests for information to help us to customize the Services and to deliver personalized products and services to you.
If you have any grievances regarding the Services, Terms of Use and Privacy Policy, or any other grievance pertaining to your use of the BFHL Platforms, you may contact-
Grievance Officer: Mr. Sachin Sharma
Address: 4,5,6, 401, 501, 601, Trion IT Park, Ahmednagar road, Pune, Maharashtra, 411014
Email address: grievances@bajajfinservhealth.in
Contact Number: 020-48562555
3. ELIGIBILITY
When you use the BFHL Platforms, you represent that you meet the following primary eligibility criteria:
a. You have attained majority in your jurisdiction (at least 18 years old in the case of India). If you are under the relevant age of majority in your jurisdiction, you may access the BFHL Platforms under the supervision of a parent or guardian, who in such a case will be deemed as the recipient / end-user of the Services for the purpose of these Terms and Conditions.
b. You are legally competent to contract, and otherwise competent to use the Software and/or receive the Subscription Services.
c. You have not been previously suspended or removed by BFHL, or disqualified for any other reason, from availing the Services.
The Services are not intended for use by minors. BFHL strongly encourages parents and guardians to consider using parental control tools to help provide a child-friendly online environment and to supervise the online activities of their minor children.
4. YOUR USE OF BFHL PLATFORMS
As an end-user and/or recipient of Services, when you use the BFHL Platforms, you agree to the following conditions of use:
a. You shall provide accurate and complete information everywhere on the BFHL Platforms, based on which you will receive the Services. Any registration information given to BFHL by you is true, accurate, correct, complete and up to date, to the best of your knowledge and belief. Any phone number used to register with the Services is registered in your name, and you might be asked to provide supporting documents to prove the same. You own sole responsibility for any consequences arising out of any inconsistency or inaccuracy of any information or data provided by you. BFHL is not obliged to make any enquiries to check the veracity of the information provided by you.
b. You agree and acknowledge that you are a citizen of India, and hereby expressly waive the right to claim any remedy or benefits from, or enforce any rights against BFHL, under Health Insurance Portability and Accountability Act, 1996, any General Data Protection Regulation guidelines issued from time to time, and any other such foreign laws.
c. You may view and access the content available on the BFHL Platform solely for the purposes of availing the Services, and only as per these Terms of Use. You shall not modify any content on the BFHL Platforms or reproduce, display, publicly perform, distribute, or otherwise use such content in any way for any public or commercial purpose or for personal gain.
d. You agree to use the Software and Services only for specified purposes that are permitted as per (a) the Terms of Use and (b) any applicable law, regulation and generally accepted practices or guidelines in the relevant jurisdictions (including any laws regarding the export of data or software
to and from India or other relevant countries). You shall not use Software and/or Services for any competitive or benchmarking purposes or for any such purposes that are disruptive to the BFHL Platforms and/or its business.
e. You shall not reproduce, distribute, display, sell, lease, transmit, create derivative works from, translate, modify, reverse-engineer, disassemble, decompile or otherwise exploit the BFHL Platform or any portion of it unless expressly permitted by BFHL in writing. You shall not use any engine, software or any other mechanism for accessing, searching and /or navigating the BFHL Platform.
f. You shall be solely responsible for all access to and use of the BFHL Platforms by anyone using the password and identification originally assigned to you whether or not such access to and use of BFHL Platforms is actually authorized by you, including without limitation, all communications and transmissions and all obligations (including, without limitation, financial obligations) incurred through such access or use. You are solely responsible for protecting the security and confidentiality of the password and identification assigned to you.
g. You shall not engage in any activity that interferes with or disrupts or damages the Software (or the servers and networks which are connected to the Software). BFHL reserves the right to initiate appropriate legal action against you for breach or threatened breach of your obligations under this clause.
h. You shall not make any commercial use of any of the information provided on the BFHL Platform.
i. You shall not impersonate any person or entity, or falsely state or otherwise misrepresent your identity, age or affiliation with any person or entity. If any fraudulent booking/reimbursement is done to misuse the BFHL Platforms including but not limited to situations where such booking/reimbursement is done to generate personal revenue and/or for any other commercial purpose, then we shall have a right to terminate your Services and account, and delist you from the BFHL Platform.
j. You shall not upload any content prohibited under applicable law, and/or designated as “Prohibited Content” under Section 5.
k. You may discontinue the use of Services and request us to delete any information provided by you, by writing to us at customercare@bajajfinservhealth.in or calling us on 020-48562555. We might connect with you in case we need any further details in order to respond to your request.
l. You shall indemnify BFHL for any claims, losses or damages, or for the costs of any regulatory or court proceedings suffered by Company as a consequence of your breach of this Agreement.
m. You explicitly agree that you are solely responsible for maintaining the confidentiality of login credentials and passwords associated with any log-in you use to access the Software and/or Services and store your confidential, personal and sensitive information. In no event shall BFHL be liable if your login credentials are compromised thereby resulting in breach of your personal, sensitive and/or confidential information.
n. You agree and acknowledge that if the information provided in relation to Medical Records or any other information provided to BFHL by you, through the Software is not synced with the servers of BFHL, you may lose such information. Additionally, due to security concerns, you may not be able to access such Medical Records if they have been left unassessed for a certain period of time.
o. BFHL offers its Software and Services on as-is basis. BFHL has the sole right to modify any feature or customize them at its sole discretion and there shall be no obligation to make customization as requested by any User.
p. BFHL provides basic support for the Software and Services and will use, as far as possible, commercially reasonable efforts to make the Software and Services available 24 hours a day, 7 days a week, except for (i) technological errors, (ii) planned downtime, or (iii) any unavailability caused by circumstances beyond BFHL’s reasonable control, including without limitation, acts of God, acts of government, flood, fire, earthquakes, lockdown, civil unrest, acts of terror, strikes or other labour problems, or internet service provider failures or delays. BFHL takes no responsibility for any disruption, interruption or delay caused by any failure of or inadequacy in any of these limiting factors or any other factor beyond the control of the Company.
q. BFHL provides a free facility of ‘Health Vault’ on the Website and its mobile application ‘Bajaj Finserv Health App’. The Health Vault may include Medical Records and any other information provided by you through your use of the Software.
r. BFHL shall have the right, at its sole discretion, to suspend your ability to use or access the Software at any time while BFHL investigates complaints or alleged violations of this Agreement, or for any other reason.
s. BFHL reserves the right to add new functionality, remove existing functionality, and modify existing functionality to its Software as and when it deems fit, and make any such changes available in newer versions of its Software or mobile application or all of these at its discretion. You may or may not be notified upon release of such newer versions and BFHL reserves the right to automatically upgrade you to the latest version of its Software as and when it deems fit.
t. You acknowledge and specifically consent to BFHL or our respective affiliates, partners and third party service providers contacting you using the contact information provided to us at any time during your association with us for any purpose including but not limited to the following purposes, to enable BFHL to provide the Services to you and/or enhance the provision of the Services to you:
To obtain feedback regarding the Services;
To contact you for offering new products or services, whether offered by us, or our respective affiliates or partners.
u. You acknowledge and agree that we may share your information, including but not limited to sensitive personal information, with our affiliates, partners and third-party service providers solely for the provision of Services to you. Additionally, you may be sent a one-time password via SMS on your registered mobile number, to verify your login on the BFHL Platforms.
v. For any reimbursement process, you are required to visit the BFHL Platform to know about the updated reimbursement process. You are solely responsible for the accuracy/authenticity of the payment details provided by you, including but not limited to the bank account details and any other information requested during the process of reimbursement and/or others. Any personal data whether provided by you as a part of the reimbursement process or collected automatically when you use the service will be governed by our Privacy Policy. This data would also be used for rendering services to you at a future date. You confirm that you are the authorised user of such bank account details/ other payment details you share with us.
w. You can search for HSPs on the Software by providing details including but not limited to the name of HSP, geographical location of HSP and specialization of HSP. The search results for HSPs on the BFHL Platform must not be understood as an endorsement of any particular HSP by BFHL. These search results are based on particulars provided by you. When you choose to consult an HSP or obtain healthcare services from an HSP on BFHL Platform, you do so at your own risk and discretion.
x. BFHL may call you for the purpose of obtaining your feedback on the Software or for any other purpose. After taking your explicit consent, BFHL may also record and access such call recordings for quality control and training purposes. You agree and acknowledge that BFHL shall not be obliged to give effect to any suggestions made received from you in the form of feedback or review.
We reserve the right to refuse service or terminate accounts at our discretion, if we believe that you have violated or are likely to violate applicable law or these Terms and Conditions.
5. PROHIBITED CONTENT
You shall not upload host, display, modify, transmit, update or share any information or distribute, or otherwise publish through the BFHL Platforms, the following Prohibited Content, which includes any content, information, or any other material that:
a. belongs to another person and which you do not own the rights to;
b. is harmful, harassing, blasphemous defamatory, obscene, pornographic, pedophilic, invasive of another’s privacy;
c. is hateful, racially or ethnically objectionable, disparaging of any person;
d. relates to or seems to encourage money laundering or gambling;
e. harm minors in any way;
f. infringes any patent, trademark, copyright or other proprietary rights;
g. violates any law in India for the time being in force;
h. deceives or misleads the addressee about the origin of your message;
i. communicates any information which is grossly offensive or menacing in nature;
j. impersonates another person;
k. contains software viruses any other computer code, files or programs designed to interrupt, destroy or limit the functionality of any computer resource and malicious programs;
l. threatens the unity, integrity, defence, security or sovereignty of India, friendly relations with foreign states, or public order;
m. incites any offence or prevents investigation of any offence or insults any other nation;
n. circumventing or disabling any digital rights management, usage rules, or other security features of the Software;
o. copying or duplicating in any manner any of the BFHL content or other information available from the Software;
p. is patently false and untrue, and is written or published in any form, with the intent to mislead or harass a person, entity or agency for financial gain or to cause any injury to any person.
You also understand and acknowledge that if you fail to adhere to the above, we have the right to remove such information and/or immediately terminate your access to the Services and / or to the BFHL Platforms. We shall also preserve such Prohibited Content for such period as may be required under applicable law for investigation purposes.
6. CALL CLINIC AND BOOK APPOINTMENT FACILITY
a. BFHL Platform may provide the facility to book appointment with HSPs through-
i. Book Appointment facility
ii. Call Clinic facility,
b. We specifically disclaim all liability arising from cancellation of appointment by the HSP post confirmation.
c. For the purposes of appointment and booking, Call Clinic facility option shall be displayed alongside HSPs listed on the BFHL Platform. By selecting Call Clinic facility option, you opt to call such HSP for the purposes of booking and appointment. This call shall have an interactive voice response message asking for your consent to record such call and shall also state the purpose for recording such call.
d. By using the Call Clinic facility, you grant BFHL the right to share and store your conversation and any other information provided by you to the HSP in pursuance of the Call Clinic Facility. You agree and acknowledge that BFHL shall have the right to record and store these calls on the servers used by BFHL. Your call recording shall be stored and used by BFHL in accordance with the Privacy Policy. BFHL may access such records for quality control and support reasons.
e. We strongly assert that you utilize the Call Clinic facility option for the purpose of booking appointment only. BFHL specifically disclaims all liability if Call Clinic facility is used for any purpose other than appointment and booking.
f. In the event you refuse to consent to the recording of calls that may contain your personal information, BFHL shall have the right to restrict or deny the provision of Services for which such personal information was requested/ deemed necessary by BFHL.
g. BFHL has the right to elect not to provide Call Clinic facility option.
7. MEDICAL RECORDS AND REMINDERS
a. We provide you the facility to access your (and/or any beneficiary listed through your account on the BFHL Platforms) medical prescriptions, appointment history, medical history and any other such health records (“Medical Records”) on the BFHL Platforms. Medical Records are stored only after your explicit consent to this Agreement is obtained by BFHL. Medical Records will be stored in the Health Vault facility on the Software.
b. As a part of the Medical Records facility, we may also give you reminders, including but not limited to reminders for HSP appointments and taking prescribed medicines. However, you must conduct your own due diligence and refer to Medical Records before acting on these reminders. In no event shall BFHL be liable for any direct, indirect, special, incidental, consequential, exemplary or punitive damages arising from, or directly or indirectly related to, the use of or the inability to use, such reminders by you.
c. You agree and acknowledge that BFHL shall not be responsible or liable in any way, for any medical deduction/opinion or consultation or any other information contained in your/your beneficiary’s Medical Records. Medical Records and any such information provided to us by the respective HSP contacted by you through BFHL Platforms, are exclusively the responsibility of the respective HSP.
d. If Medical Records are found to have been provided improperly or accidentally, BFHL has the right to retract them without warning, at its sole discretion.
e. You agree and acknowledge that BFHL may access the Medical Records for purposes such as data repair/recovery and/or similar/associated purposes in case of any information technology breach or any technological failure.
f. You agree and acknowledge that the HSPs you are visiting through the Software may use- (i) BFHL’s Software or any third party software for providing their services and (ii) BFHL’s Services for purposes including but not limited to the use and storage of Medical Records in accordance with applicable law.
g. You also agree to the storage of your/your beneficiary’s Medical Records in relation to BFHL listed HSPs that you may have visited in the past for the purpose of doctor consultation.
h. You may discontinue the use of the Medical Records facility and request us to delete any information provided by you, by writing to us at customercare@bajajfinservhealth.in or calling us on 020- 48562555. We might connect with you in case we need any further details in order to respond to your request.
i. We shall not be liable if Medical Records are not provided to you or are delivered late, despite our best efforts.
j. Medical Records are provided along with the HSPs’ contact numbers. BFHL shall not be liable for providing inaccurate contact numbers in the Medical Records given by HSPs.
k. We have the right to withdraw Medical Records without giving prior notification if such Medical Records are discovered/deemed to have been disclosed improperly or accidentally.
l. You accept and recognise that BFHL may need access to Medical Records under certain circumstances, such as when you have technical or operational issues with access to Medical Records or any ownership related issue pertaining to the Medical Records.
8. LIMITATION OF LIABILITY
By using our Services, you confirm that you understand and agree to the following:
a. The services availed by you from a healthcare service provider (“HSP”) (which inter alia include doctors/ hospitals/ diagnostic laboratories) via BFHL Platform are provided to you by the HSP you select, and not by BFHL.
b. BFHL makes no express or implied representations or warranties about its Software or Services and disclaims any implied warranties, including, but not limited to, warranties or implied warranties of merchantability or fitness/quality for a particular purpose or use or non-infringement. Company does not authorize anyone to make a warranty on behalf of BFHL.
c. BFHL only facilitates communications between you and the HSP and bears no responsibility for the quality and outcome of any services obtained by you from the respective HSP.
d. BFHL may or has entered into Agreement with various HSPs engaged in the healthcare services on principal to principal basis without any fiduciary relationship and shall not be directly or indirectly responsible for any act or omission of such HSPs. Users are requested to make independent enquiries and assessments and rely on professional advice independently obtained before availing any service from any HSP.
e. BFHL does not provide any medical or diagnostic services. If you receive any medical advice from an HSP you have contacted through BFHL Platform, you are responsible for assessing such advice, the consequences of acting on such advice, and all post-consultation follow-up action, including following HSPs instructions.
f. In no event, BFHL or its affiliates shall be liable to you for any inappropriate behavior, misconduct or any type of inconvenience caused by the HSP or its personnel.
g. In the event that BFHL markets or promotes any services to you, please note that such services will be provided by the relevant HSP, and you are responsible for undertaking an independent assessment regarding the suitability of such services and such HSPs for your purposes. Marketing or promotion of services should be considered as being for informational purposes only and shall not constitute expert advice on the suitability of such services for your specific healthcare needs.
h. In no event, BFHL or its affiliates shall be liable to you for any special, indirect, incidental, consequential, punitive, reliance, or exemplary damages arising out of or relating to: (i) these Terms and Conditions and Privacy Policy; (ii) your use or inability to use the BFHL Platforms; (iii) your use of any third party services including services provided by any HSP you contacted through BFHL Platforms.
i. BFHL does not control or endorse the content, messages or information found in any services provided by HSPs and merely acts as an aggregator/facilitator. Therefore, we specifically disclaim any liability with regard to the products and services offered by HSPs and any actions resulting from your participation in such products and services, and you agree that you waive any claims against BFHL relating to same, and to the extent such waiver may be ineffective, you agree to release any claims against BFHL relating to the same.
j. BFHL expressly disclaims any liability arising out of the third party advertisements, solicitations of their respective product and services (through dedicated hyperlink) on the BFHL Platform.
BFHL takes no responsibility for advertisements or any third-party material posted on the BFHL Platform nor does it take any responsibility for the products or services provided by advertiser/seller/solicitor. Any dealings you have with advertisers found while using the Services are between you and the advertiser, and you agree that BFHL is not liable for any loss or claim that you may have against such advertiser/seller/solicitor.
k. BFHL expressly disclaims responsibility for abandoned, incorrect, fraudulent, or non-existent HSP profiles published on the BFHL Platforms.
l. BFHL assumes no responsibility, and shall not be liable for viruses that may infect your equipment or any other damages to your equipment on account of your access to, use of, or downloading of any content from the Software. You agree and acknowledge that if you are dissatisfied with the Software, your only remedy is to discontinue using the Software. In no event, including but not limited 
9. INDEMNITY
You agree to indemnify and hold harmless BFHL, its affiliates, group companies, associates, subsidiaries, holding company of BFHL, associates and subsidiaries of holding company of BFHL officers, directors, employees, consultants, licensors, agents, and representatives from any and all claims, losses, liability, damages, and/or costs (including, but not limited to, reasonable attorney fees and costs) arising from or related to (a) your use of the Subscription Services; (b) your violation of these Terms of Use or any applicable law(s); (c) your violation of any rights of another person/ entity, including infringement of their intellectual property rights; or (d) your conduct in connection with the Software.
10. DATA & INFORMATION POLICY
We respect your right to privacy in respect of any personal and sensitive information provided to us. To see how we collect and use your personal and sensitive information, please see our Privacy Policy. The Privacy Policy is by necessary implication, part of this Terms and Conditions and the clauses therein are not repeated here for the sake of brevity.
Terms and Conditions
Before you proceed, we require your consent for sharing your data with the insurance company. Please review the following terms and conditions carefully:
a. Purpose of Data Sharing: By providing your consent, you acknowledge and agree that your data will be shared with your insurance company to facilitate insurance-related services, including but not limited to policy management, claims processing, underwriting and additional reduction in renewal premiums on policy anniversary to be provided if any by the insurer.
b. Types of Data: The data shared with the insurance company may include, but is not limited to, personal information (name, address, contact details), policy information, claims history, medical records, health data, daily activity data and other data necessary for the provision of insurance services and aid in better management of your health condition.
c. Data Confidentiality and Security: We understand the importance of data confidentiality and take appropriate measures to protect your personal information in accordance with applicable data protection laws and regulations.
d. Data Retention Period: Your data will be retained for as long as required by the insurance company for fulfilling the purpose for which it was collected, subject to applicable laws and regulations.
e. Consent Revocation: You have the right to withdraw your consent at any time. If you choose to withdraw your consent, it may impact the availability or provision of certain insurance services to you. To withdraw your consent, please contact our customer support.
By clicking I Agree or by using our mobile application after reviewing this consent letter, you confirm that you have read and understood the terms and conditions outlined above. You also agree to the collection, use, and sharing of your data as described in this consent letter.
If you do not agree with these terms and conditions, please do not proceed with using our Health Management Service.
Please note that this legal consent may be subject to updates and revisions, and it is your responsibility to review any changes that may occur.
If you have any questions or concerns regarding the data sharing process, please contact our customer support for further assistance.
11. INTELLECTUAL PROPERTY AND OWNERSHIP
You recognize and agree that all copyright, registered trademarks, all contents of the mobile application/website including but not limited to the look and feel, layout, design, text, graphics and arrangement and other intellectual property rights on all materials or contents provided as part of the Software (“Intellectual Property”) belong to us at all times or to those who grant us the license for their use.
No use of the Intellectual Property of the Company or third party, which Company has a right to use may be made for any commercial/non-commercial purpose without the prior written authorization of BFHL.
12. OTHER CONDITIONS
12.1. Pricing and Payment
a. Price for usage rights of the Software shall be as decided by the Company from time to time. Payment must be made in advance or as agreed with the Company.
b. BFHL may add new Software for additional fees and charges or may proactively amend fees and charges for existing Software, at any time in its sole discretion.
c. You agree that the billing credentials provided by you for any purchases from BFHL will be accurate and you shall not use billing credentials that are not lawfully owned by you.
d. You agree to pay all fees and other charges along with applicable taxes towards Software or Services or any other services on the BFHL Platforms. The fees payable may be dependent on the plan that you decided to purchase and on any additional usage beyond limitations of plans. Fees once paid is non-refundable.
e. The payment process would be considered to be complete only on receipt of the fees into BFHL’s designated bank account.
f. Fees shall be payable on due date without any responsibility on BFHL to send reminders for any fees due and payable. Fees not received within the specified due dates shall attract late charges of 18% per annum from the due-date of payment, and any such charges that may be levied at BFHL’s sole discretion.
g. BFHL reserves the right to modify the fees structure by providing 30 (thirty) days prior notice.
h. In order to process fee payments, BFHL might require details of your bank account, credit card number and other such financial information. Please see Privacy Policy of BFHL on how company handles financial information.
i. You can cancel your access to the Software by contacting us by email or any other mode of communication with the Company. One-time set-up fees, if any, charged by the Company shall not be refunded.
j. The subscription fees is non-transferable and the payment made to the Company for a particular software or service cannot be transferred or carried over to another software or service.
12.2. Accuracy of Information Displayed
We have made every effort to display, as accurately as possible, the information provided by the relevant third parties, including HSPs. HSP information includes but is not limited to information about the qualification, experience, fee charged, geographical location and available time slots for booking appointment with such HSP.
We also update such information at regular time periods. However, we do not undertake any liability in respect of such information and or with respect to any other information regarding which you are capable of conducting your own due diligence to ascertain accuracy.
Company does not undertake any liability in respect of any information with respect to which you are capable of conducting your own due diligence to ascertain accuracy.
12.3 Cancellation Terms
a. You can cancel a confirmed appointment any time before your appointment time.
b. If you have booked a pre-paid appointment, the refund is issued immediately. However, deposit of such amount to you shall take 2-3 working days.
c. We do not charge any cancellation fee or other penalty.
d. You can cancel your confirmed appointment through either of the BFHL Platforms or by contacting the customer support of BFHL Platforms.
e. These cancellation terms are to be read with the product specific cancellation terms. In case of any conflict between the product specific cancellation terms and these cancellation terms, the product specific cancellation terms will prevail.
12.4 Reimbursement Terms
a. You agree and acknowledge that for claiming reimbursement on the BFHL Platform, you shall be required to submit the following documents (“Reimbursement Documents”)-
i. In case of medical consultation- Prescription and invoice of such consultation;
ii. In case of lab, radiology, pathology or any other type of test- Invoice and report of such test; and
iii. Any other documentation (apart from the ones specified above) that may be required by BFHL.
b. You agree and acknowledge that the reimbursement mechanism on the BFHL Platform is subject to change at the sole discretion of BFHL.
c. You agree and acknowledge that BFHL shall retain the Reimbursement Documents provided by you for compliance with applicable law.
d. You agree not to submit the same claim for coverage/benefits under more than one wellness product/plan issued by us.
e. You hereby agree and acknowledge that to the best of your knowledge and understanding, the information and documents provided by you for claiming reimbursement are accurate and complete. You understand that providing false or misleading information or documents shall be deemed to constitute misrepresentation and may result in the denial of your claim and/or legal action.
f. BFHL reserves the right to investigate any potential duplication of claims.
g. You agree and acknowledge that BFHL may share your Reimbursement Documents with our respective affiliates, partners and third-party service providers (including healthcare service providers not listed on BFHL Platform) for verification of claims and investigation of fraud.
h. BFHL may take appropriate actions, including but not limited to denying coverage, reducing benefits, or terminating your product/plan, if we determine that a claim has been submitted for coverage under multiple product/plans.
i. BFHL reserves the right to investigate any potential duplication of claims.
12.5 Network Disclaimer
a. The Fees and Timings are tentative and may subject to change at the time of confirmation.
b. Registration fee charged by Clinic or Hospital are not covered under OPD and has to be borne by the insured.
c. It is mandatory to upload the prescription after the completion of appointments or no show charges will be applicable in case it is not uploaded after consultation.
d. If you prefer not to see the doctor, it's important to cancel the appointment before the cashless letter is generated, that is 2 hours prior to the appointment. Failure to do so may result in applicable no-show charges
13. THIRD PARTY LINKS AND RESOURCES
Where 
BFHL lists HSP information on its Software and Services as per the information provided by respective HSP. The information listed is displayed when you search for any HSP on the BFHL Software, and this information listed on the Software may be used by you to request for appointments. Such information on the Software may continue to appear even after the HSP in any way discontinues its relationship with BFHL. The list of HSPs displayed to you is prepared by a fully automated mechanism used by BFHL. This list of HSPs is based on various parameters including ranking algorithm and the feedback received from the Users. BFHL merely lists them for information purposes; you are advised to undertake your own due diligence regarding such HSPs. BFHL reserves the right to list HSPs who are not party to this Agreement and the HSPs who have subscribed to this Terms of Use are listed along with them. Company reserves the right to modify the listing of HSP on its Software.
BFHL disclaims any responsibility and shall not be liable for ways in which your data is used by HSPs and other authorized users of Software. It is the responsibility of the respective HSP alone with whom your data has been shared with your consent, to ensure that your data is used in compliance to applicable data privacy laws and as per your mandate. The Software of BFHL may be linked to the services of third parties, affiliates and business partners. BFHL has no control over, and shall not be liable or responsible for content, accuracy, validity, reliability, quality of such third party services. Inclusion of any link on the Software should not be deemed to imply that BFHL endorses the linked site. You may use the links and the third party services at your own risk, choice and preference.
14. HEALTH COIN FEATURE
a. BFHL may also provide a ‘Health Coins’ feature on the Software. Health Coins are a form of credits granted to Users for availing discount benefits in the following utilization modes:
a. Through in-app activities including but not limited to sign-up, profile completion, completion of health risk assessment and such other activities that BFHL may prescribe from time to time.
2. Through referrals.
3. Through offers on Bajaj group products.
4. As loyalty rewards on medicine purchases.
These earning modes are, however, subject to change based on the sole discretion of BFHL. By continuing to use the Software, you consent to such changes in the earning modes.
b. You may use Health Coins to avail discounts as per the utilization modes for Health Coins. Only such percentage of the total amount to be paid, as may be prescribed by BFHL from time to time, may be availed by you as discounts. You agree and acknowledge that Health Coins cannot be converted to actual money, and neither can they be transferred to bank accounts.
c. Health Coins shall have an expiry date associated with them. However, in any case, the Health Coins shall not be valid for perpetuity. The validity period of Health Coins shall be subject to change based on the sole discretion of BFHL. You may or may not be informed through SMS or e-mail or notification on BFHL Platforms about the expiration of their validity period.
d. You agree and acknowledge that BFHL has the right to withdraw the Health Coins feature before the end of its validity period as per the sole discretion of BFHL. You also agree and acknowledge that BFHL has the right to deny any utilization of Health Coins to any User, as per the sole discretion of BFHL.
e. Additionally, you agree and acknowledge that this section may be restricted by the terms governing the relationship between BFHL and the entity (“Partner Terms”), which has entitled you to Health Coins. In case of any conflict between Partners Terms and this section, the Partner Terms shall prevail.
15. EVENTS BEYOND OUR CONTROL
We shall not be liable for any non-compliance or delay in compliance with any of the obligations we assume under any contract when caused by events that are beyond our reasonable control (“Force Majeure”). Force Majeure shall include any act, event, failure to exercise, omission or accident that is beyond our reasonable control, including, among others, the following:
c. Fire, explosion, storm, flood, earthquake, collapse, epidemic or any other natural disaster.
d. Inability to use public or private transportation and telecommunication systems.
e. Acts, decrees, legislation, regulations or restrictions of any government or public authority including any judicial determination.
Our obligations deriving from any contracts should be considered suspended during the period in which Force Majeure remains in effect and we will be given an extension of the time period for fulfilling these obligations by an amount of time we shall communicate to you, not being less than the time that the situation of Force Majeure lasted.
For change in law specifically, we reserve our rights to suspend our obligations under any contract indefinitely, and / or provide Services under revised Terms and Conditions.
16. APPLICABLE LEGISLATION AND JURISDICTION
The use of Software and the product purchase contracts through BFHL Platforms shall be governed by the laws applicable in India. Any dispute relating to the use of our Software shall be subject to the exclusive jurisdiction of the Indian Courts at Pune, Maharashtra.
17. TERM, TERMINATION & DISPUTES
17.1 This Agreement shall remain in full force and effect for using any of the Services or Software in any form or capacity.
17.2 You can request for termination of your relationship with BFHL at any time by providing 30 (thirty) days’ prior written notice to BFHL. During this 30 (thirty)-day period, BFHL will investigate and ascertain the fulfilment of any ongoing Services or pending dues related to Software or any other fees payable by you. The User shall be obligated to clear any dues with BFHL for any of its Software or Services which you have procured. BFHL shall not be liable to you or any third party for any termination of your access to the Software and/or the Services.
17.3 BFHL reserves the right to terminate any account in cases:
(a) You breach any terms and conditions of this Agreement or Privacy Policy;
(b) BFHL believes in its sole discretion that your actions may cause legal liability for the Company or are contrary to the interests of the Company.
17.4. Once temporarily suspended, indefinitely suspended or terminated, you may not continue to use the Software under the same account, a different account or re-register under a new account, unless explicitly permitted by BFHL. On termination of an account due to the reasons mentioned herein, you shall no longer have access to data, messages, files and other content kept on the Software. You shall ensure that you maintain continuous backup of any content, data or information provided by you on the Software, in order to comply with your record keeping process and practices.
17.5 Return of User’s Data: Upon request by you and upon termination of Software and Services due to non-payment/others, BFHL will promptly make available to you for downloading your data in such mode and manner as the Company may decide. Upon return of the data and/or lapse of 30(thirty) days from termination of Software and Services, BFHL shall have no obligation to maintain or provide a copy of such data and shall thereafter, unless legally prohibited and to the extent required to be maintained under the applicable law, delete all your data in its systems or otherwise in its possession or under its control. In cases where you terminate the subscription voluntarily, it will be your sole responsibility to make a copy of your data before terminating the subscription.
17.6 Even after termination, certain obligations as mentioned herein above or evident from their very nature to have been intended to survive will continue and survive termination.
17.7 Even after termination, the Agreement shall continue to be applicable for any cause of action that has arisen directly or indirectly on account of your usage of the Software or the Services provided by the Company.
Last Updated: 13-12-2023''',
                                style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                           
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
