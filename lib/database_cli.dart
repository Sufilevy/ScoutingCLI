import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dolumns/dolumns.dart';
import 'package:firebase_database/firebase_database.dart';

const districts = ['district-four', 'dcmp-practice', 'dcmp'];
final helpMessage = '''\t
  Commands:
=============

h
> Show this help message.

i <team_number>
> Print general info about the team.

n <team_number>
> Print all of the notes written on the team.

p
> Show a table with the placements of all of the teams.

dcmp
> Enter one of the names of the districts to switch to that district.
Available districts: $districts
''';

// ignore_for_file: prefer_function_declarations_over_variables
void Function(Object) print = (object) {};
void Function() finishedLoading = () {};
bool textAlignLeft = true;
late final DatabaseReference dbRef;
late final FirebaseApp app;
Map<dynamic, dynamic> dbNotes = {}, dbAverages = {};
String district = "";
bool firebaseReady = false;

void main() async {
  runApp(const MyApp());
  await setupFirebase();
}

Future<void> finish() async {
  app.delete();
  exit(0);
}

/// Sets up the required settings and connections for Firebase.
Future<void> setupFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Setting up Firebase... (Wait for the > arrow)');

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBMgBHKaYSS0-UR-CqEXy_LxEP4LpHvkrE",
      authDomain: "hamosad-scouting-app.firebaseapp.com",
      databaseURL:
          "https://hamosad-scouting-app-default-rtdb.europe-west1.firebasedatabase.app",
      projectId: "hamosad-scouting-app",
      storageBucket: "hamosad-scouting-app.appspot.com",
      messagingSenderId: "870501520419",
      appId: "1:870501520419:web:669560b005e2b3d8114d96",
      measurementId: "G-3GQ0DC3E2S",
    ),
  );
  final instance = FirebaseDatabase.instance;
  dbRef = instance.ref();
  dynamic db = (await dbRef.get()).value;
  if (db != null) {
    district = db['district'];
  }
  finishedLoading();
}

/// Gets the latest data snapshot of the database.
Future<void> getData() async {
  dynamic db;
  try {
    db = (await dbRef.get()).value;
  } on Exception {
    print('The database of the current district is empty.');
    await finish();
  }
  if (db == null || db[district] == null) {
    print('The database of the current district is empty.');
    await finish();
  }
  dbNotes = db[district]['notes'];
  dbAverages = db[district]['averages'];
}

/// Returns the placement of the specified team.
Future<int> getTeamPlacement(final teamNumber) async {
  await getData(); // Update the data from the database

  List teams = [];
  for (var team in dbAverages.entries) {
    teams.add([team.key, team.value['avgScoreTotal'].toDouble()]);
  }
  teams.sort(((a, b) => b[1].compareTo(a[1])));
  teams = teams.map((e) => e[0]).toList();
  return teams.indexOf(teamNumber) + 1;
}

