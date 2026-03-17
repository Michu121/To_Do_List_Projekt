import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../notifiers/rotate_notifier.dart';

class GroupPicker extends StatefulWidget {
  const GroupPicker({
    super.key,
    required this.groups,
    required this.onChanged,
    required this.selected,
  });
  final Group? selected;
  final List<Group> groups;
  final ValueChanged<Group?> onChanged;


  @override
  State<GroupPicker> createState() => _GroupPickerState();

}

class _GroupPickerState extends State<GroupPicker> {
  bool rotate = false;
  final rotateNotifier = RotateNotifier();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Groups", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          InkWell(
            onTap: (){
              _showPicker(context);
              setState(() {
                rotateNotifier.changeValue(true);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).cardColor
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: widget.selected?.color ?? Colors.grey.shade400, radius: 8),
                      const SizedBox(width: 10),
                      Text(widget.selected!.name, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  ValueListenableBuilder(
                      valueListenable: rotateNotifier,
                      builder: (context, value, child) {
                        return AnimatedRotation(
                          turns: value ? -0.5 : -1,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(Icons.arrow_drop_down),
                        );
                      }
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    // 1. Chowa klawiaturę, żeby zwolnić miejsce
    FocusScope.of(context).unfocus();

    // 2. Pokazuje menu jako mały "Dialog" pod spodem lub nad klawiaturą
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.all(10),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 170),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.groups.length,
              itemBuilder: (context, index) {
                final grp = widget.groups[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: grp == widget.selected ? grp.color : Colors.grey.shade200
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: grp == widget.selected? grp.color.withValues(alpha:0.2) : Colors.transparent,
                              blurRadius: 6,
                              spreadRadius: 1
                          )
                        ]
                    ),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: grp.color, radius: 8),
                      title: Text(grp.name),
                      onTap: () {
                        setState(() {
                          rotateNotifier.changeValue(false);
                        });
                        widget.onChanged(grp);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ).then((_) => setState(() {
      rotateNotifier.changeValue(false);
    }));
  }
}
