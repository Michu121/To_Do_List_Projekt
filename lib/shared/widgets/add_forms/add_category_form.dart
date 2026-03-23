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
            onTap: () => hide(),
            child: Container(color: Colors.black.withAlpha(102)), // 0.4 * 255
          ),
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height * 0.2,
            width: MediaQuery.of(context).size.width * 0.85,
            child: SlideTransition(
              position: slideTransition,
              child: Dismissible(
                key: const Key('category_dismissible'),
                direction: DismissDirection.startToEnd,
                onDismissed: (_) => hide(withAnimation: false),
                child: IntrinsicHeight(
                  child: Material(
                    elevation: 20,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                    child: _CategoryFormContent(cat: cat),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    _animationController!.forward();
  }

  static Future<void> hide({bool withAnimation = true}) async {
    if (_overlayEntry == null) return;
    if (withAnimation) {
      await _animationController?.reverse();
    }
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
  // Sprawdzamy, czy edytujemy kategorię systemową, której nie wolno zmieniać/usuwać
  bool get _isDefault => widget.cat?.name == 'Default';

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.cat!.name;
      // Znajdź kolor w pickerze odpowiadający kolorowi kategorii
      final colorsMap = _colorServices.getColors();
      final matchedKey = colorsMap.keys.firstWhere(
            (key) => colorsMap[key]!.color.value == widget.cat!.color.value,
        orElse: () => colorsMap.keys.first,
      );
      _colorServices.updateColor(matchedKey, true);
      _selectedColor = colorsMap[matchedKey];
    } else {
      _selectedColor = _colorServices.getColors().values.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave({bool add = false, bool del = false}) async {
    final name = _nameController.text.trim();

    if (!del && name.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty');
      return;
    }

    setState(() => _saving = true);

    try {
      if (del) {
        // Usuwamy po nazwie (zgodnie z nowym CategoryServices)
        await categoryServices.deleteCategory(widget.cat!.name);
      } else if (add) {
        if (_isEditing) {
          // AKTUALIZACJA: Przekazujemy to samo ID, ale nową nazwę i kolor
          await categoryServices.updateCategory(Category(
              id: widget.cat!.id,
              name: name,
              color: _selectedColor!.color
          ));
        } else {
          // DODAWANIE: Tworzymy nową kategorię (ID wygeneruje się samo w modelu)
          await categoryServices.addCategory(Category(
              name: name,
              color: _selectedColor!.color
          ));
        }
      }
    } catch (e) {
      debugPrint("Błąd zapisu kategorii: $e");
    }

    if (mounted) {
      setState(() => _saving = false);
      CategoryOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 24, 20, 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? (_isDefault ? 'View Category' : 'Edit Category') : 'New Category',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  enabled: !_isDefault, // Blokada edycji nazwy dla Default
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    errorText: _nameError,
                  ),
                ),
                const SizedBox(height: 20),
                if (!_isDefault) // Ukryj picker kolorów dla kategorii Default
                  ColorPicker(
                    colorServices: _colorServices,
                    selectedColor: _selectedColor,
                    onTap: (colorName) {
                      setState(() {
                        _colorServices.updateColor(colorName, true);
                        _selectedColor = _colorServices.getColors()[colorName];
                      });
                    },
                  ),
                const SizedBox(height: 30),
                if (!_isDefault)
                  _buildActionButtons(theme, _selectedColor?.color ?? Colors.grey)
                else
                  _buildCloseButton(theme),

                if (_isEditing && !_isDefault) ...[
                  const SizedBox(height: 10),
                  _buildDeleteButton(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, Color previewColor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 45,
            decoration: BoxDecoration(
                color: previewColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: previewColor)
            ),
            alignment: Alignment.center,
            child: Text(
              _nameController.text.isEmpty ? 'Preview' : _nameController.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: previewColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: _saving ? null : () => _handleSave(add: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_isEditing ? 'Update' : 'Add'),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: () => CategoryOverlay.hide(),
        child: const Text('Close'),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton(
        onPressed: _saving ? null : () => _handleSave(del: true),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Delete Category'),
      ),
    );
  }
}