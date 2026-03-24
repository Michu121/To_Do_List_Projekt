import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../shared/models/group.dart';
import '../shared/models/task.dart';
import '../shared/services/every_task_service.dart';
import '../shared/services/group_task_service.dart';
import '../shared/widgets/add_forms/add_task_form.dart';
import '../shared/widgets/category/date_section.dart';
import '../shared/widgets/task_tiles/task_list_tile.dart';

extension _DateX on DateTime {
  DateTime get monthStart => DateTime(year, month);

  DateTime get dayStart => DateTime(year, month, day);

  DateTime addMonth(int n) => DateTime(year, month + n);

  bool sameDay(DateTime o) =>
      year == o.year && month == o.month && day == o.day;

  bool get isToday => sameDay(DateTime.now());
}

// ─────────────────────────────────────────────────────────────────────────────

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final onAccent = accent.computeLuminance() > 0.4
        ? Colors.black87
        : Colors.white;

    return Column(
      children: [
        // ── Tab bar (part of app chrome) ──────────────────────────
        Container(
          color: theme.appBarTheme.backgroundColor,
          child: TabBar(
            controller: _tabs,
            labelColor: onAccent,
            unselectedLabelColor: onAccent.withValues(alpha: 0.5),
            indicatorColor: onAccent,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            // Tłumaczenia menu głównego
            tabs: [
              const Tab(text: 'AGENDA', icon: Icon(Icons.list_alt, size: 16)), // Brak w ARB
              Tab(text: t?.calendar?.toUpperCase() ?? 'CALENDAR', icon: const Icon(Icons.calendar_month, size: 16)),
              Tab(text: t?.group?.toUpperCase() ?? 'GROUPS', icon: const Icon(Icons.group, size: 16)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [_AgendaTab(), _CalendarTab(), _GroupsTab()],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AGENDA — all tasks sorted soonest first
// ═══════════════════════════════════════════════════════════════════════════════

class _AgendaTab extends StatelessWidget {
  const _AgendaTab();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: everyTaskService,
      builder: (_, __) {
        final tasks = [...everyTaskService.getTasks()]
          ..sort((a, b) => a.date.compareTo(b.date));

        if (tasks.isEmpty) {
          return _EmptyHint(
            icon: Icons.event_note,
            message: t?.noUpcomingTasks ?? 'No upcoming tasks',
          );
        }

        final sections = groupTasksByDate(tasks);
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: sections.length + 1,
          itemBuilder: (_, i) {
            if (i == sections.length) return const SizedBox(height: 80);
            return DateSection(
              label: sections[i].label,
              tasks: sections[i].tasks,
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CALENDAR — grid + selected-day tasks + add FAB
// ═══════════════════════════════════════════════════════════════════════════════

class _CalendarTab extends StatefulWidget {
  const _CalendarTab();

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  late DateTime _month;
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    _month = DateTime.now().monthStart;
    _day = DateTime.now().dayStart;
  }

  Map<DateTime, List<Task>> _byDate(List<Task> tasks) {
    final m = <DateTime, List<Task>>{};
    for (final t in tasks) {
      m.putIfAbsent(t.date.dayStart, () => []).add(t);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: everyTaskService,
      builder: (_, _) {
        final tasks = everyTaskService.getTasks();
        final byDate = _byDate(tasks);
        final dayTasks = byDate[_day] ?? [];

        return Stack(
          children: [
            Column( // Zamiast SingleChildScrollView (zgodnie z instrukcją)
              children: [
                // ── Sekcja Kalendarza (Stała wysokość lub AspectRatio) ──
                _CompactMonthHeader(
                  month: _month,
                  day: _day,
                  onChange: (m) => setState(() => _month = m),
                ),
                _WeekdayRow(),

                // Nadajemy siatce stałą wysokość, aby się wyświetliła
                SizedBox(
                  height: 260, // Dostosowana wysokość
                  child: _Grid(
                    month: _month,
                    selected: _day,
                    byDate: byDate,
                    onSelect: (d) => setState(() => _day = d),
                  ),
                ),

                Divider(height: 1, color: Theme.of(context).dividerColor),

                // ── Sekcja Listy Zadań (Zajmuje resztę miejsca) ──
                Expanded(
                  child: _DayList(day: _day, tasks: dayTasks),
                ),
              ],
            ),

            // FAB zgodnie z instrukcją
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'cal_fab',
                onPressed: () => AddTaskSheet.show(context, preselectedDate: _day),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Compact month header ──────────────────────────────────────────────────────

class _CompactMonthHeader extends StatelessWidget {
  const _CompactMonthHeader({
    required this.month,
    required this.day,
    required this.onChange,
  });

  final DateTime month;
  final DateTime day;
  final ValueChanged<DateTime> onChange;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    final List<String> monthsList = [
      t?.january(0) ?? 'January',
      t?.february(0) ?? 'February',
      t?.march(0) ?? 'March',
      t?.april(0) ?? 'April',
      t?.may(0) ?? 'May',
      t?.june(0) ?? 'June',
      t?.july(0) ?? 'July',
      t?.august(0) ?? 'August',
      t?.september(0) ?? 'September',
      t?.october(0) ?? 'October',
      t?.november(0) ?? 'November',
      t?.december(0) ?? 'December',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () => onChange(month.addMonth(-1)),
            icon: Icon(Icons.chevron_left, color: accent),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${monthsList[month.month - 1]} ${month.year}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${day.day} ${monthsList[day.month - 1]}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () => onChange(month.addMonth(1)),
            icon: Icon(Icons.chevron_right, color: accent),
          ),
        ],
      ),
    );
  }
}

// ── Weekday row ───────────────────────────────────────────────────────────────

class _WeekdayRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [t?.monday(0)??"Mo", t?.tuesday(0)??"Tu", t?.wednesday(0)??"We", t?.thursday(0)??"Th", t?.friday(0)??"Fr", t?.saturday(0)??"Sa", t?.sunday(0)??"Su"]
            .map(
              (d) => SizedBox(
            width: 36,
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}

// ── Calendar grid ─────────────────────────────────────────────────────────────

class _Grid extends StatelessWidget {
  const _Grid({
    required this.month,
    required this.selected,
    required this.byDate,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Map<DateTime, List<Task>> byDate;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final data = _MonthData(month.year, month.month);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: data.weeksList.map((week) {
          return Expanded(
            child: Row(
              children: week.map((day) {
                return Expanded(
                  child: _DayCell(
                    date: day.date,
                    active: day.activeMonth,
                    selected: selected.sameDay(day.date),
                    tasks: byDate[day.date] ?? [],
                    onTap: () => onSelect(day.date),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.active,
    required this.selected,
    required this.tasks,
    required this.onTap,
  });

  final DateTime date;
  final bool active;
  final bool selected;
  final List<Task> tasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isToday = date.isToday;

    final Color? bg = selected ? accent : null;
    final Color fg = selected
        ? (accent.computeLuminance() > 0.4 ? Colors.black87 : Colors.white)
        : isToday
        ? accent
        : !active
        ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);

    final dots = tasks
        .map((t) {
      if (t.status.index == 2) return Colors.green;
      if (t.status.index == 1) return Colors.blueAccent;
      return theme.colorScheme.onSurface.withValues(alpha: 0.4);
    })
        .toSet()
        .take(3)
        .toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: isToday && !selected
              ? Border.all(color: accent, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday || selected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: fg,
              ),
            ),
            if (dots.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dots
                    .map(
                      (c) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: selected ? fg.withValues(alpha: 0.75) : c,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
                    .toList(),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ── Day task list ─────────────────────────────────────────────────────────────

class _DayList extends StatelessWidget {
  const _DayList({required this.day, required this.tasks});

  final DateTime day;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 44,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 8),
            Text(
              t?.noUpcomingTasks ?? 'No tasks on this day',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
          child: Text(
            '${tasks.length} ${t?.tasks ?? 'tasks'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent.withValues(alpha: 0.75),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            // Bottom padding = FAB height so last task isn't hidden
            padding: const EdgeInsets.only(bottom: 80),
            children: tasks.map((t) => TaskListTile(task: t)).toList(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GROUPS — collapsible sections per group
// ═══════════════════════════════════════════════════════════════════════════════

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: groupTaskService,
      builder: (_, __) {
        final groups = groupTaskService.groups;
        if (groups.isEmpty) {
          return _EmptyHint(
            icon: Icons.group_off,
            message: '${t?.noGroups ?? "No groups yet."}\n${t?.createOrJoinGroup ?? "Create or join one!"}',
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: groups.length,
          itemBuilder: (_, i) => _GroupSection(group: groups[i]),
        );
      },
    );
  }
}

class _GroupSection extends StatefulWidget {
  const _GroupSection({required this.group});

  final Group group;

  @override
  State<_GroupSection> createState() => _GroupSectionState();
}

class _GroupSectionState extends State<_GroupSection> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tasks = groupTaskService.tasksForGroup(widget.group.id).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.group.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.group.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: widget.group.color,
                  child: Text(
                    widget.group.name.isNotEmpty
                        ? widget.group.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: widget.group.color.computeLuminance() > 0.4
                          ? Colors.black87
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${tasks.length} ${t?.tasks ?? 'tasks'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more, color: widget.group.color),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _open
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: tasks.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            child: Text(
              t?.noGroupTasks ?? 'No tasks in this group',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          )
              : Column(
            children: tasks
                .map((t) => TaskListTile(task: t, showGroup: false))
                .toList(),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Empty hint ────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 58,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Month data helper ─────────────────────────────────────────────────────────

class _MonthData {
  final int year;
  final int month;

  const _MonthData(this.year, this.month);

  int get days => DateUtils.getDaysInMonth(year, month);

  int get offset => DateTime(year, month, 1).weekday - 1;

  int get weeks => ((days + offset) / 7).ceil();

  List<List<_DayData>> get weekList {
    final res = <List<_DayData>>[];
    var first = DateTime(year, month, 1).subtract(Duration(days: offset));
    for (var w = 0; w < weeks; w++) {
      res.add(
        List.generate(7, (i) {
          final d = first.add(Duration(days: i)).dayStart;
          return _DayData(d, d.year == year && d.month == month);
        }),
      );
      first = first.add(const Duration(days: 7));
    }
    return res;
  }

  List<List<_DayData>> get weeksList => weekList;
}

class _DayData {
  final DateTime date;
  final bool activeMonth;

  const _DayData(this.date, this.activeMonth);
}