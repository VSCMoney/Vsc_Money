// import 'package:flutter/material.dart';
//
// class Goal {
//   final String date;
//   final String year;
//   final String label;
//   final double progress;
//   final String amount;
//   final Color color;
//
//   Goal({
//     required this.date,
//     required this.year,
//     required this.label,
//     required this.progress,
//     required this.amount,
//     required this.color,
//   });
// }
//
// class GoalsPage extends StatelessWidget {
//   final List<Goal> goals = [
//     Goal(
//       date: 'Mar',
//       year: '2027',
//       label: 'Car',
//       progress: 0.42,
//       amount: '50K',
//       color: Colors.blue,
//     ),
//     Goal(
//       date: 'Mar',
//       year: '2027',
//       label: 'Education Loan',
//       progress: 0.25,
//       amount: '5L',
//       color: Colors.lightBlue,
//     ),
//     Goal(
//       date: 'Apr',
//       year: '2035',
//       label: 'Emergency Fund',
//       progress: 0.12,
//       amount: '10L',
//       color: Colors.green,
//     ),
//     Goal(
//       date: 'Mar',
//       year: '2037',
//       label: 'Ghar',
//       progress: 0.08,
//       amount: '1Cr',
//       color: Colors.purple,
//     ),
//     Goal(
//       date: 'Dec',
//       year: '2040',
//       label: 'Son’s Education',
//       progress: 0.08,
//       amount: '1Cr',
//       color: Colors.teal,
//     ),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         shape: const CircleBorder(),
//         onPressed: () {},
//         backgroundColor: Colors.black87,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Column(
//                   children: List.generate(goals.length * 2 - 1, (index) {
//                     if (index.isEven) {
//                       int goalIndex = index ~/ 2;
//                       return Column(
//                         children: [
//                           Text(
//                             goals[goalIndex].date,
//                             style: TextStyle(color: Colors.grey[600]),
//                           ),
//                           Text(
//                             goals[goalIndex].year,
//                             style: const TextStyle(
//                                 fontWeight: FontWeight.bold, fontSize: 16),
//                           ),
//                           const SizedBox(height: 8),
//                           Container(
//                             width: 10,
//                             height: 10,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                         ],
//                       );
//                     } else {
//                       return Container(
//                         height: 80,
//                         width: 2,
//                         color: Colors.grey[300],
//                       );
//                     }
//                   }),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     children: goals.map((goal) => _buildGoalCard(goal)).toList(),
//                   ),
//                 )
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildGoalCard(Goal goal) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: goal.color,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 '${(goal.progress * 100).toInt()}%',
//                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 goal.label,
//                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 goal.amount,
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Stack(
//             children: [
//               Container(
//                 width: double.infinity,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.3),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//               FractionallySizedBox(
//                 widthFactor: goal.progress,
//                 child: Container(
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                 ),
//               )
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vscmoney/constants/stock_detail_bottomsheet.dart';
import 'package:vscmoney/main.dart';
import 'package:vscmoney/screens/widgets/drawer.dart';

import '../../../constants/app_bar.dart';
import '../../../constants/bottomsheet.dart';
import '../../../constants/colors.dart';
import '../../../services/theme_service.dart';
import 'chat_screen.dart';
import 'home_screen.dart';

class Goal {
  final String id;
  final DateTime targetDate;
  final String label;
  final double progress;
  final String amount;
  final Color color;

  Goal({
    required this.id,
    required this.targetDate,
    required this.label,
    required this.progress,
    required this.amount,
    required this.color,
  });

  // Format the month from the date
  String get month => DateFormat('MMM').format(targetDate);

  // Get the year as a string
  String get year => targetDate.year.toString();
}

class GoalsPage extends StatefulWidget {
  const GoalsPage({Key? key}) : super(key: key);

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  // Start with an empty list of goals
  final List<Goal> _goals = [];

  // Available colors for new goals
  final List<Color> _availableColors = [
    Colors.blue,
    Colors.lightBlue,
    Colors.green,
    Colors.purple,
    Colors.teal,
  ];

  // Sort goals by date
  List<Goal> get _sortedGoals {
    final sorted = List<Goal>.from(_goals);
    sorted.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    return sorted;
  }
  final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey = GlobalKey();


