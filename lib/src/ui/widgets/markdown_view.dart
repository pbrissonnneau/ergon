import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// Lightweight Markdown renderer (paragraphs, emphasis, headings, lists,
/// links, quotes, code). Links open in the user's external application; the
/// app itself never performs network requests.
class MarkdownView extends StatefulWidget {
  const MarkdownView(this.data, {super.key, this.selectable = true});
  final String data;
  final bool selectable;

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  final _recognizers = <GestureRecognizer>[];
  List<md.Node>? _nodes;
  String? _parsed;

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  List<md.Node> get nodes {
    if (_parsed != widget.data) {
      _parsed = widget.data;
      _nodes = md.Document(
        extensionSet: md.ExtensionSet.gitHubFlavored,
        encodeHtml: false,
      ).parseLines(widget.data.replaceAll('\r\n', '\n').split('\n'));
    }
    return _nodes!;
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final children = <Widget>[];
    for (final n in nodes) {
      final w = _block(context, n, 0);
      if (w != null) children.add(w);
    }
    final col = Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    return widget.selectable ? SelectionArea(child: col) : col;
  }

  Widget? _block(BuildContext context, md.Node node, int depth) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    if (node is md.Text) {
      return _para(context, [TextSpan(text: node.text)], text.bodyMedium);
    }
    if (node is! md.Element) return null;
    switch (node.tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        final style = switch (node.tag) {
          'h1' => text.headlineSmall,
          'h2' => text.titleLarge,
          'h3' => text.titleMedium,
          _ => text.titleSmall,
        };
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text.rich(
            TextSpan(children: _inlines(context, node.children)),
            style: style?.copyWith(fontWeight: FontWeight.w600),
          ),
        );
      case 'p':
        return _para(context, _inlines(context, node.children), text.bodyMedium);
      case 'ul':
      case 'ol':
        final ordered = node.tag == 'ol';
        final start = int.tryParse(node.attributes['start'] ?? '') ?? 1;
        var i = 0;
        return Padding(
          padding: EdgeInsets.only(left: depth == 0 ? 4 : 16, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final li in (node.children ?? const <md.Node>[]).whereType<md.Element>())
                _listItem(context, li, ordered ? '${start + i++}.' : '•', depth),
            ],
          ),
        );
      case 'blockquote':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: theme.colorScheme.outline, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final c in node.children ?? const <md.Node>[]) ?_block(context, c, depth)],
          ),
        );
      case 'pre':
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(node.textContent, style: text.bodySmall?.copyWith(fontFamily: 'monospace')),
        );
      case 'hr':
        return const Divider(height: 16);
      default:
        return _para(context, _inlines(context, node.children), text.bodyMedium);
    }
  }

  Widget _listItem(BuildContext context, md.Element li, String bullet, int depth) {
    final inline = <md.Node>[];
    final nested = <Widget>[];
    for (final c in li.children ?? const <md.Node>[]) {
      if (c is md.Element && (c.tag == 'ul' || c.tag == 'ol')) {
        nested.add(_block(context, c, depth + 1)!);
      } else if (c is md.Element && c.tag == 'p') {
        inline.addAll(c.children ?? const []);
      } else {
        inline.add(c);
      }
    }
    final checkbox = li.attributes['class']?.contains('task-list-item') ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: checkbox ? const SizedBox.shrink() : Text(bullet, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(children: _inlines(context, inline)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        ...nested,
      ],
    );
  }

  Widget _para(BuildContext context, List<InlineSpan> spans, TextStyle? style) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(TextSpan(children: spans), style: style),
  );

  List<InlineSpan> _inlines(BuildContext context, List<md.Node>? nodes, [TextStyle style = const TextStyle()]) {
    final out = <InlineSpan>[];
    for (final n in nodes ?? const <md.Node>[]) {
      if (n is md.Text) {
        out.add(TextSpan(text: n.text, style: style));
      } else if (n is md.Element) {
        switch (n.tag) {
          case 'strong':
            out.addAll(_inlines(context, n.children, style.copyWith(fontWeight: FontWeight.bold)));
          case 'em':
            out.addAll(_inlines(context, n.children, style.copyWith(fontStyle: FontStyle.italic)));
          case 'del':
            out.addAll(_inlines(context, n.children, style.copyWith(decoration: TextDecoration.lineThrough)));
          case 'code':
            out.add(
              TextSpan(
                text: n.textContent,
                style: style.copyWith(
                  fontFamily: 'monospace',
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            );
          case 'br':
            out.add(const TextSpan(text: '\n'));
          case 'input':
            final checked = n.attributes['checked'] != null;
            out.add(TextSpan(text: checked ? '☑ ' : '☐ ', style: style));
          case 'a':
            final href = n.attributes['href'] ?? '';
            final r = TapGestureRecognizer()..onTap = () => _openLink(href);
            _recognizers.add(r);
            out.add(
              TextSpan(
                children: _inlines(
                  context,
                  n.children,
                  style.copyWith(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
                ),
                recognizer: r,
                mouseCursor: SystemMouseCursors.click,
              ),
            );
          default:
            out.addAll(_inlines(context, n.children, style));
        }
      }
    }
    return out;
  }

  Future<void> _openLink(String href) async {
    final uri = Uri.tryParse(href);
    if (uri == null || !uri.hasScheme) return;
    // Hand the link to the OS (browser / mail client); Ergon never fetches it.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
