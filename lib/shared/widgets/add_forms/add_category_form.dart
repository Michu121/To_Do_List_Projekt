import 'package:flutter/material.dart';
import 'package:todo_list/shared/services/category_services.dart';

import '../../models/category.dart';
import '../../models/colors.dart'; // Added to support ColorsToPick
import '../../services/color_services.dart';
import '../pickers/color_picker.dart';

class CategoryOverlay {
  static OverlayEntry? _overlayEntry;
  static AnimationController? _animationController;

  static void show(BuildContext context,{Category? cat}) {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);

    _animationController = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 300),
    );

    final slideTransition = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: hide,
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height * 0.15, // Adjusted top offset
            width: MediaQuery.of(context).size.width * 0.85,
            child: SlideTransition(
              position: slideTransition,
              child: Material(
                elevation: 10,
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16), // Added for a cleaner look
                ),
                child: _CategoryFormContent(cat: cat),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    _animationController!.forward();
  }

  static Future<void> hide() async {
    if (_overlayEntry == null) return;
    await _animationController?.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _animationController?.dispose();
    _animationController = null;
  }
}

// Extracted into a StatefulWidget to handle text input and color selection state
class _CategoryFormContent extends StatefulWidget {
  final Category? cat;
  const _CategoryFormContent({this.cat});

  @override
  State<_CategoryFormContent> createState() => _CategoryFormContentState();
}

class _CategoryFormContentState extends State<_CategoryFormContent> {
  final _colorServices = ColorServices();
  final _nameController = TextEditingController();

  ColorsToPick? _selectedColor;
  String? _nameError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = _colorServices.getColors().values.firstOrNull;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty');
      return;
    }

    setState(() => _saving = true);

    categoryServices.addCategory(Category(name: name, color: _selectedColor!.color));

    setState(() => _saving = false);

    CategoryOverlay.hide();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.cat != null) {
      _nameController.text = widget.cat!.name;
      if (_selectedColor !=  _colorServices.getColors().values.first) {
        String selectedColorName = _colorServices.getColors().keys.firstWhere((key) => _colorServices.getColors()[key]!.color == widget.cat!.color);
        _colorServices.updateColor(selectedColorName, true);
      }
    } else {
      _nameController.text = "";
      _selectedColor = _colorServices.getColors().values.first;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Vital for automatic height
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Name',
              border: const OutlineInputBorder(),
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Color',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          ColorPicker(
            colorServices: _colorServices,
            selectedColor: _selectedColor,
            onTap: (name) {
              setState(() {
                _colorServices.updateColor(name, true);
                _selectedColor = _colorServices.getColors()[name];
              });
            },
          ),
          // Use a fixed margin instead of Spacer()
          const SizedBox(height: 32),
          ValueListenableBuilder(
            valueListenable: _nameController,
            builder: (context, value, child) {
              return SizedBox(
                width: double.infinity,
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _selectedColor!.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(_nameController.text.isEmpty ? "Podgląd": _nameController.text, style: TextStyle(color: _selectedColor!.color.computeLuminance() > 0.5 ? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis)),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _saving ? null : _handleSave,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: _saving
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Add', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ],
      ),
    );
  }
}