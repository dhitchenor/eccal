import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

// Converts Quill Document format to various text formats (Markdown, plain text, etc.)
//
// Handles all Quill formatting attributes and converts them to Markdown:
// - Bold, italic, underline, strikethrough
// - Headers (h1-h6)
// - Lists (ordered and unordered)
//
// To be added, properly:
// - Links
// - Code blocks and inline code
// - Blockquotes

class EntryConverter {
  // Convert a Quill Document to Markdown
  static String toMarkdown(Document document) {
    final delta = document.toDelta();
    final buffer = StringBuffer();
    String currentLine = '';
    Map<String, dynamic>? lineAttributes;

    for (final op in delta.toList()) {
      if (op.data is! String) continue;

      final text = op.data as String;
      final attributes = op.attributes ?? {};

      // Check if this operation contains a newline
      if (text.contains('\n')) {
        final parts = text.split('\n');

        for (int i = 0; i < parts.length; i++) {
          if (i > 0) {
            // Before processing this line, check if the newline has attributes
            // Those attributes belong to the line we just finished
            if (text == '\n' && attributes.isNotEmpty) {
              // Pure newline with attributes - apply to current line
              lineAttributes = attributes;
            }

            // Process the completed line
            final formattedLine = _formatLine(currentLine, lineAttributes);
            buffer.writeln(formattedLine);
            currentLine = '';
            lineAttributes = null;
          }

          if (parts[i].isNotEmpty) {
            currentLine += _applyInlineFormatting(parts[i], attributes);
          }
        }

        // If this wasn't a pure newline, store attributes for next line
        if (text != '\n') {
          lineAttributes = attributes;
        }
      } else {
        // No newline, just accumulate text
        currentLine += _applyInlineFormatting(text, attributes);
      }
    }

    // Don't forget the last line if it doesn't end with newline
    if (currentLine.isNotEmpty) {
      final formattedLine = _formatLine(currentLine, lineAttributes);
      buffer.write(formattedLine);
    }

    return buffer.toString().trimRight();
  }

  // Apply inline formatting (bold, italic, etc.) to text
  static String _applyInlineFormatting(
    String text,
    Map<String, dynamic> attributes,
  ) {
    String formatted = text;

    // Apply formatting in order (innermost to outermost)

    // Subscript - HTML tag
    if (attributes['script'] == 'sub') {
      formatted = '<sub>$formatted</sub>';
    }

    // Superscript - HTML tag
    if (attributes['script'] == 'super') {
      formatted = '<sup>$formatted</sup>';
    }

    // Code (inline) - backticks
    if (attributes['code'] == true) {
      formatted = '`$formatted`';
    }

    // Strikethrough
    if (attributes['strike'] == true) {
      formatted = '~~$formatted~~';
    }

    // Underline - HTML tag
    if (attributes['underline'] == true) {
      formatted = '<u>$formatted</u>';
    }

    // Italic
    if (attributes['italic'] == true) {
      formatted = '*$formatted*';
    }

    // Bold
    if (attributes['bold'] == true) {
      formatted = '**$formatted**';
    }

    // Link
    if (attributes['link'] != null) {
      final url = attributes['link'] as String;
      formatted = '[$formatted]($url)';
    }

    return formatted;
  }

  // Format a complete line based on line-level attributes (headers, lists, blockquotes)
  static String _formatLine(String line, Map<String, dynamic>? attributes) {
    if (line.isEmpty && (attributes == null || attributes.isEmpty)) {
      return '';
    }

    attributes ??= {};

    // Headers (h1 through h6) - hashes before AND after
    if (attributes['header'] != null) {
      final level = attributes['header'] as int;
      final hashes = '#' * level;
      return '$hashes $line $hashes';
    }

    // Code block - use actual newlines
    if (attributes['code-block'] == true) {
      return '''```
$line
```''';
    }

    // Blockquote
    if (attributes['blockquote'] == true) {
      return '> $line';
    }

    // Lists
    if (attributes['list'] != null) {
      final listType = attributes['list'] as String;
      final indent = (attributes['indent'] as int?) ?? 0;
      final indentation = '  ' * indent;

      if (listType == 'ordered') {
        return '$indentation 1. $line';
      } else if (listType == 'bullet') {
        return '$indentation - $line';
      } else if (listType == 'checked') {
        return '$indentation - [x] $line';
      } else if (listType == 'unchecked') {
        return '$indentation - [ ] $line';
      }
    }

    // Alignment (not standard Markdown)
    if (attributes['align'] != null) {
      // Markdown doesn't support alignment natively
      // Just return the line as-is
    }

    // Indentation without list
    if (attributes['indent'] != null && attributes['list'] == null) {
      final indent = attributes['indent'] as int;
      final indentation = '  ' * indent;
      return '$indentation$line';
    }

    // Default: just return the line
    return line;
  }

