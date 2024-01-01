import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

enum EnergyUnit { kcal, kj }

class EnergyEntry {
  final int energy;
  final DateTime timestamp;

  EnergyEntry(this.energy, this.timestamp);

  Map<String, dynamic> toJson() => {
    'energy': energy,
    'timestamp': timestamp.toIso8601String(),
  };

  factory EnergyEntry.fromJson(Map<String, dynamic> json) {
    return EnergyEntry(
      json['energy'],
      DateTime.parse(json['timestamp']),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _kjController = TextEditingController();
  final TextEditingController _kcalController = TextEditingController();
  int _totalEnergy = 0;
  List<EnergyEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadTotalEnergy();
    _resetEnergyAtMidnight();
  }

  Future<void> _loadTotalEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String? entriesJson = prefs.getString('entries');
      if (entriesJson != null) {
        Iterable l = json.decode(entriesJson);
        _entries = List<EnergyEntry>.from(
          l.map((model) => EnergyEntry.fromJson(model)));

        _pruneEntries();
      }
    });
  }

  Future<void> _saveTotalEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    String entriesJson = json.encode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString('entries', entriesJson);
  }

  void _pruneEntries() {
    //prune entries from previous days
    for (final entry in _entries) {
      if (entry.timestamp.day != DateTime.now().day) {
        _entries.removeAt(_entries.indexOf(entry));
        break;
      }
    }

    //recalculate total energy
    _totalEnergy = 0;
    for (final entry in _entries) {
      _totalEnergy += entry.energy;
    }
  }

  void _resetEnergyAtMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final duration = midnight.difference(now);
    Future.delayed(duration, () {
      setState(() {
        _pruneEntries();
      });
      _saveTotalEnergy();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Total Energy: $_totalEnergy kcal'),
        centerTitle: true,
        titleSpacing: 0
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _kcalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Energy (kcal)',
              ),
              onSubmitted: (value) {
                final int kcal = int.tryParse(value) ?? 0;

                setState(() {
                  _entries.add(EnergyEntry(kcal, DateTime.now()));
                  _pruneEntries();
                });

                _saveTotalEnergy();
                _kcalController.clear();
                _kjController.clear();
              },
              onChanged: (value) {
                final int kcal = int.tryParse(_kcalController.text) ?? 0;
                final int kj = (kcal / 0.239).round();
                if (kj == 0) {
                  _kjController.clear();
                } else {
                  _kjController.text = kj.toString();
                }
              },
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _kjController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Energy (kJ)',
              ),
              onSubmitted: (value) {
                final int kj = int.tryParse(value) ?? 0;
                final int kcal = (kj * 0.239).round();

                setState(() {
                  _entries.add(EnergyEntry(kcal, DateTime.now()));
                  _pruneEntries();
                });

                _saveTotalEnergy();
                _kcalController.clear();
                _kjController.clear();
              },
              onChanged: (value) {
                final int kj = int.tryParse(_kjController.text) ?? 0;
                final int kcal = (kj * 0.239).round();
                if (kcal == 0) {
                  _kcalController.clear();
                } else {
                  _kcalController.text = kcal.toString();
                }
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0), // Add padding here
                    child: Dismissible(
                      key: Key(entry.timestamp.toString()),
                      onDismissed: (direction) {
                        setState(() {
                          _totalEnergy -= entry.energy;
                          _entries.removeAt(index);
                          _saveTotalEnergy();
                        });
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        title: Text(
                          '${entry.energy} kcal - ${DateFormat.yMMMd().add_Hms().format(entry.timestamp)}',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                        tileColor: Colors.blue.shade900,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
