import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EnergyUnit { kcal, kj }

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
    });
  }

  Future<void> _saveTotalEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_energy', _totalEnergy);
  }

  void _resetEnergyAtMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final duration = midnight.difference(now);
    Future.delayed(duration, () {
      setState(() {
        _totalEnergy = 0;
      });
      _saveTotalEnergy();
    });
  }

  void _addEnergy() {
    final int energy = int.tryParse(_controller.text) ?? 0;
    setState(() {
      if (_selectedUnit == EnergyUnit.kj) {
        // Assuming conversion rate: 1 kJ = 0.239 kcal
        _totalEnergy += (energy * 0.239).round();
      } else {
        _totalEnergy += energy;
      }
    });
    _saveTotalEnergy();
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ToggleButtons(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('kcal'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('kJ'),
                ),
              ],
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
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      'Enter Energy (${_selectedUnit == EnergyUnit.kcal ? 'kcal' : 'kJ'})',
                ),
              ),
              ElevatedButton(
                onPressed: _addEnergy,
                child: const Text('Add Energy'),
              ),
              Text('Total Energy: $_totalEnergy kcal'),
            ],
          ),
        ),
      ),
    );
  }
}
