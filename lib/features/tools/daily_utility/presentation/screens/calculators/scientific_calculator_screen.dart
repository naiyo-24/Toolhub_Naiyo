import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:math_expressions/math_expressions.dart';

class ScientificCalculatorScreen extends StatefulWidget {
  const ScientificCalculatorScreen({super.key});

  @override
  State<ScientificCalculatorScreen> createState() => _ScientificCalculatorScreenState();
}

class _ScientificCalculatorScreenState extends State<ScientificCalculatorScreen> {
  String _input = '';
  String _result = '0';

  void _onPressed(String text) {
    setState(() {
      if (text == 'C') {
        _input = '';
        _result = '0';
      } else if (text == '⌫') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (text == '=') {
        _calculateResult();
      } else if (['sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'log', 'ln', 'sqrt', 'exp'].contains(text)) {
        _input += '$text(';
      } else if (text == 'π') {
        _input += 'pi';
      } else if (text == 'x²') {
        _input += '^2';
      } else {
        _input += text;
      }
    });
  }

  void _calculateResult() {
    try {
      String finalExpression = _input;
      finalExpression = finalExpression.replaceAll('×', '*');
      finalExpression = finalExpression.replaceAll('÷', '/');
      finalExpression = finalExpression.replaceAll('log(', '(1/ln(10))*ln(');
      
      GrammarParser p = GrammarParser();
      Expression exp = p.parse(finalExpression);
      ContextModel cm = ContextModel();
      double eval = RealEvaluator(cm).evaluate(exp).toDouble();
      
      _result = eval.toString();
      if (_result.endsWith('.0')) {
        _result = _result.substring(0, _result.length - 2);
      }
    } catch (e) {
      _result = 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Scientific Calculator',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_input, style: const TextStyle(color: Colors.white54, fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(_result, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: GridView.count(
                crossAxisCount: 5,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.1,
                children: [
                  _btn('asin', AppColors.primaryBlue), _btn('acos', AppColors.primaryBlue), _btn('atan', AppColors.primaryBlue), _btn('(', AppColors.primaryBlue), _btn(')', AppColors.primaryBlue),
                  _btn('sin', AppColors.primaryBlue), _btn('cos', AppColors.primaryBlue), _btn('tan', AppColors.primaryBlue), _btn('C', AppColors.primaryPink), _btn('⌫', AppColors.primaryPink),
                  _btn('log', AppColors.primaryBlue), _btn('ln', AppColors.primaryBlue), _btn('e', AppColors.primaryBlue), _btn('^', AppColors.primaryBlue), _btn('/', AppColors.primaryYellow),
                  _btn('sqrt', AppColors.primaryBlue), _btn('7', Colors.grey[200]!), _btn('8', Colors.grey[200]!), _btn('9', Colors.grey[200]!), _btn('*', AppColors.primaryYellow),
                  _btn('exp', AppColors.primaryBlue), _btn('4', Colors.grey[200]!), _btn('5', Colors.grey[200]!), _btn('6', Colors.grey[200]!), _btn('-', AppColors.primaryYellow),
                  _btn('%', AppColors.primaryBlue), _btn('1', Colors.grey[200]!), _btn('2', Colors.grey[200]!), _btn('3', Colors.grey[200]!), _btn('+', AppColors.primaryYellow),
                  _btn('x²', AppColors.primaryBlue), _btn('0', Colors.grey[200]!), _btn('.', Colors.grey[200]!), _btn('π', AppColors.primaryBlue), _btn('=', AppColors.primaryGreen),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _btn(String text, Color color) {
    return GestureDetector(
      onTap: () => _onPressed(text),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: text.length > 2 ? 14 : 22,
            fontWeight: FontWeight.bold,
            color: color == Colors.grey[200] ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
