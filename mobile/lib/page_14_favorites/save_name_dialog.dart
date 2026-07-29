import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Save Name Pop-up — Page 14
// Prompts for the name a saved look will be shown under in Favorites.
// Reused for renaming an existing saved result — pass [initialName]
// and it becomes excluded from the duplicate-name check.
// ─────────────────────────────────────────────────────────────

class SaveNameDialog extends StatefulWidget {
  final List<String> existingNames;
  final String? initialName;

  const SaveNameDialog({
    super.key,
    required this.existingNames,
    this.initialName,
  });

  @override
  State<SaveNameDialog> createState() => _SaveNameDialogState();
}

class _SaveNameDialogState extends State<SaveNameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Please enter a name');
      return;
    }

    final initialLower = (widget.initialName ?? '').toLowerCase();
    final isDuplicate = widget.existingNames.any((existing) =>
        existing.toLowerCase() == name.toLowerCase() &&
        existing.toLowerCase() != initialLower);
    if (isDuplicate) {
      setState(() =>
          _errorText = 'You already have a saved look with this name');
      return;
    }

    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;
    final isRename = widget.initialName != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(contentWidth * 0.07),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRename ? 'Rename this look' : 'Name this look',
              style: TextStyle(
                fontSize: contentWidth * 0.055,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: contentWidth * 0.02),

            Text(
              'Give it a name so you can find it later.',
              style: TextStyle(
                fontSize: contentWidth * 0.035,
                color: Colors.black54,
              ),
            ),

            SizedBox(height: contentWidth * 0.05),

            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'e.g. Date Night',
                errorText: _errorText,
                filled: true,
                fillColor: const Color(0xFFFFF0F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: contentWidth * 0.04,
                  vertical: contentWidth * 0.035,
                ),
              ),
            ),

            SizedBox(height: contentWidth * 0.06),

            SizedBox(
              width: double.infinity,
              height: contentWidth * 0.13,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6EB4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: contentWidth * 0.045,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: contentWidth * 0.015),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: contentWidth * 0.038,
                    color: Colors.grey,
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
