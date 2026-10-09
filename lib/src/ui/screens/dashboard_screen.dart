import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../engine/engine.dart';
import '../../state/career_state.dart';
import '../shared/glass_card.dart';
import '../shared/neon_button.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _tab = 0;
  final _tabs = const ['النظرة العامة', 'الفريق', 'الانتقالات', 'المباريات', 'التكتيك'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(careerControllerProvider);
    final controller = ref.read(careerControllerProvider.notifier);
    final pages = <Widget>[
      _Overview(state: state, controller: controller),
      _SquadPage(state: state, controller: controller),
      _TransfersPage(state: state, controller: controller),
      _FixturesPage(state: state, controller: controller),
      _TacticsPage(controller: controller, onChanged: () => setState(() {})),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('FC CAREER MODE'),
          Text(_tabs[_tab], style: const TextStyle(fontSize: 12, color: AppColors.textLow)),
        ]),
        actions: [
          IconButton(tooltip: 'حفظ المسيرة', onPressed: () async {
            await controller.saveCareer();
            if (mounted) _message('تم حفظ المسيرة بنجاح');
          }, icon: const Icon(Icons.save_outlined)),
          IconButton(tooltip: 'أكاديمية الناشئين', onPressed: () {
            controller.addYouthIntake(); _message('وصلت دفعة جديدة من الناشئين');
          }, icon: const Icon(Icons.school_outlined)),
        ],
      ),
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'الفريق'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), selectedIcon: Icon(Icons.swap_horiz), label: 'الانتقالات'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'المباريات'),
          NavigationDestination(icon: Icon(Icons.tune), selectedIcon: Icon(Icons.tune), label: 'التكتيك'),
        ],
      ),
    );
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _Overview extends StatelessWidget {
  final CareerGameState state;
  final CareerController controller;
  const _Overview({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final upcoming = state.fixtures.where((f) => !f.played && (f.homeClubId == state.playerClub.id || f.awayClubId == state.playerClub.id)).toList()..sort((a, b) => a.matchday.compareTo(b.matchday));
    final Fixture? next = upcoming.isEmpty ? null : upcoming.first;
    final avg = state.squad.isEmpty ? 0 : (state.squad.map((p) => p.overallRating).reduce((a,b) => a+b) / state.squad.length).round();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF183D49), Color(0xFF111D30), Color(0xFF18243B)]),
          border: Border.all(color: AppColors.cyanSky.withValues(alpha: .4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(color: AppColors.electricLime, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.shield, size: 32, color: AppColors.deepNavy)),
            const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(state.playerClub.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), Text('${state.playerClub.division} • الموسم ${state.currentSeason}', style: const TextStyle(color: AppColors.textLow))])),
          ]),
          const SizedBox(height: 24),
          Row(children: [
            _Stat('المركز', '${state.seasonStats.leaguePosition}', Icons.emoji_events_outlined),
            _Stat('النقاط', '${state.seasonStats.pointsTotal}', Icons.bolt_outlined),
            _Stat('قوة الفريق', '$avg', Icons.groups_2_outlined),
          ]),
          const SizedBox(height: 20),
          Row(children: [const Icon(Icons.account_balance_wallet_outlined, color: AppColors.electricLime), const SizedBox(width: 8), const Text('ميزانية الانتقالات', style: TextStyle(color: AppColors.textLow)), const Spacer(), Text(_money(state.playerClub.budget), style: const TextStyle(color: AppColors.electricLime, fontWeight: FontWeight.bold, fontSize: 18))]),
        ]),
      ),
      const SizedBox(height: 16),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle('المباراة القادمة', icon: Icons.stadium_outlined),
        const SizedBox(height: 14),
        if (next == null) const Text('لا توجد مباراة قادمة ضمن جدول فريقك.') else ...[
          Row(children: [Expanded(child: _TeamName(next.homeClubName, isHome: true)), const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('VS', style: TextStyle(color: AppColors.electricLime, fontWeight: FontWeight.w900))), Expanded(child: _TeamName(next.awayClubName, isHome: false))]),
          const SizedBox(height: 12),
          Text('الجولة ${next.matchday} • ${next.homeClubId == state.playerClub.id ? 'على أرضك' : 'خارج أرضك'}', style: const TextStyle(color: AppColors.textLow)),
          const SizedBox(height: 16),
          NeonButton(label: 'العب المباراة', expanded: true, onPressed: () { controller.playNextFixture(); controller.saveCareer(); }),
        ],
      ])),
      const SizedBox(height: 16),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle('ملخص الموسم', icon: Icons.insights_outlined), const SizedBox(height: 14),
        Row(children: [Expanded(child: _SmallMetric('انتصارات', '${state.seasonStats.wins}', const Color(0xFF73E6A0))), Expanded(child: _SmallMetric('تعادلات', '${state.seasonStats.draws}', AppColors.cyanSky)), Expanded(child: _SmallMetric('خسارات', '${state.seasonStats.losses}', AppColors.coralRed))]),
        const SizedBox(height: 18),
        Row(children: [const Text('الأهداف', style: TextStyle(color: AppColors.textLow)), const Spacer(), Text('${state.seasonStats.goalsFor} مسجلة  •  ${state.seasonStats.goalsAgainst} مستقبلة', style: const TextStyle(fontWeight: FontWeight.w600))]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (state.seasonStats.currentForm / 100).clamp(0.0,1.0), minHeight: 9, color: AppColors.electricLime, backgroundColor: AppColors.lightSlate.withValues(alpha: .35))),
        const SizedBox(height: 6), Text('الفورمة الحالية ${state.seasonStats.currentForm}%', style: const TextStyle(color: AppColors.textLow, fontSize: 12)),
      ])),
      const SizedBox(height: 16),
      GlassCard(child: Row(children: [const Icon(Icons.school_outlined, color: AppColors.electricLime, size: 30), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('أكاديمية الناشئين', style: TextStyle(fontWeight: FontWeight.bold)), Text('${state.youth.players.length} لاعب ناشئ • مستوى المنشآت ${state.youth.facilities}', style: const TextStyle(color: AppColors.textLow, fontSize: 12))])), TextButton(onPressed: controller.addYouthIntake, child: const Text('استقطاب'))])),
      if (state.recentMatches.isNotEmpty) ...[
        const SizedBox(height: 16), const _SectionTitle('آخر النتائج', icon: Icons.history), const SizedBox(height: 8),
        ...state.fixtures.where((f) => f.played && (f.homeClubId == state.playerClub.id || f.awayClubId == state.playerClub.id)).take(4).map((f) => _FixtureTile(fixture: f, clubId: state.playerClub.id)),
      ],
    ]);
  }
}