/// Prints out the information associated with each team.
Future<void> getTeamInfo(final teamNumber) async {
  await getData(); // Update the data from the database

  if (int.tryParse(teamNumber) == null) {
    print('Invalid team number. Only use numbers.');
    return;
  } else {
    if (!dbAverages.containsKey(teamNumber)) {
      print('The database does not contain the specified team.');
      return;
    } else {
      final teamEntry = dbAverages[teamNumber];
      final table = dolumnify(
        [
          ['NAME', 'VALUE'],
          ['Placement', await getTeamPlacement(teamNumber)],
          [
            'Average Balls Autonomus',
            (teamEntry['avgBallsAutonomus'] ?? 0.0).toStringAsPrecision(3),
          ],
          [
            'Average Score Autonomus',
            (teamEntry['avgScoreAutonomus'] ?? 0.0).toStringAsPrecision(3),
          ],
          [
            'Average Upper Teleop',
            (teamEntry['avgUpperTeleop'] ?? 0.0).toStringAsPrecision(3),
          ],
          [
            'Average Lower Teleop',
            (teamEntry['avgLowerTeleop'] ?? 0.0).toStringAsPrecision(3),
          ],
          [
            'Average Score Percent',
            (teamEntry['avgScorePercent'] ?? 0.0).toStringAsPrecision(3) + '%',
          ],
          [
            'Average Score Teleop',
            (teamEntry['avgScoreTeleop'] ?? 0.0).toStringAsPrecision(3),
          ],
          [
            'Average Bar Climbed',
            (teamEntry['avgBarClimbed'] ?? 0.0).toStringAsPrecision(3),
          ],
          [
            'Average Sconds Climbed',
            (teamEntry['avgTimeClimbed'] ?? 0.0).toStringAsPrecision(3),
          ],
          [
            'Average Score Total',
            (teamEntry['avgScoreTotal'] ?? 0.0).toStringAsPrecision(3),
          ],
          [
            'Number of Reports',
            (teamEntry['numberOfReports'] ?? 0),
          ]
        ],
        columnSplitter: ' | ',
        headerSeparator: '=',
        headerIncluded: true,
      );
      final bars = dbAverages[teamNumber]['barsCanClimb'];
      var barsString = [];
      for (var bar in bars) {
        if (bar == true) {
          barsString.add('X');
        } else {
          barsString.add('  ');
        }
      }
      print('Team Number: $teamNumber\n\n' +
          table +
          '\n\n Robot\'s main focus (Scoring 1 <-> 5 Defending): ' +
          teamEntry['avgRobotFocus'].toString() +
          '\n' +
          '\n Bars that the robot can climb:\n' +
          ' 1    2    3    4\n[${barsString[0]}]  [${barsString[1]}]  [${barsString[2]}]  [${barsString[3]}]');
    }
  }
}

/// Prints out the notes associated with each team.
Future<void> getTeamNotes(final teamNumber) async {
  await getData(); // Update the data from the database

  if (int.tryParse(teamNumber) == null) {
    print('Invalid team number. Only use numbers.');
    return;
  } else {
    if (!dbNotes.containsKey(teamNumber)) {
      print('The database does not contain the specified team.');
      return;
    } else {
      final notes = dbNotes[teamNumber];
      bool hasNotes = false;
      String notesString = "Team Number: $teamNumber\n";
      for (var note in notes.entries) {
        var currentNotes = [];
        if (note.value['autonomus'].isNotEmpty) {
          currentNotes.add(['Autonomus', note.value['autonomus']]);
          hasNotes = true;
        }
        if (note.value['teleop'].isNotEmpty) {
          currentNotes.add(['Teleop', note.value['teleop']]);
          hasNotes = true;
        }
        if (note.value['endgame'].isNotEmpty) {
          currentNotes.add(['Endgame', note.value['endgame']]);
          hasNotes = true;
        }

        if (currentNotes.isEmpty) continue;

        final table = dolumnify(
          [
            ['GAME-STAGE', 'NOTE'],
            ...currentNotes.map((e) => [e[0].toString(), e[1].toString()])
          ],
          headerIncluded: true,
          headerSeparator: '=',
          columnSplitter: ' | ',
        );
        notesString +=
            '\n\n\nGame Number: ${note.key.split('_')[0]}\nReporter Name: ${note.key.split('_')[1]}\n\n' +
                table;
      }
      if (!hasNotes) {
        print('There are no notes on the team.');
      } else {
        print(notesString);
      }
    }
  }
}

/// Prints out the placements table of the teams.
Future<void> getTeamsPlacements() async {
  await getData(); // Update the data from the database

  List teams = [];
  for (var team in dbAverages.entries) {
    teams.add([team.key, team.value['avgScoreTotal'].toDouble()]);
  }
  teams.sort(((a, b) => b[1].compareTo(a[1])));

  List<List<String>> placements = [];
  for (var i = 0; i < teams.length; i++) {
    placements.add([(i + 1).toString().padRight(2, ' '), teams[i].first]);
  }
  final table = dolumnify(
    [
      ['P', 'TEAM'],
      ...placements
    ],
    headerIncluded: true,
    headerSeparator: '=',
    columnSplitter: ' | ',
  );
  print(table);
}

