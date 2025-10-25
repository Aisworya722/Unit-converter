import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() => runApp(const UnitConverterApp());

class UnitConverterApp extends StatelessWidget {
  const UnitConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unit Converter',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const ConverterScreen(),
    );
  }
}

enum Category { length, weight, temperature }
enum System { metric, imperial }

class Unit {
  final String name;
  final String symbol;
  const Unit(this.name, this.symbol);

  @override
  String toString() => '$name ($symbol)';
}

class UnitRegistry {
  static const lengthMetric = <Unit>[
    Unit('Kilometer', 'km'),
    Unit('Meter', 'm'),
    Unit('Centimeter', 'cm'),
  ];
  static const lengthImperial = <Unit>[
    Unit('Mile', 'mi'),
    Unit('Yard', 'yd'),
    Unit('Foot', 'ft'),
  ];

  static const weightMetric = <Unit>[
    Unit('Kilogram', 'kg'),
    Unit('Gram', 'g'),
  ];
  static const weightImperial = <Unit>[
    Unit('Pound', 'lb'),
    Unit('Ounce', 'oz'),
  ];

  static const temperatureMetric = <Unit>[
    Unit('Celsius', '°C'),
  ];
  static const temperatureImperial = <Unit>[
    Unit('Fahrenheit', '°F'),
  ];

  static List<Unit> unitsFor(Category category, System system) {
    switch (category) {
      case Category.length:
        return system == System.metric ? lengthMetric : lengthImperial;
      case Category.weight:
        return system == System.metric ? weightMetric : weightImperial;
      case Category.temperature:
        return system == System.metric ? temperatureMetric : temperatureImperial;
    }
  }
}

class Conversions {
  static double _lengthToMeters(Unit u, double v) {
    switch (u.symbol) {
      case 'km':
        return v * 1000;
      case 'm':
        return v;
      case 'cm':
        return v / 100;
      case 'mi':
        return v * 1609.344;
      case 'yd':
        return v * 0.9144;
      case 'ft':
        return v * 0.3048;
      default:
        throw ArgumentError('Unsupported length unit ${u.symbol}');
    }
  }

  static double _metersTo(Unit u, double meters) {
    switch (u.symbol) {
      case 'km':
        return meters / 1000;
      case 'm':
        return meters;
      case 'cm':
        return meters * 100;
      case 'mi':
        return meters / 1609.344;
      case 'yd':
        return meters / 0.9144;
      case 'ft':
        return meters / 0.3048;
      default:
        throw ArgumentError('Unsupported length unit ${u.symbol}');
    }
  }

  static double _weightToKg(Unit u, double v) {
    switch (u.symbol) {
      case 'kg':
        return v;
      case 'g':
        return v / 1000;
      case 'lb':
        return v * 0.45359237;
      case 'oz':
        return v * 0.028349523125;
      default:
        throw ArgumentError('Unsupported weight unit ${u.symbol}');
    }
  }

  static double _kgTo(Unit u, double kg) {
    switch (u.symbol) {
      case 'kg':
        return kg;
      case 'g':
        return kg * 1000;
      case 'lb':
        return kg / 0.45359237;
      case 'oz':
        return kg / 0.028349523125;
      default:
        throw ArgumentError('Unsupported weight unit ${u.symbol}');
    }
  }

  static double _tempConvert(Unit from, Unit to, double v) {
    if (from.symbol == '°C' && to.symbol == '°F') {
      return v * 9 / 5 + 32;
    } else if (from.symbol == '°F' && to.symbol == '°C') {
      return (v - 32) * 5 / 9;
    } else if (from.symbol == to.symbol) {
      return v;
    }
    throw ArgumentError('Unsupported temperature conversion ${from.symbol} → ${to.symbol}');
  }

  static double convert(Category category, Unit from, Unit to, double value) {
    switch (category) {
      case Category.length:
        final meters = _lengthToMeters(from, value);
        return _metersTo(to, meters);
      case Category.weight:
        final kg = _weightToKg(from, value);
        return _kgTo(to, kg);
      case Category.temperature:
        return _tempConvert(from, to, value);
    }
  }
}

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  Category _category = Category.length;
  System _system = System.metric;

  late List<Unit> _fromUnits = UnitRegistry.unitsFor(_category, _system);
  late List<Unit> _toUnits = UnitRegistry.unitsFor(_category, _system);

  late Unit _from = _fromUnits.first;
  late Unit _to = _toUnits[math.min(1, _toUnits.length - 1)];

  final _inputController = TextEditingController(text: '1');
  String? _errorText;
  double? _result;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _refreshUnits() {
    setState(() {
      _fromUnits = UnitRegistry.unitsFor(_category, _system);
      _toUnits = UnitRegistry.unitsFor(_category, _system);
      _from = _fromUnits.first;
      _to = _toUnits[math.min(1, _toUnits.length - 1)];
      _result = null;
      _errorText = null;
    });
  }

  void _convert() {
    setState(() {
      _errorText = null;
      _result = null;
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        _errorText = 'Enter a value';
        return;
      }
      final value = double.tryParse(input.replaceAll(',', ''));
      if (value == null) {
        _errorText = 'Invalid number';
        return;
      }
      try {
        _result = Conversions.convert(_category, _from, _to, value);
      } catch (e) {
        _errorText = e.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_category) {
      Category.length => 'Length',
      Category.weight => 'Weight',
      Category.temperature => 'Temperature',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Converter'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Category>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: Category.values
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name[0].toUpperCase() + c.name.substring(1)),
                              ))
                          .toList(),
                      onChanged: (c) {
                        if (c == null) return;
                        _category = c;
                        _refreshUnits();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<System>(
                      value: _system,
                      decoration: const InputDecoration(labelText: 'System'),
                      items: const [
                        DropdownMenuItem(value: System.metric, child: Text('Metric')),
                        DropdownMenuItem(value: System.imperial, child: Text('Imperial')),
                      ],
                      onChanged: (s) {
                        if (s == null) return;
                        _system = s;
                        _refreshUnits();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Unit>(
                      value: _from,
                      decoration: const InputDecoration(labelText: 'From'),
                      items: _fromUnits
                          .map((u) => DropdownMenuItem(value: u, child: Text(u.toString())))
                          .toList(),
                      onChanged: (u) => setState(() => _from = u!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Unit>(
                      value: _to,
                      decoration: const InputDecoration(labelText: 'To'),
                      items: _toUnits
                          .map((u) => DropdownMenuItem(value: u, child: Text(u.toString())))
                          .toList(),
                      onChanged: (u) => setState(() => _to = u!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _inputController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Value',
                  hintText: 'Enter a number',
                  errorText: _errorText,
                  suffixIcon: IconButton(
                    tooltip: 'Clear',
                    onPressed: () => setState(() {
                      _inputController.clear();
                      _result = null;
                      _errorText = null;
                    }),
                    icon: const Icon(Icons.clear),
                  ),
                ),
                onSubmitted: (_) => _convert(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Convert'),
                  onPressed: _convert,
                ),
              ),
              const SizedBox(height: 24),
              if (_result != null)
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$title Result', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          _formatResult(_result!, _to.symbol),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                'Tip: switch Category or System to reveal different unit sets.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatResult(double value, String symbol) {
    final fixed = value.abs() >= 1 ? value.toStringAsFixed(4) : value.toStringAsPrecision(6);
    return '${_trimZeros(fixed)} $symbol';
  }

  String _trimZeros(String s) {
    if (!s.contains('.')) return s;
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }
}
