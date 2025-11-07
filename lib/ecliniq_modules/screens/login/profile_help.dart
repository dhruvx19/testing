
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';

/// Login trouble page header + terms heading.
class ProfileHelpPage extends StatelessWidget {
	const ProfileHelpPage({super.key});

	@override
	Widget build(BuildContext context) {
		return EcliniqScaffold(
			backgroundColor: EcliniqScaffold.primaryBlue,
			body: SizedBox.expand(
				child: Column(
					children: [
						const SizedBox(height: 40),
						Row(
							children: [
								IconButton(
									onPressed: () => Navigator.of(context).maybePop(),
									icon: const Icon(
										Icons.close,
										color: Colors.white,
										size: 24,
									),
								),

								

								const SizedBox(width: 48),
							],
						),

						const SizedBox(height: 10),

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
																	'Need help for Profile Details?',
																	style: const TextStyle(
																		fontSize: 24,
																		fontWeight: FontWeight.w500,
																	),
																),
																const SizedBox(height: 5),
																Text(
																	'Try the following',
																	style: TextStyle(
																		fontSize: 16,
																		fontWeight: FontWeight.w400,
																	).copyWith(color: Colors.grey.shade600),
																),
															],
														),
													),
												],
											),


																						const SizedBox(height: 18),
																						Row(
																							children: [
																								Container(
																									width: 32,
																									height: 32,
																									decoration: BoxDecoration(
																										color: Colors.blue.shade50,
																										shape: BoxShape.circle,
																									),
																									child: Image.asset("lib/ecliniq_icons/assets/Vector_Question.png"),
																								),
                                                ],
																						),
                                            const SizedBox(height: 6),
                                   Column(
														 crossAxisAlignment: CrossAxisAlignment.start,
															children: [
															Text(
																	'Trouble inputting Profile Info ? ',
																	style: TextStyle(
																		fontWeight: FontWeight.w500,
  																		fontSize: 18,
																											color: Colors.grey.shade900,
																											fontFamily: 'Inter',
																										),
																									),
																                const SizedBox(height: 5),
																                   Text(
																										'Go to our help centre to know step - by - step guide for Profile Details Process.',
																										style: TextStyle(
																											fontWeight: FontWeight.w400,
																											fontSize: 14,
																											color: Colors.grey.shade600,
																											fontFamily: 'Inter',
																										),
																									),
														],													),
                                                        const SizedBox(height: 10),
                                                        Align(
																													alignment: Alignment.centerLeft,
																													child: ElevatedButton.icon(
																													  onPressed: () {},
																													  icon: const SizedBox.shrink(),
																													  label: Row(
																														mainAxisSize: MainAxisSize.min,
																														children: const [
																														  Text('Go to Help Centre', style: TextStyle(
																																fontWeight: FontWeight.w500,
																																fontSize: 14,
																																color: Colors.blue,
																																fontFamily: 'Inter',
																															),),
																														  SizedBox(width: 8),
																														  Icon(Icons.arrow_forward, size: 18, color: Colors.blue,),
																														],
																													  ),
																																											style: ElevatedButton.styleFrom(
																																											backgroundColor: Colors.blue.shade50,
																																												foregroundColor: Colors.blue.shade100,
																																												padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
																																												shape: RoundedRectangleBorder(
																																													borderRadius: BorderRadius.circular(8),
																																													side: BorderSide(color: Colors.blue, width: 0.5),
																																												),
																																											),
																													),
																												  ),
                                                          
                                                          const SizedBox(height: 18),
                                                          const Divider(thickness: 1,),
                                                          const SizedBox(height: 26),
																						Row(
																							children: [
																								Container(
																									width: 32,
																									height: 32,
																									decoration: BoxDecoration(
																										color: Colors.blue.shade50,
																										shape: BoxShape.circle,
																									),
																									child: Image.asset("lib/ecliniq_icons/assets/Vector_chat.png"),
																								),
                                                ],
																						),
                                            const SizedBox(height: 6),
                                   Column(
														 crossAxisAlignment: CrossAxisAlignment.start,
															children: [
															Text(
																	'Can’t able to add profile details?',
																	style: TextStyle(
																		fontWeight: FontWeight.w500,
  																		fontSize: 18,
																											color: Colors.grey.shade900,
																											fontFamily: 'Inter',
																										),
																									),
																                const SizedBox(height: 5),
																                   Text(
																										'Get instant answers to your queries from our support team',
																										style: TextStyle(
																											fontWeight: FontWeight.w400,
																											fontSize: 14,
																											color: Colors.grey.shade600,
																											fontFamily: 'Inter',
																										),
																									),
														],													),
                                                        const SizedBox(height: 10),
                                                        Align(
																													alignment: Alignment.centerLeft,
																													child: ElevatedButton.icon(
																													  onPressed: () {},
																													  icon: const SizedBox.shrink(),
																													  label: Row(
																														mainAxisSize: MainAxisSize.min,
																														children: const [
																														  Text('Contact Customer Support', style: TextStyle(
																																fontWeight: FontWeight.w500,
																																fontSize: 14,
																																color: Colors.blue,
																																fontFamily: 'Inter',
																															),),
																														  SizedBox(width: 8),
																														  Icon(Icons.arrow_forward, size: 18, color: Colors.blue,),
																														],
																													  ),
																																											style: ElevatedButton.styleFrom(
																																												backgroundColor: Colors.blue.shade50,
																																												foregroundColor: Colors.blue.shade100,
																																												padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
																																												shape: RoundedRectangleBorder(
																																													borderRadius: BorderRadius.circular(8),
																																													side: BorderSide(color: Colors.blue, width: 0.5),
																																												),
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

