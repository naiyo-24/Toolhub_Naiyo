import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:dio/dio.dart';
import '../../providers/daily_utility_providers.dart';

class CurrencyConverterScreen extends ConsumerStatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  ConsumerState<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends ConsumerState<CurrencyConverterScreen> {
  final _inputController = TextEditingController();
  
  String _fromCurrency = 'USD';
  String _toCurrency = 'INR';
  String _result = '0.00';
  bool _isLoading = true;
  String _error = '';

  Map<String, dynamic> _rates = {};
  List<String> _currencies = [];

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final dio = Dio();
      final response = await dio.get('https://api.exchangerate-api.com/v4/latest/USD');
      
      if (response.statusCode == 200) {
        final data = response.data;
        _rates = data['rates'] as Map<String, dynamic>;
        _currencies = _rates.keys.toList()..sort();
        
        if (!_currencies.contains(_fromCurrency)) _fromCurrency = _currencies.first;
        if (!_currencies.contains(_toCurrency)) _toCurrency = _currencies.first;
      } else {
        _error = 'Failed to load exchange rates';
      }
    } catch (e) {
      _error = 'Network error. Please try again.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _convert();
      }
    }
  }

  Future<void> _convert() async {
    if (_rates.isEmpty) return;

    double input = double.tryParse(_inputController.text) ?? 0.0;
    if (input == 0) {
      setState(() => _result = '0.00');
      return;
    }

    try {
      final result = await ref.read(dailyUtilityServiceProvider).convertCurrency(
        input,
        _fromCurrency,
        _toCurrency,
      );

      setState(() {
        _result = (result['converted_amount'] as num).toStringAsFixed(2);
      });
    } catch (e) {
      // Fallback to local rate calculation if API fails (e.g., currency not supported by backend Enum)
      double fromRate = (_rates[_fromCurrency] as num).toDouble();
      double toRate = (_rates[_toCurrency] as num).toDouble();

      double baseUsd = input / fromRate;
      double finalVal = baseUsd * toRate;

      setState(() {
        _result = finalVal.toStringAsFixed(2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Currency Converter',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchRates,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
            // Instructions
            NeoCard(
              backgroundColor: const Color(0xFFE0FBFC), // Light Blue tint
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.black),
                      const SizedBox(width: 8),
                      Text('How to use', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "1. Enter the amount to convert.\n2. Select your base currency and target currency.\n3. Tap 'Convert' to get the latest exchange rate result.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchRates,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      NeoCard(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildDropdown('From', _fromCurrency, (val) {
                              setState(() => _fromCurrency = val!);
                              _convert();
                            }),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _inputController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Enter amount',
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: const Icon(Icons.attach_money_rounded, color: Colors.black54),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.black, width: 2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                                ),
                              ),
                              onChanged: (_) => _convert(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGreen,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.swap_vert, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              String temp = _fromCurrency;
                              _fromCurrency = _toCurrency;
                              _toCurrency = temp;
                            });
                            _convert();
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      NeoCard(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDropdown('To', _toCurrency, (val) {
                              setState(() => _toCurrency = val!);
                              _convert();
                            }, true),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.currency_exchange_rounded, color: Colors.black54),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _result,
                                      style: AppTextStyles.heroTitle.copyWith(fontSize: 24, color: Colors.black),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDropdown(String label, String value, ValueChanged<String?> onChanged, [bool isDark = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.sectionTitle.copyWith(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
              items: _currencies.map((String cur) {
                return DropdownMenuItem<String>(
                  value: cur,
                  child: Text(cur, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
