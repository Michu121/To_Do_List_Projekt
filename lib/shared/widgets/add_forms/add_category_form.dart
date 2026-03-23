import 'package:flutter/material.dart';
import 'package:todo_list/shared/services/category_services.dart';

import '../../models/category.dart';
import '../../models/colors.dart';
import '../../services/color_services.dart';
import '../pickers/color_picker.dart';

class CategoryOverlay {
  static OverlayEntry? _overlayEntry;
  static AnimationController? _animationController;

  static void show(BuildContext context, {Category? cat}) {
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
        CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut));

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: hide,
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height * 0.15,
            width: MediaQuery.of(context).size.width * 0.85,
            child: SlideTransition(
              position: slideTransition,
              child: Material(
                elevation: 10,
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
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

  bool get _isEditing => widget.cat != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.cat!.name;
      // orElse prevents "Bad state: No element" when the stored colour doesn't
      // match any palette entry exactly.
      final matchedKey = _colorServices.getColors().keys.firstWhere(
            (key) => _colorServices.getColors()[key]!.color == widget.cat!.color,
        orElse: () => _colorServices.getColors().keys.first,
      );
      _colorServices.updateColor(matchedKey, true);
    }
    _selectedColor = _colorServices.getColors().values.firstOrNull;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave({bool add = false, bool del = false}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty');
      return;
    }

    setState(() => _saving = true);

    if (add) {
      if (_isEditing) {
        await categoryServices.updateCategory(
          Category(
              id: widget.cat!.id, name: name, color: _selectedColor!.color),
        );
      } else {
        await categoryServices
            .addCategory(Category(name: name, color: _selectedColor!.color));
      }
    } else if (_isEditing && del) {
      // Delete by original name, not the (possibly edited) field value.
      await categoryServices.deleteCategory(widget.cat!.name);
    }

    setState(() => _saving = false);
    CategoryOverlay.hide();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text('Color',
              style:
              TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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
          const SizedBox(height: 32),
          ListenableBuilder(
            listenable: _colorServices,
            builder: (context, _) => ValueListenableBuilder(
              valueListenable: _nameController,
              builder: (context, _, __) {
                final previewColor = _selectedColor?.color ?? Colors.grey;
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Row(
                    children: [
                      // Live preview chip
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: previewColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            _nameController.text.isEmpty
                                ? 'Preview'
                                : _nameController.text,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: previewColor.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      // Save / Update button
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _saving
                                ? null
                                : () => _handleSave(add: true),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: _saving
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                                  : Text(
                                _isEditing ? 'Update' : 'Add',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _saving ? null : () => _handleSave(del: true),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Delete',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}