class _SquadPage extends StatelessWidget {
  final CareerGameState state; final CareerController controller;
  const _SquadPage({required this.state, required this.controller});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    _PageBanner(title: 'الفريق الأول', subtitle: '${state.squad.length} لاعب مسجل', icon: Icons.groups_2_outlined),
    const SizedBox(height: 12),
    ...state.squad.map((p) => GlassCard(child: Row(children: [
      Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: _ratingColor(p.overallRating).withValues(alpha: .15), borderRadius: BorderRadius.circular(14)), child: Text('${p.overallRating}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _ratingColor(p.overallRating)))),
      const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${p.firstName} ${p.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('${p.position} • ${p.age} سنة • تطور ${p.potential}', style: const TextStyle(color: AppColors.textLow, fontSize: 12))])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('لياقة ${p.form}%', style: const TextStyle(color: AppColors.cyanSky, fontSize: 11)), const SizedBox(height: 4), TextButton(onPressed: state.squad.length <= 11 ? null : () { final ok = controller.sellPlayer(p); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'تم بيع اللاعب وإضافة المبلغ للميزانية' : 'لا يمكن بيع اللاعب: يجب بقاء 11 لاعباً على الأقل'))); }, child: const Text('بيع'))]),
    ]))),
  ]);
}

class _TransfersPage extends StatelessWidget {
  final CareerGameState state; final CareerController controller;
  const _TransfersPage({required this.state, required this.controller});
  @override
  Widget build(BuildContext context) {
    final targets = List<CareerPlayer>.generate(8, (i) => CareerPlayer(
      id: 9000 + i, firstName: ['Jamal','Theo','Rayan','Victor','Samir','Enzo','Milan','Yusuf'][i],
      lastName: ['Haddad','Brooks','Nasser','Costa','Ali','Moretti','Petrov','Karim'][i], age: 18 + i % 8,
      position: ['FWD','MID','DEF','GK','MID','FWD','DEF','MID'][i], overallRating: 68 + i * 2,
      potential: 82 + i * 2, pace: 70 + i, shooting: 68 + i, passing: 70 + i,
      dribbling: 71 + i, defense: 60 + i, physical: 67 + i, morale: 75, form: 70,
      contractEndYear: DateTime.now().year + 3, injuryWeeks: 0, isYouthPlayer: false,
    ));
    return ListView(padding: const EdgeInsets.all(16), children: [
      _PageBanner(title: 'سوق الانتقالات', subtitle: 'ميزانيتك ${_money(state.playerClub.budget)}', icon: Icons.swap_horiz),
      const SizedBox(height: 10),
      const Text('أهداف مقترحة • رسوم الانتقال تقديرية', style: TextStyle(color: AppColors.textLow)),
      const SizedBox(height: 10),
      ...targets.map((p) {
        final fee = p.overallRating * p.overallRating * 650.0;
        final owned = state.squad.any((x) => x.id == p.id);
        return GlassCard(child: Row(children: [Container(width: 46, height: 46, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.cyanSky.withValues(alpha: .15), borderRadius: BorderRadius.circular(13)), child: Text('${p.overallRating}', style: const TextStyle(color: AppColors.cyanSky, fontWeight: FontWeight.bold))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${p.firstName} ${p.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)), Text('${p.position} • ${p.age} سنة • إمكانات ${p.potential}', style: const TextStyle(color: AppColors.textLow, fontSize: 12)), Text(_money(fee), style: const TextStyle(color: AppColors.electricLime, fontSize: 12, fontWeight: FontWeight.bold))])), ElevatedButton(onPressed: owned || state.playerClub.budget < fee ? null : () { final ok = controller.signPlayer(p, fee); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'تم التعاقد مع ${p.firstName} ${p.lastName}' : 'الميزانية لا تكفي'))); }, child: Text(owned ? 'متعاقد' : 'شراء'))]));
      }),
      const SizedBox(height: 8), const Text('ملاحظة: قائمة اللاعبين المقترحين تجريبية داخل اللعبة وليست قاعدة بيانات لاعبين حقيقية.', style: TextStyle(color: AppColors.textLow, fontSize: 12)),
    ]);
  }
}

