import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import 'lib_logic_finance_engine.dart';

class MainOverlay extends StatefulWidget {
  @override
  _MainOverlayState createState() => _MainOverlayState();
}

class _MainOverlayState extends State<MainOverlay> {
  bool subscriptionActive = false;
  String selectedApp = 'Uber';
  String selectedCategory = 'X';
  double lucroPorKm = 0.0;
  String idioma = 'PT';
  final FinanceEngine engine = FinanceEngine();

  // Parâmetros configuráveis pelo motorista
  double taxaFrotista = 0.15;   // 15% exemplo
  double cpkReal = 0.30;        // custo real por km (combustível + manutenção)
  double distanciaKm = 5.0;
  double brutoExemplo = 15.0;
  bool isGPL = false;

  final Map<String, List<String>> categorias = {
    'Uber': ['X', 'XL', 'Black', 'Comfort'],
    'Bolt': ['Basic', 'XL', 'Comfort', 'Black'],
  };

  @override
  void initState() {
    super.initState();
    _checkSubscription();
    _calcularAutomatico();
  }

  Future<void> _checkSubscription() async {
    // Simulação – integrar com Stripe real
    final status = true; // substituir por verificação real
    setState(() {
      subscriptionActive = status;
    });
  }

  void _calcularAutomatico() {
    if (!subscriptionActive) return;
    final lucro = engine.calcularLucroNetto(
      bruto: brutoExemplo,
      taxaFrotista: taxaFrotista,
      distanciaKm: distanciaKm,
      cpkReal: cpkReal,
      isGPL: isGPL,
    );
    lucroPorKm = lucro / distanciaKm;
    setState(() {});
  }

  Color _getCorSemaforo() {
    if (!subscriptionActive) return Colors.grey;
    if (lucroPorKm > 0.70) return Colors.green;
    if (lucroPorKm >= 0.30) return Colors.orange;
    return Colors.red;
  }

  String _formatMoeda(double valor) {
    return NumberFormat.currency(locale: idioma == 'PT' ? 'pt_PT' : 'en_US', symbol: '€').format(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: _getCorSemaforo(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Lucro/km: ${_formatMoeda(lucroPorKm)}',
                  style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // Seletor App/Categoria
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: selectedApp,
                    items: ['Uber', 'Bolt'].map((app) => DropdownMenuItem(value: app, child: Text(app))).toList(),
                    onChanged: (v) => setState(() => selectedApp = v!),
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    value: selectedCategory,
                    items: categorias[selectedApp]!.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Botão de idioma
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    idioma = idioma == 'PT' ? 'EN' : 'PT';
                  });
                },
                child: Text(idioma == 'PT' ? '🇵🇹 PT' : '🇺🇸 US'),
              ),
              const SizedBox(height: 20),
              // Parâmetros configuráveis (painel de controlo)
              Card(
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text('⚙️ Custos reais do veículo', style: TextStyle(color: Colors.white)),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Taxa Frotista (%)'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          taxaFrotista = double.tryParse(v) ?? 0.15;
                          _calcularAutomatico();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Custo por km (CPK real - €)'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          cpkReal = double.tryParse(v) ?? 0.30;
                          _calcularAutomatico();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Distância (km)'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          distanciaKm = double.tryParse(v) ?? 1.0;
                          _calcularAutomatico();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Valor Bruto (€)'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          brutoExemplo = double.tryParse(v) ?? 0.0;
                          _calcularAutomatico();
                        },
                      ),
                      Row(
                        children: [
                          const Text('GPL (Eco-G):', style: TextStyle(color: Colors.white)),
                          Switch(
                            value: isGPL,
                            onChanged: (v) {
                              setState(() => isGPL = v);
                              _calcularAutomatico();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (!subscriptionActive)
                const Text('Subscrição inativa', style: TextStyle(color: Colors.white, fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }
}