  // Convert a Quill Document to plain text (strips all formatting)
  static String toPlainText(Document document) {
    return document.toPlainText();
  }

  // Convert a Quill Document to Delta JSON string
  static String toDeltaJson(Document document) {
    final delta = document.toDelta();
    return jsonEncode(delta.toJson());
  }

  // Create a Quill Document from Delta JSON string
  static Document fromDeltaJson(String deltaJson) {
    final json = jsonDecode(deltaJson) as List;
    final buffer = StringBuffer();

    for (final op in json) {
      if (op is Map<String, dynamic>) {
        final insert = op['insert'];
        if (insert is String) {
          buffer.write(insert);
        }
      }
    }

    return Document()..insert(0, buffer.toString());
  }

  // Create a Quill Document from plain text
  static Document fromPlainText(String text) {
    return Document()..insert(0, text);
  }

  // Convert Markdown to Quill Document with proper formatting
  // Uses Delta operations to prevent attribute bleeding
  static Document fromMarkdown(String markdown) {
    final lines = markdown.split('\n');
    final operations = <Map<String, dynamic>>[];

    for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      String line = lines[lineIdx];
      Map<String, dynamic>? lineAttributes;

      // Handle headers - strip hashes from both ends
      if (line.startsWith('###### ')) {
        line = line
            .substring(7)
            .replaceAll(RegExp(r'\s*######\s*$'), '')
            .trim();
        lineAttributes = {'header': 6};
      } else if (line.startsWith('##### ')) {
        line = line.substring(6).replaceAll(RegExp(r'\s*#####\s*$'), '').trim();
        lineAttributes = {'header': 5};
      } else if (line.startsWith('#### ')) {
        line = line.substring(5).replaceAll(RegExp(r'\s*####\s*$'), '').trim();
        lineAttributes = {'header': 4};
      } else if (line.startsWith('### ')) {
        line = line.substring(4).replaceAll(RegExp(r'\s*###\s*$'), '').trim();
        lineAttributes = {'header': 3};
      } else if (line.startsWith('## ')) {
        line = line.substring(3).replaceAll(RegExp(r'\s*##\s*$'), '').trim();
        lineAttributes = {'header': 2};
      } else if (line.startsWith('# ')) {
        line = line.substring(2).replaceAll(RegExp(r'\s*#\s*$'), '').trim();
        lineAttributes = {'header': 1};
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        line = line.substring(2);
        lineAttributes = {'list': 'bullet'};
      } else if (RegExp(r'^(\d+)\.\s+').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\.\s+').firstMatch(line)!;
        line = line.substring(match.end);
        lineAttributes = {'list': 'ordered'};
      } else if (line.startsWith('> ')) {
        line = line.substring(2);
        lineAttributes = {'blockquote': true};
      } else if (line.startsWith('```')) {
        final codeLines = <String>[];
        lineIdx++;
        while (lineIdx < lines.length && !lines[lineIdx].startsWith('```')) {
          codeLines.add(lines[lineIdx]);
          lineIdx++;
        }
        if (codeLines.isNotEmpty) {
          operations.add({'insert': codeLines.join('\n')});
          operations.add({
            'insert': '\n',
            'attributes': {'code-block': true},
          });
        }
        continue;
      }

      // Parse inline formatting for this line
      if (line.isNotEmpty) {
        final segments = _parseInlineMarkdown(line);
        for (final segment in segments) {
          if (segment.text.isNotEmpty) {
            final attrs = <String, dynamic>{};
            for (final attr in segment.attributes) {
              attrs[attr.key] = attr.value;
            }
            operations.add({
              'insert': segment.text,
              if (attrs.isNotEmpty) 'attributes': attrs,
            });
          }
        }
      }

      // Add newline with line-level attributes
      operations.add({
        'insert': '\n',
        if (lineAttributes != null) 'attributes': lineAttributes,
      });
    }