class _FixturesPage extends StatelessWidget {
  final CareerGameState state; final CareerController controller;
  const _FixturesPage({required this.state, required this.controller});
  @override
  Widget build(BuildContext context) {
    final fixtures = state.fixtures.where((f) => f.homeClubId == state.playerClub.id || f.awayClubId == state.playerClub.id).toList()..sort((a,b) => a.matchday.compareTo(b.matchday));
    final upcoming = fixtures.where((f) => !f.played).toList();
    final nextId = upcoming.isEmpty ? -1 : upcoming.first.id;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _PageBanner(title: 'جدول المباريات', subtitle: '${fixtures.where((f) => f.played).length} من ${fixtures.length} مباريات مكتملة', icon: Icons.calendar_month_outlined),
      const SizedBox(height: 12),
      ...fixtures.map((f) => _FixtureTile(fixture: f, clubId: state.playerClub.id, onPlay: f.played || f.id != nextId ? null : () { controller.playNextFixture(); controller.saveCareer(); })),
    ]);
  }
}

class _TacticsPage extends StatefulWidget {
  final CareerController controller; final VoidCallback onChanged;
  const _TacticsPage({required this.controller, required this.onChanged});
  @override
  State<_TacticsPage> createState() => _TacticsPageState();
}
class _TacticsPageState extends State<_TacticsPage> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const _PageBanner(title: 'غرفة التكتيك', subtitle: 'جهّز أسلوب لعب فريقك قبل المباراة', icon: Icons.tune),
      const SizedBox(height: 14),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle('خطة اللعب', icon: Icons.sports_soccer), const SizedBox(height: 12),
        _choice<String>('التشكيلة', c.formation, const ['4-3-3','4-2-3-1','4-4-2','3-5-2','5-3-2'], (v) => setState(() { c.setTactics(newFormation: v); widget.onChanged(); })),
        const SizedBox(height: 14), _choice<String>('العقلية', c.mentality, const ['متوازن','هجومي','دفاعي','استحواذ'], (v) => setState(() { c.setTactics(newMentality: v); widget.onChanged(); })),
        const SizedBox(height: 14), _choice<String>('الضغط', c.pressing, const ['منخفض','متوسط','عالٍ'], (v) => setState(() { c.setTactics(newPressing: v); widget.onChanged(); })),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.deepNavy, borderRadius: BorderRadius.circular(16)), child: Column(children: [
          const Text('التشكيلة الأساسية', style: TextStyle(color: AppColors.textLow)), const SizedBox(height: 12),
          _pitchLine(['LW','ST','RW']), _pitchLine(c.formation == '4-4-2' ? ['LM','CM','CM','RM'] : ['LM','CM','CM','RM']), _pitchLine(['LB','CB','CB','RB']), _pitchLine(['GK']),
        ])),
        const SizedBox(height: 10), const Text('تؤثر الاختيارات على إعدادات المحاكاة القادمة. هذه معاينة تكتيكية مبسطة وليست ملعباً ثلاثي الأبعاد.', style: TextStyle(color: AppColors.textLow, fontSize: 12)),
      ])),
      const SizedBox(height: 12), NeonButton(label: 'حفظ التكتيك', expanded: true, onPressed: () async { await c.saveCareer(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المسيرة؛ التشكيلة والتكتيك جاهزان للمباراة القادمة'))); }),
    ]);
  }
  Widget _choice<T>(String label, T value, List<T> options, ValueChanged<T> onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), DropdownButtonFormField<T>(initialValue: value, isExpanded: true, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)), items: options.map((v) => DropdownMenuItem<T>(value: v, child: Text('$v'))).toList(), onChanged: (v) { if (v != null) onChanged(v); })]);
  Widget _pitchLine(List<String> labels) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: labels.map((label) => Container(width: 44, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.electricLime.withValues(alpha: .16), border: Border.all(color: AppColors.electricLime.withValues(alpha: .7)), borderRadius: BorderRadius.circular(18)), child: Text(label, style: const TextStyle(color: AppColors.electricLime, fontWeight: FontWeight.bold, fontSize: 11)))).toList()));
}

