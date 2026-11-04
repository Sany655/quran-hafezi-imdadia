import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'index_screen.dart';

class WuduReminderScreen extends StatefulWidget {
  const WuduReminderScreen({super.key});

  @override
  State<WuduReminderScreen> createState() => _WuduReminderScreenState();
}

class _WuduReminderScreenState extends State<WuduReminderScreen> {
  void _navigateToApp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const IndexScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF04160D),
              Color(0xFF0B3821),
              Color(0xFF061E12),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // Islamic Ornament / Bismillah
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F5132),
                          border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.2),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFFFDE68A),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Bismillah Calligraphy
                      Text(
                        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 22,
                          color: Color(0xFFFDE68A),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        'পবিত্রতা ও তিলাওয়াতের আদব',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quranic Ayah Card on Purity
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Arabic Ayah
                            Text(
                              'إِنَّهُ لَقُرْآنٌ كَرِيمٌ ﴿٧٧﴾ فِي كِتَابٍ مَّكْنُونٍ ﴿٧٨﴾ لَّا يَمَسُّهُ إِلَّا الْمُطَهَّرُونَ ﴿٧٩﴾',
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 18,
                                height: 2.0,
                                color: Color(0xFFFFFBEB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Divider
                            Container(
                              height: 1,
                              width: 80,
                              color: const Color(0xFFD4AF37).withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),

                            // Bengali Meaning
                            Text(
                              '“নিশ্চয় এটি এক সম্মানিত কুরআন, যা আছে সুরক্ষিত কিতাবে; পবিত্রগণ ব্যতীত অন্য কেউ তা স্পর্শ করে না।”',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 13.5,
                                height: 1.6,
                                color: const Color(0xFFE2E8F0),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 6),

                            Text(
                              '(সূরা আল-ওয়াকি\'আহ: ৭৭-৭৯)',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 11.5,
                                color: const Color(0xFFFDE68A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mobile Touch & Wudu Guidance Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F5132).withOpacity(0.45),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.touch_app_outlined,
                                  color: Color(0xFFFDE68A),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'মোবাইলে কুরআন স্পর্শের বিধান',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'অনেকে মনে করেন মোবাইলের স্ক্রিনে কোরআন থাকলে অজুর প্রয়োজন নেই। কিন্তু ফুকাহায়ে কিরাম ও ওলামাদের নির্ভরযোগ্য ও সতর্কতামূলক ফতোয়া অনুযায়ী: মোবাইলের পর্দায় যখন কুরআনের আয়াত দৃশ্যমান থাকে, তখন বিনা অজুতে সরাসরি স্ক্রিনের আয়াতের ওপর হাত বা আঙুল লাগানো থেকে বিরত থাকা উচিত।',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 12.5,
                                height: 1.6,
                                color: const Color(0xFFF1F5F9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF061E12).withOpacity(0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.water_drop_outlined,
                                    color: Color(0xFF38BDF8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'কুরআনের পূর্ণ বরকত ও সর্বোচ্চ সম্মান প্রদর্শনের জন্য তিলাওয়াত শুরুর পূর্বে অজু করে নেওয়া সবচেয়ে উত্তম ও নিরাপদ।',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: const Color(0xFFBAE6FD),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick Adab Points
                      Row(
                        children: [
                          Expanded(
                            child: _buildAdabPill(
                              icon: Icons.check_circle_outline_rounded,
                              title: 'অজু নিশ্চিত করুন',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAdabPill(
                              icon: Icons.mic_none_rounded,
                              title: 'ধীরে ধীরে তিলাওয়াত',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAdabPill(
                              icon: Icons.favorite_border_rounded,
                              title: 'একনিষ্ঠ মনযোগ',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom Action Section: Slide to Enter
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF04160D),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'অজু অবস্থায় পবিত্র অন্তরে তিলাওয়াত শুরু করুন',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Custom Smooth Slide Button
                    _SlideToEnterWidget(
                      onConfirmed: _navigateToApp,
                    ),

                    const SizedBox(height: 8),

                    // Secondary direct button for accessibility
                    TextButton(
                      onPressed: _navigateToApp,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'সরাসরি সূচীপত্রে প্রবেশ করুন →',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11.5,
                          color: const Color(0xFFD4AF37),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdabPill({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFDE68A), size: 16),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansBengali(
              fontSize: 10.5,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideToEnterWidget extends StatefulWidget {
  final VoidCallback onConfirmed;

  const _SlideToEnterWidget({required this.onConfirmed});

  @override
  State<_SlideToEnterWidget> createState() => _SlideToEnterWidgetState();
}

class _SlideToEnterWidgetState extends State<_SlideToEnterWidget> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isConfirmed = false;
  late AnimationController _resetController;
  Animation<double>? _resetAnimation;

  final double _buttonHeight = 56.0;
  final double _knobSize = 46.0;
  final double _padding = 5.0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isConfirmed) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_isConfirmed) return;

    // If dragged more than 75% of track, complete the action
    if (_dragOffset >= maxDrag * 0.75) {
      setState(() {
        _dragOffset = maxDrag;
        _isConfirmed = true;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.onConfirmed();
      });
    } else {
      // Spring back to 0
      final current = _dragOffset;
      _resetAnimation = Tween<double>(begin: current, end: 0.0).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
      )..addListener(() {
          setState(() {
            _dragOffset = _resetAnimation!.value;
          });
        });
      _resetController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxDrag = trackWidth - _knobSize - (_padding * 2);
        final progress = maxDrag > 0 ? (_dragOffset / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          width: trackWidth,
          height: _buttonHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_buttonHeight / 2),
            color: const Color(0xFF0F5132).withOpacity(0.5),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F5132).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Filled progress track behind knob
              Container(
                width: _dragOffset + _knobSize + _padding,
                height: _buttonHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_buttonHeight / 2),
                  color: const Color(0xFF0F5132),
                ),
              ),

              // Centered prompt text (fades as user drags)
              Center(
                child: Opacity(
                  opacity: (1.0 - progress * 1.5).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'স্লাইড করে প্রবেশ করুন',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFDE68A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFFFDE68A),
                      ),
                    ],
                  ),
                ),
              ),

              // Sliding Circular Knob
              Positioned(
                left: _padding + _dragOffset,
                top: _padding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) => _onDragEnd(details, maxDrag),
                  child: Container(
                    width: _knobSize,
                    height: _knobSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFDE68A),
                          Color(0xFFD4AF37),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isConfirmed ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        color: const Color(0xFF04160D),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