/// Checks if the number of arguments entered matches the expected number of arguments.
///
/// [length] is the number of arguments entered, [expected] is the expected number of arguments.
bool checkNumberOfArgs(final length, {required final expected}) {
  if (length < expected) {
    print('Not enough arguments. (Expected $expected, got $length)');
    return false;
  } else if (length > expected) {
    print('Too many arguments. (Expected $expected, got $length)');
    return false;
  } else {
    return true;
  }
}

/// Runs the main loop of the CLI.
void runCommand(final String? command,
    {required final Function ilay, required final Function text}) async {
  if (command == null || command.isEmpty) return;

  var input =
      command.split(' ').map((element) => element.toLowerCase()).toList();
  switch (input.first) {
    case 'h':
      if (checkNumberOfArgs(input.length - 1, expected: 0)) {
        print(helpMessage);
      }
      textAlignLeft = true;
      text();
      break;
    case 'i':
      if (checkNumberOfArgs(input.length - 1, expected: 1)) {
        await getTeamInfo(input[1]);
      }
      textAlignLeft = false;
      text();
      break;
    case 'n':
      if (checkNumberOfArgs(input.length - 1, expected: 1)) {
        await getTeamNotes(input[1]);
      }
      textAlignLeft = true;
      text();
      break;

    case 'p':
      if (checkNumberOfArgs(input.length - 1, expected: 0)) {
        await getTeamsPlacements();
      }
      textAlignLeft = false;
      text();
      break;
    case 'faggot':
      textAlignLeft = false;
      ilay();
      break;
    default:
      if (districts.contains(input.first)) {
        district = input.first;
        print('District set to: $district');
      } else {
        print('Unknown command.\n\n$helpMessage');
      }
      textAlignLeft = true;
      text();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Database CLI',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentText = helpMessage;
  final _theme = ThemeData(
      backgroundColor: Colors.black,
      primaryColor: Colors.white,
      shadowColor: Colors.grey);
  late FocusNode _focusNode;
  final TextEditingController _controller = TextEditingController();
  bool _ilay = false;
  double screenWidth = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    finishedLoading = () => setState(() => firebaseReady = true);
    print = (object) => setState(() => _currentText = object.toString());
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(child: child, opacity: animation);
      },
      child: Scaffold(
        key: ValueKey<bool>(firebaseReady),
        backgroundColor: _theme.backgroundColor,
        body: firebaseReady
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: screenWidth / 2,
                          child: TextField(
                            focusNode: _focusNode,
                            onSubmitted: (value) {
                              setState(() {
                                runCommand(
                                  value,
                                  ilay: () {
                                    if (!_ilay) setState(() => _ilay = true);
                                  },
                                  text: () {
                                    if (_ilay) setState(() => _ilay = false);
                                  },
                                );
                                _controller.clear();
                                _focusNode.unfocus();
                              });
                            },
                            controller: _controller,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            cursorColor: _theme.primaryColor,
                            maxLength: 15,
                            style: TextStyle(
                                fontSize: 20, color: _theme.primaryColor),
                            decoration: InputDecoration(
                              hintText: 'Enter a command...',
                              hintStyle: TextStyle(
                                  fontSize: 20, color: _theme.primaryColor),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: _theme.primaryColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: _theme.primaryColor,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: _theme.primaryColor,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: _theme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 11,
                      child: _ilay
                          ? Image.asset('assets/images/ilay.jpeg')
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SizedBox(
                                  width: screenWidth / 1.25,
                                  child: Text(
                                    _currentText,
                                    textAlign: textAlignLeft
                                        ? TextAlign.start
                                        : TextAlign.start,
                                    style: TextStyle(
                                      fontSize: screenWidth / 300 + 15,
                                      color: _theme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Text(
                  'Loading...',
                  style: TextStyle(color: _theme.primaryColor, fontSize: 30),
                ),
              ),
      ),
    );
  }
}