    // Create Document from Delta JSON operations (Document.fromJson expects the ops list directly)
    return Document.fromJson(operations);
  }

  // Parse inline markdown and return segments with Attribute objects
  // Single-pass parser with priority order: 1. Bold, 2. Italic, 3. HTML tags
  static List<_StyledText> _parseInlineMarkdown(String text) {
    return _parseWithPriority(text, 0);
  }

  // Recursive parser that respects priority: bold > italic > HTML tags
  // Priority levels: 0 = all, 1 = skip bold, 2 = skip bold+italic, 3 = only HTML
  static List<_StyledText> _parseWithPriority(String text, int skipLevel) {
    final result = <_StyledText>[];
    final buffer = StringBuffer();
    int i = 0;

    while (i < text.length) {
      bool matched = false;

      // Priority 1: Bold and italic (***text***)
      if (skipLevel < 1 &&
          i + 2 < text.length &&
          text.substring(i, i + 3) == '***') {
        final end = text.indexOf('***', i + 3);
        if (end != -1) {
          if (buffer.isNotEmpty) {
            result.add(_StyledText(buffer.toString(), []));
            buffer.clear();
          }
          // Recursively parse inner content with italic+HTML priority
          final innerSegments = _parseWithPriority(
            text.substring(i + 3, end),
            1,
          );
          for (final segment in innerSegments) {
            result.add(
              _StyledText(segment.text, [
                Attribute.bold,
                Attribute.italic,
                ...segment.attributes,
              ]),
            );
          }
          i = end + 3;
          matched = true;
        }
      }

      // Priority 2: Bold (**text**)
      if (!matched &&
          skipLevel < 1 &&
          i + 1 < text.length &&
          text.substring(i, i + 2) == '**') {
        final end = text.indexOf('**', i + 2);
        if (end != -1) {
          if (buffer.isNotEmpty) {
            result.add(_StyledText(buffer.toString(), []));
            buffer.clear();
          }
          // Recursively parse inner content with italic+HTML priority
          final innerSegments = _parseWithPriority(
            text.substring(i + 2, end),
            1,
          );
          for (final segment in innerSegments) {
            result.add(
              _StyledText(segment.text, [
                Attribute.bold,
                ...segment.attributes,
              ]),
            );
          }
          i = end + 2;
          matched = true;
        }
      }

      // Priority 3: Italic (*text* or _text_)
      if (!matched && skipLevel < 2 && (text[i] == '*' || text[i] == '_')) {
        final marker = text[i];
        final end = text.indexOf(marker, i + 1);
        if (end != -1 && end > i + 1) {
          if (buffer.isNotEmpty) {
            result.add(_StyledText(buffer.toString(), []));
            buffer.clear();
          }
          // Recursively parse inner content with HTML priority only
          final innerSegments = _parseWithPriority(
            text.substring(i + 1, end),
            2,
          );
          for (final segment in innerSegments) {
            result.add(
              _StyledText(segment.text, [
                Attribute.italic,
                ...segment.attributes,
              ]),
            );
          }
          i = end + 1;
          matched = true;
        }
      }

      // Priority 4: Strikethrough (~~text~~)
      if (!matched && i + 1 < text.length && text.substring(i, i + 2) == '~~') {
        final end = text.indexOf('~~', i + 2);
        if (end != -1) {
          if (buffer.isNotEmpty) {
            result.add(_StyledText(buffer.toString(), []));
            buffer.clear();
          }
          result.add(
            _StyledText(text.substring(i + 2, end), [Attribute.strikeThrough]),
          );
          i = end + 2;
          matched = true;
        }
      }

      // Priority 5: Inline code (`code`)
      if (!matched && text[i] == '`') {
        final end = text.indexOf('`', i + 1);
        if (end != -1) {
          if (buffer.isNotEmpty) {
            result.add(_StyledText(buffer.toString(), []));
            buffer.clear();
          }
          result.add(
            _StyledText(text.substring(i + 1, end), [Attribute.inlineCode]),
          );
          i = end + 1;
          matched = true;
        }
      }

      // Priority 6: Underline (<u>text</u>)
      if (!matched &&
          i + 2 < text.length &&
          text.substring(i, i + 3) == '<u>') {
        final end = text.indexOf('</u>', i + 3);
        if (end != -1) {
          if (buffer.isNotEmpty) {
            result.add(_StyledText(buffer.toString(), []));
            buffer.clear();
          }
          // Recursively parse inner content to handle nested tags
          final innerSegments = _parseWithPriority(
            text.substring(i + 3, end),
            3,
          );
          for (final segment in innerSegments) {
            result.add(
              _StyledText(segment.text, [
                Attribute.underline,
                ...segment.attributes,
              ]),
            );
          }
          i = end + 4;
          matched = true;
        }
      }

      // Priority 7: Subscript (<sub>text</sub>)
      if (!matched &&
          i + 4 < text.length &&
          text.substring(i, i + 5) == '<sub>') {
        final end = text.indexOf('</sub>', i + 5);
        if (end != -1) {
          if (buffer.isNotEmpty) {
            result.add(_StyledText(buffer.toString(), []));
            buffer.clear();
          }
          // Recursively parse inner content to handle nested tags
          final innerSegments = _parseWithPriority(
            text.substring(i + 5, end),
            3,
          );
          for (final segment in innerSegments) {
            result.add(
              _StyledText(segment.text, [
                Attribute.subscript,
                ...segment.attributes,
              ]),
            );
          }
          i = end + 6;
          matched = true;
        }
      }

      // Priority 8: Superscript (<sup>text</sup>)
      if (!matched &&
          i + 4 < text.length &&
          text.substring(i, i + 5) == '<sup>') {
        final end = text.indexOf('</sup>', i + 5);
        if (end != -1) {
          if (buffer.isNotEmpty) {
            result.add(_StyledText(buffer.toString(), []));
            buffer.clear();
          }
          // Recursively parse inner content to handle nested tags
          final innerSegments = _parseWithPriority(
            text.substring(i + 5, end),
            3,
          );
          for (final segment in innerSegments) {
            result.add(
              _StyledText(segment.text, [
                Attribute.superscript,
                ...segment.attributes,
              ]),
            );
          }
          i = end + 6;
          matched = true;
        }
      }

      // Priority 9: Links ([text](url))
      if (!matched && text[i] == '[') {
        final textEnd = text.indexOf(']', i + 1);
        if (textEnd != -1 &&
            textEnd + 1 < text.length &&
            text[textEnd + 1] == '(') {
          final urlEnd = text.indexOf(')', textEnd + 2);
          if (urlEnd != -1) {
            if (buffer.isNotEmpty) {
              result.add(_StyledText(buffer.toString(), []));
              buffer.clear();
            }
            final linkText = text.substring(i + 1, textEnd);
            final url = text.substring(textEnd + 2, urlEnd);
            result.add(_StyledText(linkText, [LinkAttribute(url)]));
            i = urlEnd + 1;
            matched = true;
          }
        }
      }

      // No match - add character to buffer
      if (!matched) {
        buffer.write(text[i]);
        i++;
      }
    }

    if (buffer.isNotEmpty) {
      result.add(_StyledText(buffer.toString(), []));
    }

    return result.isNotEmpty ? result : [_StyledText('', [])];
  }
}

// Helper class for styled text segments with Attribute objects
class _StyledText {
  final String text;
  final List<Attribute> attributes;

  _StyledText(this.text, this.attributes);
}