  @override
  Widget build(BuildContext context) {
    final sortedGoals = _sortedGoals;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return ChatGPTBottomSheetWrapper(
      key:_sheetKey,
      //bottomSheet: ZomatoStockBottomSheet(),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Builder(
            builder: (context) {
              return appBar(
                context,
                "Goals",
                () {

                },
                false,
                showNewChatButton: false,
              );
            },
          ),
        ),
        drawer: CustomDrawer(
          selectedRoute: "Goals",
        ),
        backgroundColor: theme.background,
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: () => _showAddGoalDialog(),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: sortedGoals.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Icon(Icons.flag, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No goals yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first goal by tapping the + button',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        )
            : SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: sortedGoals.length,
            itemBuilder: (context, index) {
              return _buildTimelineItem(sortedGoals, index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(List<Goal> goals, int index) {
    final goal = goals[index];

    // Calculate if we need to show a new date marker
    bool showDate = true;

    // If not the first goal, check if date is same as previous goal
    if (index > 0) {
      final previousGoal = goals[index - 1];

      // Only show date if the month/year is different from previous goal
      if (previousGoal.month == goal.month && previousGoal.year == goal.year) {
        showDate = false;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date column
        SizedBox(
          width: 60,
          child: Column(
            children: [
              // Only show date if it's a new date or first item
              if (showDate) ...[
                Text(
                  goal.month,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                Text(
                  goal.year,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[800],
                  ),
                ),
              ],
              // If not first goal, add connecting line to previous goal
              if (index > 0 || !showDate)
                Container(
                  width: 2,
                  height: showDate ? 90 : 120, // Adjust height based on whether date is shown
                  color: Colors.grey[300],
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Goal card
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: showDate ? 0 : 0,  // No padding if date is shown
              bottom: 5,
            ),
            child: _buildGoalCard(goal),
          ),
        ),
      ],
    );
  }





    Widget _buildGoalCard(Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: goal.color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(goal.progress * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                goal.label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                goal.amount,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: goal.progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>  CreateGoalsSheet(
        onTap:(){
          context.pop(context);
        // _sheetKey.currentState?.openSheet();
        },
      ),
    );

  }

  // Method to add sample goals for testing UI
  void addSampleGoals() {
    setState(() {
      _goals.add(Goal(
        id: '1',
        targetDate: DateTime(2026, 3, 1),
        label: 'saadar',
        progress: 0.0,
        amount: 'DC avad',
        color: Colors.blue,
      ));
      _goals.add(Goal(
        id: '2',
        targetDate: DateTime(2026, 3, 15),
        label: 'sad dava',
        progress: 0.0,
        amount: 'cds adad adv',
        color: Colors.blue,
      ));
      _goals.add(Goal(
        id: '3',
        targetDate: DateTime(2026, 3, 20),
        label: 'adrshrhrheheg',
        progress: 0.0,
        amount: 'rebaebb',
        color: Colors.blue,
      ));
      _goals.add(Goal(
        id: '4',
        targetDate: DateTime(2036, 3, 1),
        label: 'Goal 4',
        progress: 0.0,
        amount: 'Amount 4',
        color: Colors.blue,
      ));
    });
  }
}







class CreateGoalsSheet extends StatefulWidget {
  final VoidCallback onTap;
   CreateGoalsSheet({super.key, required this.onTap});

  @override
  State<CreateGoalsSheet> createState() => _CreateGoalsSheetState();
}

class _CreateGoalsSheetState extends State<CreateGoalsSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;


    return Padding(
      padding: MediaQuery.of(context).viewInsets, // for keyboard
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration:  BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Define your Goal',
              style: TextStyle(
                color: theme.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                  fontFamily: 'Sf Pro Text'
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.box,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.shadow),
              ),
              child:  TextField(
                style: TextStyle(color: theme.text),
                cursorColor: theme.text,
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: 'Save 60k for bali trip in 6 months',
                  hintStyle: TextStyle(color: theme.secondaryText,fontFamily: 'Sf Pro Text'),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF9B21),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:  Text(
                  'Create',
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                      fontFamily: 'Sf Pro Text'
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}



class ZomatoStockBottomSheet extends StatelessWidget {
  const ZomatoStockBottomSheet({super.key});

  // Method to show the bottom sheet

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    // Calculate responsive sizes
    final paddingHorizontal = screenWidth * 0.05;
    final bottomSheetHeight = screenHeight * 0.90;

    return Container(
      height: bottomSheetHeight,
      padding: EdgeInsets.only(
        top: 16,
        left: paddingHorizontal,
        right: paddingHorizontal,
        bottom: 24,
      ),
      decoration:  BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with X button and Zomato title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 28),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Text(
                'Zomato',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 28), // Balance for the X button
            ],
          ),

          const SizedBox(height: 20),

          // Stock details section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eternal',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        '₹1821.45',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: const Text(
                          '-14.5 (1.19%)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '1D',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Zomato logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE23744),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'zomato',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stock chart
          Container(
            height: screenHeight * 0.15,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: StockChartPainter(),
            ),
          ),

          const SizedBox(height: 16),

          // Time period selector
          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeButton('NSE', false, context),
                _buildTimeButton('1D', true, context),
                _buildTimeButton('1W', false, context),
                _buildTimeButton('1M', false, context),
                _buildTimeButton('1Y', false, context),
                _buildTimeButton('5Y', false, context),
                _buildTimeButton('All', false, context),
              ],
            ),
          ),

          const Divider(height: 32),

          // Performance section
          const Text(
            'Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          // Today's range
          _buildRangeIndicator(
            'Today\'s low',
            '210.54',
            'Today\'s high',
            '216.00',
            0.3, // The position of the current value in the range (0-1)
            context,
          ),

          const SizedBox(height: 24),

          // 52 week range
          _buildRangeIndicator(
            '52 week low',
            '210.54',
            '52 week high',
            '216.00',
            0.6, // The position of the current value in the range (0-1)
            context,
          ),

          const SizedBox(height: 24),

          // Key stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Open Price', '210.54'),
              ),
              Expanded(
                child: _buildStatItem('Prev. close', '210.54'),
              ),
              Expanded(
                child: _buildStatItem('Volume', '60,62,086'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStatItem('Lower circuit', '210.54'),
              ),
              Expanded(
                child: _buildStatItem('Upper circuit', '210.54'),
              ),
              const Expanded(child: SizedBox()), // Empty cell for alignment
            ],
          ),

          const Spacer(),

          // Bottom buttons
          Row(
            children: [
              // Ask follow up button
              Expanded(
                flex: 4,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE28743),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Ask follow up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Circular refresh button
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE28743),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.currency_rupee,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom indicator
          Center(
            child: Container(
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build time period selector buttons
  Widget _buildTimeButton(String text, bool isSelected, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFBE9D7) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isSelected ? const Color(0xFFE28743) : Colors.grey[700],
        ),
      ),
    );
  }

  // Helper to build price range indicators
  Widget _buildRangeIndicator(
      String leftLabel,
      String leftValue,
      String rightLabel,
      String rightValue,
      double position,
      BuildContext context,
      ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftLabel,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              rightLabel,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftValue,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              rightValue,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.purple[100],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Positioned(
              left: MediaQuery.of(context).size.width * position * 0.8, // Adjust for padding
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper to build a stat item
  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Custom painter for stock chart
class StockChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.green.withOpacity(0.2),
          Colors.green.withOpacity(0.05),
          Colors.green.withOpacity(0.01),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw horizontal gray line (middle reference)
    final Paint grayLinePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height * 0.6),
      Offset(size.width, size.height * 0.6),
      grayLinePaint,
    );

    // Create a path for the stock line
    final path = Path();
    final fillPath = Path();

    // Sample stock data points
    final List<double> points = [
      0.7, 0.5, 0.6, 0.4, 0.5, 0.3, 0.4, 0.5, 0.6, 0.7,
      0.65, 0.6, 0.55, 0.5, 0.4, 0.35, 0.3, 0.4, 0.5,
      0.3, 0.2, 0.3, 0.4, 0.5, 0.4, 0.5, 0.6, 0.7, 0.6, 0.5
    ];

    final stepX = size.width / (points.length - 1);

    // Start paths
    path.moveTo(0, size.height * points[0]);
    fillPath.moveTo(0, size.height * points[0]);

    // Create the line and fill
    for (int i = 1; i < points.length; i++) {
      path.lineTo(i * stepX, size.height * points[i]);
      fillPath.lineTo(i * stepX, size.height * points[i]);
    }

    // Complete fill path
    fillPath.lineTo(size.width, size.height); // Bottom right
    fillPath.lineTo(0, size.height); // Bottom left
    fillPath.close();

    // Draw fill first (underneath)
    canvas.drawPath(fillPath, fillPaint);

    // Draw the line on top
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Example usage


