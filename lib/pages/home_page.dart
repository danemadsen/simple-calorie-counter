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
  final TextEditingController _controller = TextEditingController();
  int _totalEnergy = 0;
  EnergyUnit _selectedUnit = EnergyUnit.kcal;
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
      _totalEnergy = prefs.getInt('total_energy') ?? 0;
      String? entriesJson = prefs.getString('entries');
      if (entriesJson != null) {
        Iterable l = json.decode(entriesJson);
        _entries = List<EnergyEntry>.from(
          l.map((model) => EnergyEntry.fromJson(model)));
      }
    });
  }

  Future<void> _saveTotalEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_energy', _totalEnergy);
    String entriesJson = json.encode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString('entries', entriesJson);
  }

  void _resetEnergyAtMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final duration = midnight.difference(now);
    Future.delayed(duration, () {
      setState(() {
        _totalEnergy = 0;
        _entries.clear();
      });
      _saveTotalEnergy();
    });
  }

  void _addEnergy() {
    final int energy = int.tryParse(_controller.text) ?? 0;
    final int energyInKcal = _selectedUnit == EnergyUnit.kj
        ? (energy * 0.239).round()
        : energy;

    setState(() {
      _entries.add(EnergyEntry(energyInKcal, DateTime.now()));
      _totalEnergy += energyInKcal;
    });

    _saveTotalEnergy();
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        titleSpacing: 0,
        actions: <Widget>[
          Expanded(
            child: Center(
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(30.0), // Rounded corners
                isSelected: [
                  _selectedUnit == EnergyUnit.kcal,
                  _selectedUnit == EnergyUnit.kj
                ],
                onPressed: (int index) {
                  setState(() {
                    _selectedUnit = EnergyUnit.values[index];
                    _controller.text = ''; // Clear text field when unit changes
                  });
                },
                children: const <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text('kcal'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text('kJ'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Energy (${_selectedUnit == EnergyUnit.kcal ? 'kcal' : 'kJ'})',
              ),
            ),
            ElevatedButton(
              onPressed: _addEnergy,
              child: const Text('Add Energy'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return Dismissible(
                    key: Key(entry.timestamp.toString()),
                    onDismissed: (direction) {
                      setState(() {
                        _totalEnergy -= entry.energy;
                        _entries.removeAt(index);
                        _saveTotalEnergy();
                      });
                    },
                    child: ListTile(
                      title: Text(
                        '${entry.energy} kcal - ${DateFormat.yMMMd().add_Hms().format(entry.timestamp)}',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis, // Ensures text is on one line
                      ),
                    ),
                  );
                },
              ),
            ),
            Text('Total Energy: $_totalEnergy kcal'),
          ],
        ),
      ),
    );
  }
}
