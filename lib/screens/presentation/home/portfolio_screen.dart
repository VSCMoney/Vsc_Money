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
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final sortedGoals = _sortedGoals;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Builder(
          builder: (context) => appBars(context, "Portfolio", () {}),
        ),
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () => _showAddGoalDialog(),
        backgroundColor: Colors.grey[800],
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
    final formKey = GlobalKey<FormState>();
    final TextEditingController labelController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 365));
    Color selectedColor = _availableColors.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Goal'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: labelController,
                  decoration: const InputDecoration(labelText: 'Goal Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a goal name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Goal Amount'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a goal amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Target Date: '),
                    TextButton(
                      onPressed: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          selectedDate = pickedDate;
                        }
                      },
                      child: Text(DateFormat('MMM yyyy').format(selectedDate)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Select Color:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        selectedColor = color;
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color == selectedColor ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _goals.add(Goal(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    targetDate: selectedDate,
                    label: labelController.text,
                    progress: 0.0,
                    amount: amountController.text,
                    color: selectedColor,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add Goal'),
          ),
        ],
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






PreferredSizeWidget appBars(BuildContext context, String title, VoidCallback onNewChatTap) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(150),
    child: Card(
      elevation: 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 👈 Center logo
                Text("Goals" , style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18
                ),),

                // 👈 Row for left and right buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left menu icon
                    // ✅ Wrap this with Builder to get the right context
                    Builder(
                      builder: (BuildContext scaffoldContext) {
                        return GestureDetector(
                          onTap: () {
                            print("jdn");
                            // ✅ This will definitely open the drawer
                            Scaffold.of(scaffoldContext).openDrawer();
                          },
                          child: SvgPicture.asset('assets/images/drawer.svg'),
                        );
                      },
                    ),



                    // Right-side icons
                    Row(
                      children: [
                        GestureDetector(
                            onTap: (){

                            },
                            child: const Icon(Icons.notifications_none_outlined, color: Colors.black)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),

  );
}
