import 'package:flutter/material.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildSearchBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSaleReceiptCard('600 yar', 'PM 09:02 2026-04-20', '1 منتجات'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesChartScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
                  child: const Icon(Icons.leaderboard, color: Colors.white70, size: 20),
                )
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
                child: const Icon(Icons.tune, color: Colors.white70, size: 20),
              )
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('المبيعات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.cyan, borderRadius: BorderRadius.circular(12)),
                    child: const Text('إجمالي المبلغ: 600 yar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                  )
                ],
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
                )
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
         textAlign: TextAlign.right,
         style: const TextStyle(color: Colors.white),
         decoration: InputDecoration(
           hintText: 'بحث في المبيعات...',
           hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
           prefixIcon: const Icon(Icons.search, color: Colors.grey), // Search icon on the left based on screenshot! Wait, in screen it's on right? 
           suffixIcon: const Icon(Icons.search, color: Colors.grey), // Actually it's on right in image 2
           filled: true,
           fillColor: const Color(0xFF1A1A24),
           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
           contentPadding: const EdgeInsets.symmetric(vertical: 14),
           isDense: true,
         )
      )
    );
  }

  Widget _buildSaleReceiptCard(String amount, String date, String itemsCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                 child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
               ),
               const SizedBox(width: 8),
               Container(
                 padding: const EdgeInsets.all(10),
                 decoration: const BoxDecoration(color: Color(0xFF252533), shape: BoxShape.circle),
                 child: const Icon(Icons.print, color: Colors.white70, size: 20),
               ),
             ],
          ),
          Row(
            children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                    Text(amount, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    Text(itemsCount, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                 ],
               ),
               const SizedBox(width: 16),
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: const Color(0xFF111116), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                 child: const Icon(Icons.receipt_long, color: Colors.blueAccent),
               )
            ],
          )
        ],
      )
    );
  }
}

// ----------------------------------------------------
// مؤشر المبيعات والمنصرفات (رسم بياني) - Landscape Style 
// ----------------------------------------------------
class SalesChartScreen extends StatelessWidget {
  const SalesChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                        )
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
                        child: const Icon(Icons.leaderboard, color: Colors.white70, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
                        child: const Icon(Icons.visibility, color: Colors.white70, size: 20),
                      )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                       Text('مؤشر المبيعات والمنصرفات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            // Date Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
                   child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
                 ),
                 const SizedBox(width: 16),
                 const Text('٢٠٢٦/٠٤/٢٤', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                 const SizedBox(width: 16),
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
                   child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                 ),
              ],
            ),
            const Spacer(),
            
            // Text values around chart 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('صافي الربح', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text('0 yar', style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                    ]
                  )
                ]
              )
            ),
            const SizedBox(height: 24),
            // Lines
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 2, color: Colors.greenAccent
            ),
            const SizedBox(height: 2),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 2, color: Colors.redAccent
            ),
            
            const Spacer(),
            
            // Bottom Dashboard inside Chart
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                 color: Colors.black,
                 borderRadius: BorderRadius.circular(24),
                 border: Border.all(color: Colors.white10)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('ساعة الذروة', Icons.access_time, '-', Colors.greenAccent),
                  Container(width: 1, height: 40, color: Colors.white10),
                  _buildStatItem('المصروفات', Icons.arrow_downward, '0 yar', Colors.redAccent),
                  Container(width: 1, height: 40, color: Colors.white10),
                  _buildStatItem('المبيعات', Icons.arrow_upward, '0 yar', Colors.blueAccent),
                ],
              )
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('9 م', style: TextStyle(color: Colors.white24, fontSize: 10)),
                  Text('6 م', style: TextStyle(color: Colors.white24, fontSize: 10)),
                  Text('3 م', style: TextStyle(color: Colors.white24, fontSize: 10)),
                  Text('12 م', style: TextStyle(color: Colors.white24, fontSize: 10)),
                  Text('9 ص', style: TextStyle(color: Colors.white24, fontSize: 10)),
                  Text('6 ص', style: TextStyle(color: Colors.white24, fontSize: 10)),
                  Text('3 ص', style: TextStyle(color: Colors.white24, fontSize: 10)),
                  Text('12 ص', style: TextStyle(color: Colors.white24, fontSize: 10)),
                ]
              )
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, IconData icon, String value, Color color) {
    return Column(
      children: [
        Row(
          children: [
             Icon(icon, color: color, size: 12),
             const SizedBox(width: 4),
             Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color == Colors.greenAccent ? Colors.greenAccent : (color == Colors.redAccent ? Colors.redAccent : Colors.blueAccent), fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
