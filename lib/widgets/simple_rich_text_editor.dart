import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../services/entry_conversion.dart';
import '../utils/app_localizations.dart';

class SimpleRichTextEditor extends StatefulWidget {
  final String? initialMarkdown;
  final ValueChanged<String>? onChanged;

  const SimpleRichTextEditor({
    Key? key,
    this.initialMarkdown,
    this.onChanged,
  }) : super(key: key);

  @override
  State<SimpleRichTextEditor> createState() => SimpleRichTextEditorState();
}

class SimpleRichTextEditorState extends State<SimpleRichTextEditor> {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _toolbarScrollController = ScrollController(); // Add this

  @override
  void initState() {
    super.initState();
    
    // Create document from initial markdown (convert to rich text)
    final doc = (widget.initialMarkdown != null && widget.initialMarkdown!.isNotEmpty)
        ? EntryConverter.fromMarkdown(widget.initialMarkdown!)
        : quill.Document()..insert(0, '');
    
    _controller = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    
    _controller.addListener(() {
      // This listener fires when the document changes (including toolbar taps)
      if (!_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      }

      widget.onChanged?.call(getMarkdown());
    });
    
    // Scroll toolbar to the right after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_toolbarScrollController.hasClients) {
        _toolbarScrollController.jumpTo(_toolbarScrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _toolbarScrollController.dispose();
    super.dispose();
  }

  // Method to set markdown content programmatically
  void setMarkdown(String markdown) {
    // Convert Markdown to Quill Document to preserve formatting
    final doc = markdown.isNotEmpty 
        ? EntryConverter.fromMarkdown(markdown)
        : quill.Document()..insert(0, '');
    
    _controller.document = doc;
    _controller.updateSelection(const TextSelection.collapsed(offset: 0), quill.ChangeSource.local);
  }

  // Method to clear the editor
  void clear() {
    final doc = quill.Document()..insert(0, '');
    _controller.document = doc;
    _controller.updateSelection(const TextSelection.collapsed(offset: 0), quill.ChangeSource.local);
  }

  // Get markdown text (converts Quill Document to Markdown)
  String getMarkdown() {
    return EntryConverter.toMarkdown(_controller.document);
  }

  // Get the Quill Document for proper conversion
  quill.Document? getDocument() {
    return _controller.document;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toolbar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Theme(
                data: ThemeData(
                  iconTheme: IconThemeData(color: Colors.grey.shade800),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _toolbarScrollController, // Add this
                  child: Row(
                    children: [
                      // Undo
                      quill.QuillToolbarHistoryButton(
                        isUndo: true,
                        controller: _controller,
                        options: const quill.QuillToolbarHistoryButtonOptions(iconSize: 20),
                      ),
                      // Redo
                      quill.QuillToolbarHistoryButton(
                        isUndo: false,
                        controller: _controller,
                        options: const quill.QuillToolbarHistoryButtonOptions(iconSize: 20),
                      ),
                      const SizedBox(width: 8),

                      // Bold
                      quill.QuillToolbarToggleStyleButton(
                        controller: _controller,
                        attribute: quill.Attribute.bold,
                        options: const quill.QuillToolbarToggleStyleButtonOptions(iconSize: 20),
                      ),
                      // Italic
                      quill.QuillToolbarToggleStyleButton(
                        controller: _controller,
                        attribute: quill.Attribute.italic,
                        options: const quill.QuillToolbarToggleStyleButtonOptions(iconSize: 20),
                      ),
                      // Underline
                      quill.QuillToolbarToggleStyleButton(
                        controller: _controller,
                        attribute: quill.Attribute.underline,
                        options: const quill.QuillToolbarToggleStyleButtonOptions(iconSize: 20),
                      ),

                      const SizedBox(width: 8),

                      // Subscript
                      quill.QuillToolbarToggleStyleButton(
                        controller: _controller,
                        attribute: quill.Attribute.subscript,
                        options: const quill.QuillToolbarToggleStyleButtonOptions(iconSize: 20),
                      ),
                      // Superscript
                      quill.QuillToolbarToggleStyleButton(
                        controller: _controller,
                        attribute: quill.Attribute.superscript,
                        options: const quill.QuillToolbarToggleStyleButtonOptions(iconSize: 20),
                      ),

                      const SizedBox(width: 8),

                      // Heading dropdown
                      PopupMenuButton<int>(
                        icon: const Icon(Icons.format_size, size: 20),
                        tooltip: 'text_editor.heading'.tr(),
                        onSelected: (level) {
                          if (level == 0) {
                            _applyHeadingFormat(null);
                          } else {
                            _applyHeadingFormat(level);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<int>(
                            value: 0, // Use 0 instead of null for normal text
                            child: Text('text_editor.normal_text'.tr()),
                          ),
                          PopupMenuItem<int>(
                            value: 1,
                            child: Text('text_editor.heading_1'.tr()),
                          ),
                          PopupMenuItem<int>(
                            value: 2,
                            child: Text('text_editor.heading_2'.tr()),
                          ),
                          PopupMenuItem<int>(
                            value: 3,
                            child: Text('text_editor.heading_3'.tr()),
                          ),
                          PopupMenuItem<int>(
                            value: 4,
                            child: Text('text_editor.heading_4'.tr()),
                          ),
                          PopupMenuItem<int>(
                            value: 5,
                            child: Text('text_editor.heading_5'.tr()),
                          ),
                          PopupMenuItem<int>(
                            value: 6,
                            child: Text('text_editor.heading_6'.tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Rich text editor
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                ),
                child: quill.QuillEditor.basic(
                  controller: _controller,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  config: quill.QuillEditorConfig(
                    padding: const EdgeInsets.all(12),
                    placeholder: 'text_editor.start_writing'.tr(),
                    autoFocus: false,
                    expands: false,
                    scrollable: true,
                    scrollPhysics: const ClampingScrollPhysics(),
                    customStyles: quill.DefaultStyles(
                      paragraph: quill.DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                          height: 1.4,
                        ),
                        quill.HorizontalSpacing.zero,
                        quill.VerticalSpacing.zero,
                        quill.VerticalSpacing.zero,
                        null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  void _applyHeadingFormat(int? level) {
    final selection = _controller.selection;
    
    if (!selection.isValid || selection.baseOffset < 0) {
      return;
    }

    // Get the current selection
    final baseOffset = selection.baseOffset;
    final extentOffset = selection.extentOffset;
    
    // Find line boundaries
    final text = _controller.document.toPlainText();
    
    // Find start of line (go backwards to find last newline or start)
    int lineStart = baseOffset;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    
    // Find end of line (go forwards to find next newline or end)
    int lineEnd = extentOffset;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }
    
    final lineLength = lineEnd - lineStart;
    
    if (lineLength <= 0) {
      return;
    }

    final lineText = text.substring(lineStart, lineEnd);

    if (level == null) {
      // Remove heading formatting by deleting and reinserting as plain text
      // Delete the entire line including newline if present
      final deleteLength = lineEnd < text.length ? lineLength + 1 : lineLength;
      _controller.document.delete(lineStart, deleteLength);
      
      // Insert the plain text back without any attributes
      _controller.document.insert(lineStart, lineText);
      
      // If we deleted a newline, add it back
      if (lineEnd < text.length) {
        _controller.document.insert(lineStart + lineText.length, '\n');
      }
      
      // Update selection
      _controller.updateSelection(
        TextSelection.collapsed(offset: lineStart + lineText.length),
        quill.ChangeSource.local,
      );
    } else {
      // Apply heading formatting based on level
      final headingAttribute = switch (level) {
        1 => quill.Attribute.h1,
        2 => quill.Attribute.h2,
        3 => quill.Attribute.h3,
        4 => quill.Attribute.h4,
        5 => quill.Attribute.h5,
        6 => quill.Attribute.h6,
        _ => quill.Attribute.h1, // fallback
      };
      
      _controller.formatText(
        lineStart,
        lineLength,
        headingAttribute,
      );
    }
    
    // Restore focus to editor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
}