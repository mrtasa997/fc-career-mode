import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/engine.dart';

const _saveKey = 'fc_career_mode_save_v1';
final careerControllerProvider =
    NotifierProvider<CareerController, CareerGameState>(CareerController.new);

class CareerController extends Notifier<CareerGameState> {
  final CareerEngine _engine = CareerEngine(MatchSimulator(Random()));
  bool _restoring = false;
  String formation = '4-3-3';
  String mentality = 'متوازن';
  String pressing = 'متوسط';

  @override
  CareerGameState build() {
    final initial = _createDefaultState();
    Future<void>.microtask(_restoreSave);
    return initial;
  }

  Future<void> _restoreSave() async {
    if (_restoring) return;
    _restoring = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      formation = prefs.getString('fc_tactics_formation') ?? formation;
      mentality = prefs.getString('fc_tactics_mentality') ?? mentality;
      pressing = prefs.getString('fc_tactics_pressing') ?? pressing;
      final raw = prefs.getString(_saveKey);
      if (raw != null && raw.isNotEmpty) {
        state = CareerGameState.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Ignore a corrupt/old save and start a clean career instead.
    }
  }

  Future<void> saveCareer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode(state.toJson()));
    await prefs.setString('fc_tactics_formation', formation);
    await prefs.setString('fc_tactics_mentality', mentality);
    await prefs.setString('fc_tactics_pressing', pressing);
  }

  Future<void> resetCareer() async {
    state = _createDefaultState();
    formation = '4-3-3';
    mentality = 'متوازن';
    pressing = 'متوسط';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
    await prefs.remove('fc_tactics_formation');
    await prefs.remove('fc_tactics_mentality');
    await prefs.remove('fc_tactics_pressing');
  }

  void setTactics({String? newFormation, String? newMentality, String? newPressing}) {
    formation = newFormation ?? formation;
    mentality = newMentality ?? mentality;
    pressing = newPressing ?? pressing;
  }

  void playNextFixture() {
    Fixture? fixture;
    for (final candidate in state.fixtures) {
      if (!candidate.played && (candidate.homeClubId == state.playerClub.id || candidate.awayClubId == state.playerClub.id)) { fixture = candidate; break; }
    }
    if (fixture == null) return;
    final playerClub = state.playerClub;
    final homePlayers = fixture.homeClubId == playerClub.id
        ? state.squad : _opponentPlayers(fixture.homeClubName);
    final awayPlayers = fixture.awayClubId == playerClub.id
        ? state.squad : _opponentPlayers(fixture.awayClubName);
    final parts = formation.split('-').map((v) => int.tryParse(v) ?? 0).toList();
    final defenders = parts.isNotEmpty ? parts[0] : 4;
    final midfielders = parts.length > 1 ? parts[1] : 3;
    final forwards = parts.length > 2 ? parts[2] : 3;
    final setupFormation = Formation(
      formationCode: formation,
      defenders: defenders,
      midfielders: midfielders,
      forwards: forwards,
      style: mentality,
      pressing: pressing,
      buildUp: mentality == 'استحواذ' ? 'Short passing' : 'Balanced',
    );
    final home = TeamSetup(
      clubId: fixture.homeClubId, clubName: fixture.homeClubName,
      players: _teamPlayers(homePlayers), formation: setupFormation, morale: 78,
    );
    final away = TeamSetup(
      clubId: fixture.awayClubId, clubName: fixture.awayClubName,
      players: _teamPlayers(awayPlayers), formation: setupFormation, morale: 74,
    );
    state = _engine.playFixture(state, fixture, home, away);
    saveCareer();
  }

  void addYouthIntake() {
    final intake = _engine.generateYouthIntake(
      count: 3, startingId: 1000 + state.youth.players.length,
      random: Random(state.currentMatchday + state.youth.players.length),
    );
    state = state.copyWith(youth: state.youth.copyWith(
      players: [...state.youth.players, ...intake],
    ));
    saveCareer();
  }

  bool signPlayer(CareerPlayer player, double fee) {
    if (state.playerClub.budget < fee) return false;
    if (state.squad.any((p) => p.id == player.id)) return false;
    final updatedClub = state.playerClub.copyWith(
      budget: state.playerClub.budget - fee,
      players: [...state.playerClub.players, player],
    );
    state = state.copyWith(
      playerClub: updatedClub,
      squad: [...state.squad, player],
    );
    saveCareer();
    return true;
  }

  bool sellPlayer(CareerPlayer player) {
    if (state.squad.length <= 11) return false;
    final fee = (player.overallRating * player.overallRating * 650.0);
    final updatedSquad = state.squad.where((p) => p.id != player.id).toList();
    state = state.copyWith(
      squad: updatedSquad,
      playerClub: state.playerClub.copyWith(
        budget: state.playerClub.budget + fee,
        players: updatedSquad,
      ),
    );
    saveCareer();
    return true;
  }

  CareerGameState _createDefaultState() {
    final squad = List<CareerPlayer>.generate(18, (index) {
      final position = index < 2 ? 'GK' : index < 7 ? 'DEF' : index < 13 ? 'MID' : 'FWD';
      return CareerPlayer(
        id: index + 1,
        firstName: ['Alex','Mateo','Daniel','Luca','Noah','Ethan','Omar','Adam','Leo'][index % 9],
        lastName: ['Morgan','Silva','Reed','Costa','Bennett','Walker','Hassan','Kane','Martinez'][index % 9] + (index > 8 ? ' ${index + 1}' : ''),
        age: 19 + (index % 13), position: position,
        overallRating: 67 + (index % 17), potential: 76 + (index % 20),
        pace: 60 + (index * 7 % 36), shooting: 55 + (index * 9 % 40),
        passing: 58 + (index * 5 % 38), dribbling: 57 + (index * 8 % 40),
        defense: 52 + (index * 6 % 43), physical: 60 + (index * 4 % 36),
        morale: 75 + (index % 20), form: 60 + (index % 35),
        contractEndYear: DateTime.now().year + 2 + (index % 3),
        injuryWeeks: 0, isYouthPlayer: false,
      );
    });
    final club = CareerClub(
      id: 1, name: 'FC Elite', country: 'England', division: 'Premier Division',
      budget: 12000000, weeklyWages: 185000, players: squad,
      manager: const ClubManager(name: 'مدرب جديد', experience: 1, reputation: 55),
    );
    final opponentNames = <String>['Northbridge United','Riverside City','Capital Athletic','Westport FC','Kingsport Rovers','Eastvale Town','Redbridge FC','Harbor Athletic'];
    final clubs = [club, ...opponentNames.asMap().entries.map((entry) => CareerClub(
      id: entry.key + 2, name: entry.value, country: 'England', division: 'Premier Division',
      budget: 5000000 + entry.key * 700000, weeklyWages: 95000 + entry.key * 5000,
      players: _opponentPlayers(entry.value),
      manager: const ClubManager(name: 'AI Manager', experience: 8, reputation: 65),
    ))];
    final fixtures = <Fixture>[];
    var id = 1;
    for (var round = 0; round < clubs.length - 1; round++) {
      for (var i = 0; i < clubs.length ~/ 2; i++) {
        final home = clubs[(round + i) % clubs.length];
        final away = clubs[(clubs.length - 1 - i + round) % clubs.length];
        if (home.id == away.id) continue;
        fixtures.add(Fixture(id: id, matchday: round + 1, homeClubId: home.id,
          homeClubName: home.name, awayClubId: away.id, awayClubName: away.name,
          played: false, result: null, homeFormation: '4-3-3', awayFormation: '4-2-3-1'));
        id++;
      }
    }
    return _engine.initializeCareer(
      playerClub: club, leagueClubs: clubs, fixtures: fixtures,
      youth: YouthGroup(players: const [], facilities: 62),
    );
  }

  List<TeamPlayer> _teamPlayers(List<CareerPlayer> players) => players.map((player) => TeamPlayer(
    id: player.id, name: '${player.firstName} ${player.lastName}',
    position: player.position, overallRating: player.overallRating,
  )).toList();

  List<CareerPlayer> _opponentPlayers(String clubName) => List<CareerPlayer>.generate(18, (index) {
    final positions = <String>['GK','GK','DEF','DEF','DEF','DEF','DEF','MID','MID','MID','MID','MID','MID','FWD','FWD','FWD','FWD','FWD'];
    return CareerPlayer(
      id: 5000 + clubName.hashCode.abs() % 500 + index,
      firstName: clubName.split(' ').first, lastName: 'Player ${index + 1}',
      age: 19 + index % 12, position: positions[index], overallRating: 64 + (index % 19),
      potential: 72 + (index % 24), pace: 62, shooting: 62, passing: 62,
      dribbling: 62, defense: 62, physical: 62, morale: 70, form: 65,
      contractEndYear: DateTime.now().year + 2, injuryWeeks: 0, isYouthPlayer: false,
    );
  });
}
