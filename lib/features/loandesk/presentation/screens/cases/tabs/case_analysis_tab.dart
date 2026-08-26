import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/core/api/api_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/loan_case.dart';
import '../../../theme/loandesk_theme.dart';
import '../../../widgets/neo_card.dart';
import '../../reports/case_summary_pdf_screen.dart';
import '../../../providers/loan_case_provider.dart';

class CaseAnalysisTab extends ConsumerStatefulWidget {
  final LoanCase loanCase;
  const CaseAnalysisTab({super.key, required this.loanCase});

  @override
  ConsumerState<CaseAnalysisTab> createState() => _CaseAnalysisTabState();
}

class _CaseAnalysisTabState extends ConsumerState<CaseAnalysisTab> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _analysisData;

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final dio = Dio();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final url = '${ApiConfig.loanDeskBaseUrl}/analysis/case/${widget.loanCase.id}/evaluate';
      final response = await dio.post(url);
      
      setState(() {
        _analysisData = response.data;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?.toString() ?? e.message ?? 'Unknown network error';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: LoanDeskTheme.primaryBlue),
              SizedBox(height: 16),
              Text('Evaluating Case via AI...', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Analysis Failed:\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LoanDeskTheme.primaryBlack,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry Evaluation'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Parse data safely matching the backend schema RiskAnalysisResponse
    final data = _analysisData ?? {};
    final riskScore = data['risk_score'] ?? 0;
    final riskGrade = data['risk_grade'] ?? 'N/A';
    final recommendedDecision = data['decision'] ?? 'UNKNOWN';
    final foir = data['foir_percentage'] ?? 0;
    
    final details = data['analysis_details'] ?? {};
    final categories = details['categories'] as Map<String, dynamic>? ?? {};
    final positiveFactors = (details['positive_factors'] as List<dynamic>?) ?? [];
    final riskFactors = (details['risk_factors'] as List<dynamic>?) ?? [];
    final graphBase64 = details['graph_base64'];
    final recommendedOffers = (details['recommended_offers'] as List<dynamic>?) ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decision Card
          NeoCard(
            padding: const EdgeInsets.all(20),
            backgroundColor: _getDecisionColor(recommendedDecision.toString()),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Risk Score', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('$riskScore/100', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Grade & Decision', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('$riskGrade • $recommendedDecision', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Proposed Loan Details
          const Text('Proposed Loan Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          NeoCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.white,
            child: Column(
              children: [
                _buildDetailRow('Requested Amount', '₹${(widget.loanCase.amount).toStringAsFixed(2)}'),
                const Divider(),
                _buildDetailRow('Interest Rate', '${widget.loanCase.rawDetails?['interest_rate'] ?? 0}%'),
                const Divider(),
                _buildDetailRow('Tenure', '${widget.loanCase.rawDetails?['tenure_months'] ?? 0} Months'),
                const Divider(),
                _buildDetailRow('Verified Monthly Income', '₹${(data['verified_monthly_income'] ?? 0).toStringAsFixed(2)}'),
                const Divider(),
                _buildDetailRow('Proposed EMI', '₹${(data['proposed_emi'] ?? 0).toStringAsFixed(2)}', isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Metrics Grid
          const Text('Category Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: categories.length, // backend sends FOIR in categories map now!
            itemBuilder: (context, index) {
              final entry = categories.entries.elementAt(index);
              final status = entry.value['status'] ?? 'unknown';
              return _buildCategoryCard(entry.key, entry.value['message']?.toString() ?? '', status.toString().toLowerCase());
            },
          ),
          
          const SizedBox(height: 24),
          
          // Positive Factors
          if (positiveFactors.isNotEmpty) ...[
            const Text('Positive Factors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green)),
            const SizedBox(height: 12),
            ...positiveFactors.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(e.toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],
          
          // Risk Factors
          if (riskFactors.isNotEmpty) ...[
            const Text('Risk Factors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.red)),
            const SizedBox(height: 12),
            ...riskFactors.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(e.toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            )),
            const SizedBox(height: 24),
          ],
          
          if (graphBase64 != null) ...[
            const Text('Monthly Income Utilization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            NeoCard(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.white,
              child: Image.memory(
                base64Decode(graphBase64),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          if (recommendedOffers.isNotEmpty) ...[
            const Text('AI Recommended Loan Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendedOffers.length,
                itemBuilder: (context, index) {
                  final offer = recommendedOffers[index];
                  return Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 16),
                    child: NeoCard(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: LoanDeskTheme.primaryWhite,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(offer['plan_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                              Text(offer['color_indicator'] ?? ''),
                            ],
                          ),
                          const Spacer(),
                          const Text('Max Loan Amount', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          Text('₹${(offer['max_loan_amount'] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tenure', style: TextStyle(fontSize: 10, color: Colors.black54)),
                                  Text('${offer['tenure_months']} mos', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  const Text('Rate/Limit', style: TextStyle(fontSize: 10, color: Colors.black54)),
                                  Text('${offer['interest_rate'] ?? 0}% / ${offer['foir'] ?? 0}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Max EMI', style: TextStyle(fontSize: 10, color: Colors.black54)),
                                  Text('₹${(offer['max_emi'] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  const Text(' ', style: TextStyle(fontSize: 10, color: Colors.black54)),
                                  const Text(' ', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Generate PDF
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CaseSummaryPdfScreen(loanCase: widget.loanCase),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text('GENERATE CAM REPORT (PDF)', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: LoanDeskTheme.primaryBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius - LoanDeskTheme.borderWidth),
                ),
                elevation: LoanDeskTheme.shadowOffset,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.loanCase.status != 'Completed')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(loanCaseProvider.notifier).updateCaseStatus(widget.loanCase.id, 'Completed');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Case marked as completed!')));
                  }
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text('MARK CASE AS COMPLETED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LoanDeskTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius - LoanDeskTheme.borderWidth),
                  ),
                  elevation: LoanDeskTheme.shadowOffset,
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Color _getDecisionColor(String decision) {
    decision = decision.toUpperCase();
    if (decision.contains('ELIGIBLE') || decision.contains('APPROVE')) return LoanDeskTheme.primaryGreen;
    if (decision.contains('REVIEW')) return LoanDeskTheme.primaryYellow;
    if (decision.contains('REJECT') || decision.contains('DECLINE') || decision.contains('NOT ELIGIBLE')) return LoanDeskTheme.primaryPink;
    return LoanDeskTheme.primaryWhite;
  }
  
  Widget _buildCategoryCard(String title, String value, String status) {
    String emoji = '🟡';
    if (status.contains('pass') || status.contains('good') || status.contains('high')) emoji = '🟢';
    if (status.contains('fail') || status.contains('poor') || status.contains('low')) emoji = '🔴';
    
    return NeoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(emoji),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.black54, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}
