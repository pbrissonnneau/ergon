import 'package:flutter/material.dart';

import 'markdown_view.dart';

/// Plain-text Markdown editor with a formatting toolbar and preview toggle.
class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({super.key, required this.controller, this.onChanged, this.startInPreview = false});
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool startInPreview;

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late bool _preview = widget.startInPreview && widget.controller.text.isNotEmpty;
  final _focus = FocusNode();

  TextEditingController get c => widget.controller;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _changed() => widget.onChanged?.call(c.text);

  void _wrap(String left, [String? right]) {
    right ??= left;
    final sel = c.selection.isValid ? c.selection : TextSelection.collapsed(offset: c.text.length);
    final selected = sel.textInside(c.text);
    final replacement = '$left${selected.isEmpty ? 'text' : selected}$right';
    c.value = c.value.copyWith(
      text: c.text.replaceRange(sel.start, sel.end, replacement),
      selection: TextSelection(
        baseOffset: sel.start + left.length,
        extentOffset: sel.start + replacement.length - right.length,
      ),
    );
    _focus.requestFocus();
    _changed();
  }

  void _prefixLines(String Function(int i) prefix) {
    final sel = c.selection.isValid ? c.selection : TextSelection.collapsed(offset: c.text.length);
    final text = c.text;
    final lineStart = text.lastIndexOf('\n', sel.start > 0 ? sel.start - 1 : 0) + 1;
    var lineEnd = text.indexOf('\n', sel.end);
    if (lineEnd < 0) lineEnd = text.length;
    final lines = text.substring(lineStart, lineEnd).split('\n');
    final updated = [for (var i = 0; i < lines.length; i++) '${prefix(i)}${lines[i]}'].join('\n');
    c.value = c.value.copyWith(
      text: text.replaceRange(lineStart, lineEnd, updated),
      selection: TextSelection.collapsed(offset: lineStart + updated.length),
    );
    _focus.requestFocus();
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _tool(Icons.format_bold, 'Bold', () => _wrap('**')),
                        _tool(Icons.format_italic, 'Italic', () => _wrap('_')),
                        _tool(Icons.title, 'Heading', () => _prefixLines((_) => '## ')),
                        _tool(Icons.format_list_bulleted, 'Bullet list', () => _prefixLines((_) => '- ')),
                        _tool(Icons.format_list_numbered, 'Numbered list', () => _prefixLines((i) => '${i + 1}. ')),
                        _tool(Icons.check_box_outlined, 'Checklist', () => _prefixLines((_) => '- [ ] ')),
                        _tool(Icons.link, 'Link', () => _wrap('[', '](https://)')),
                      ],
                    ),
                  ),
                ),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: const [
                    ButtonSegment(value: false, label: Text('Edit')),
                    ButtonSegment(value: true, label: Text('Preview')),
                  ],
                  selected: {_preview},
                  onSelectionChanged: (s) => setState(() => _preview = s.first),
                ),
              ],
            ),
          ),
          const Divider(),
          if (_preview)
            Padding(
              padding: const EdgeInsets.all(12),
              child: c.text.trim().isEmpty
                  ? Text('Nothing to preview', style: TextStyle(color: scheme.outline))
                  : MarkdownView(c.text),
            )
          else
            TextField(
              controller: c,
              focusNode: _focus,
              minLines: 4,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              onChanged: (_) => _changed(),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintText: 'Add a description (Markdown supported)',
              ),
            ),
        ],
      ),
    );
  }

  Widget _tool(IconData icon, String tip, VoidCallback onTap) => IconButton(
    icon: Icon(icon, size: 20),
    tooltip: tip,
    visualDensity: VisualDensity.compact,
    onPressed: _preview ? null : onTap,
  );
}
