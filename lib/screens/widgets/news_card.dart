import 'package:flutter/material.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IRB Infrastructure to Present at Arihant Capital’s Virtual Conference March 25',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 8),
                const Text('1h ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                const Text(
                  'IRB Infrastructure Developers will attend a virtual conference hosted by Arihant Capital...',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Text('Show more', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: Colors.orange, size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Icon(Icons.bookmark_border, size: 20),
                    SizedBox(width: 12),
                    Icon(Icons.share, size: 20),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/Mask group.png', height: 20, width: 20),
                    const SizedBox(width: 8),
                    const Text('IRB Infra Devs', style: TextStyle(fontSize: 13.5)),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text('₹45.88', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(width: 4),
                    Text('0.84%', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