class _FixtureTile extends StatelessWidget {
  final Fixture fixture; final int clubId; final VoidCallback? onPlay;
  const _FixtureTile({required this.fixture, required this.clubId, this.onPlay});
  @override
  Widget build(BuildContext context) {
    final isHome = fixture.homeClubId == clubId;
    final score = fixture.result;
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassCard(child: Row(children: [Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.cyanSky.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Text('${fixture.matchday}', style: const TextStyle(color: AppColors.cyanSky, fontWeight: FontWeight.bold))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${fixture.homeClubName}  -  ${fixture.awayClubName}', style: const TextStyle(fontWeight: FontWeight.w700)), Text('الجولة ${fixture.matchday} • ${isHome ? 'ملعبك' : 'خارج ملعبك'}', style: const TextStyle(color: AppColors.textLow, fontSize: 12))])), if (score != null) Text('${score.homeScore} : ${score.awayScore}', style: const TextStyle(color: AppColors.electricLime, fontWeight: FontWeight.w900, fontSize: 18)) else if (onPlay != null) IconButton(tooltip: 'العب المباراة القادمة', onPressed: onPlay, icon: const Icon(Icons.play_circle_fill, color: AppColors.electricLime)) else const Icon(Icons.schedule, color: AppColors.textLow)])));
  }
}

class _PageBanner extends StatelessWidget {
  final String title, subtitle; final IconData icon;
  const _PageBanner({required this.title, required this.subtitle, required this.icon});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF173C48), Color(0xFF18233A)]), border: Border.all(color: AppColors.cyanSky.withValues(alpha: .25))), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.electricLime, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.deepNavy, size: 27)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: AppColors.textLow, fontSize: 12))]))]));
}

class _SectionTitle extends StatelessWidget {
  final String title; final IconData icon;
  const _SectionTitle(this.title, {required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, color: AppColors.cyanSky, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: AppColors.textHigh, fontWeight: FontWeight.w800, fontSize: 16))]);
}
class _Stat extends StatelessWidget {
  final String label, value; final IconData icon;
  const _Stat(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .04), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppColors.electricLime, size: 18), const SizedBox(height: 10), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)), Text(label, style: const TextStyle(color: AppColors.textLow, fontSize: 11))])));
}
class _SmallMetric extends StatelessWidget {
  final String label, value; final Color color;
  const _SmallMetric(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: AppColors.textLow, fontSize: 12))]);
}
class _TeamName extends StatelessWidget {
  final String name; final bool isHome;
  const _TeamName(this.name, {required this.isHome});
  @override
  Widget build(BuildContext context) => Column(children: [CircleAvatar(radius: 24, backgroundColor: isHome ? AppColors.electricLime : AppColors.cyanSky, child: Icon(Icons.shield, color: AppColors.deepNavy, size: 27)), const SizedBox(height: 8), Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]);
}
Color _ratingColor(int rating) => rating >= 82 ? const Color(0xFF73E6A0) : rating >= 74 ? AppColors.electricLime : AppColors.cyanSky;
String _money(double amount) { if (amount >= 1000000) return '€${(amount / 1000000).toStringAsFixed(1)}M'; if (amount >= 1000) return '€${(amount / 1000).toStringAsFixed(0)}K'; return '€${amount.toStringAsFixed(0)}'; }
