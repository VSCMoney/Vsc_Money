// import 'package:flutter/material.dart';
// import 'package:vscmoney/constants/colors.dart';
// import 'package:flutter_svg/flutter_svg.dart';
//
// class InvestmentPlanScreen extends StatelessWidget {
//   const InvestmentPlanScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           return Padding(
//             padding: EdgeInsets.symmetric(horizontal: 10),
//             child: Column(
//               children: [
//                 const SizedBox(height: 30),
//                 Expanded(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 32),
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade200,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.2),
//                               blurRadius: 6,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             CircleAvatar(
//                               radius: 14,
//                               backgroundColor: Colors.brown.shade300,
//                               child: const Text(
//                                 'R',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             const Expanded(
//                               child: Text(
//                                 'Hey Penny! I don’t know how to split my money. Can you help?',
//                                 style: TextStyle(fontSize: 13.5),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 52),
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: AppColors.lightOrange,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             Image.asset(
//                               'assets/images/Group.png',
//                               height: 18,
//                               width: 18,
//                             ),
//                             const SizedBox(width: 8),
//                             const Text(
//                               'Here’s your investment plan',
//                               style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       Padding(
//                         padding: const EdgeInsets.only(left: 120),
//                         child: SvgPicture.asset(
//                           fit: BoxFit.contain,
//                           height: 250,
//                           'assets/images/Group 2.svg', // Use your actual .svg asset path
//                         ),
//                       ),
//                       const SizedBox(height: 50),
//                       const Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 24),
//                         child: Column(
//                           children: [
//                             Text(
//                               'Your AI-Powered\nInvestment Strategist',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.w500,
//                                 fontStyle: FontStyle.normal,
//                               ),
//                             ),
//                             SizedBox(height: 26),
//                             Text(
//                               'Chat with AI for real-time insights and tailored investment strategies.',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 14.5,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:vscmoney/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class InvestmentPlanScreen extends StatelessWidget {
  const InvestmentPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 90),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.brown.shade300,
                              child: const Text(
                                'R',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Hey Penny! I don’t know how to split my money. Can you help?',
                                style: TextStyle(fontSize: 13.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 52),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Image.asset(
                              'assets/images/onboard.png',
                              height: 18,
                              width: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Here’s your investment plan',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 120),
                        child: SvgPicture.asset(
                          'assets/images/Group 2.svg',
                          fit: BoxFit.contain,
                          height: 250,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              'Your AI-Powered\nInvestment Strategist',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 26),
                            Text(
                              'Chat with AI for real-time insights and tailored investment strategies.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40), // for padding at the bottom
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
