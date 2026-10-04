import 'package:flutter/material.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    required this.title,
    required this.url,
    required this.content,
  });

  final String title;
  final Uri url;
  final String content;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

enum _ReaderTone { light, sepia, dark }

class _ReaderPageState extends State<ReaderPage> {
  double _fontSize = 19;
  double _lineHeight = 1.9;
  _ReaderTone _tone = _ReaderTone.light;

  @override
  Widget build(BuildContext context) {
    final palette = switch (_tone) {
      _ReaderTone.light => (const Color(0xFFFDFDFD), const Color(0xFF202124)),
      _ReaderTone.sepia => (const Color(0xFFF6F0E3), const Color(0xFF3F372B)),
      _ReaderTone.dark => (const Color(0xFF17181A), const Color(0xFFE9EAEC)),
    };

    return Scaffold(
      backgroundColor: palette.$1,
      appBar: AppBar(
        backgroundColor: palette.$1,
        foregroundColor: palette.$2,
        title: const Text('حالت مطالعه'),
        actions: [
          PopupMenuButton<_ReaderTone>(
            tooltip: 'رنگ صفحه',
            initialValue: _tone,
            onSelected: (value) => setState(() => _tone = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _ReaderTone.light, child: Text('روشن')),
              PopupMenuItem(value: _ReaderTone.sepia, child: Text('سپیا')),
              PopupMenuItem(value: _ReaderTone.dark, child: Text('تیره')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SelectionArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 42),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.title.trim().isEmpty
                                ? widget.url.host
                                : widget.title,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              color: palette.$2,
                              fontSize: _fontSize + 8,
                              height: 1.45,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.url.host,
                            style: TextStyle(
                              color: palette.$2.withValues(alpha: .62),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.content,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: palette.$2,
                              fontSize: _fontSize,
                              height: _lineHeight,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.$1,
                border: Border(
                  top: BorderSide(color: palette.$2.withValues(alpha: .10)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'کوچک‌تر',
                        onPressed: _fontSize <= 15
                            ? null
                            : () => setState(() => _fontSize -= 1),
                        icon: Icon(Icons.text_decrease_rounded, color: palette.$2),
                      ),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 15,
                          max: 28,
                          divisions: 13,
                          label: _fontSize.round().toString(),
                          onChanged: (value) => setState(() => _fontSize = value),
                        ),
                      ),
                      IconButton(
                        tooltip: 'بزرگ‌تر',
                        onPressed: _fontSize >= 28
                            ? null
                            : () => setState(() => _fontSize += 1),
                        icon: Icon(Icons.text_increase_rounded, color: palette.$2),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'فاصله خطوط',
                        onPressed: () => setState(() {
                          _lineHeight = _lineHeight >= 2.2 ? 1.6 : _lineHeight + .2;
                        }),
                        icon: Icon(Icons.format_line_spacing_rounded, color: palette.$2),
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
