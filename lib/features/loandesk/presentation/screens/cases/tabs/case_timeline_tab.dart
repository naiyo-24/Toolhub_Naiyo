import 'package:flutter/material.dart';
import '../../../../domain/entities/loan_case.dart';
import '../../../theme/loandesk_theme.dart';
import '../../../widgets/neo_card.dart';
import '../../../widgets/neo_button.dart';
import '../../../widgets/neo_text_field.dart';

class CaseTimelineTab extends StatelessWidget {
  final LoanCase loanCase;

  const CaseTimelineTab({super.key, required this.loanCase});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> events = [
      {
        'title': 'Case Created',
        'subtitle': 'Created by Rahul Banker',
        'date': 'Oct 12, 10:30 AM',
        'icon': Icons.add_circle,
        'color': LoanDeskTheme.primaryGreen,
      },
      {
        'title': 'PAN Verified',
        'subtitle': 'System Auto-Verification',
        'date': 'Oct 12, 10:35 AM',
        'icon': Icons.verified,
        'color': LoanDeskTheme.primaryBlue,
      },
      {
        'title': 'Bank Statement Uploaded',
        'subtitle': 'Uploaded by Applicant',
        'date': 'Oct 13, 02:15 PM',
        'icon': Icons.upload_file,
        'color': LoanDeskTheme.primaryYellow,
      },
      {
        'title': 'Note Added',
        'subtitle': 'Applicant requested higher amount. Reviewing financials.',
        'date': 'Oct 14, 09:00 AM',
        'icon': Icons.note_alt,
        'color': LoanDeskTheme.primaryWhite,
      },
      {
        'title': 'Sent for Approval',
        'subtitle': 'Waiting on Credit Manager',
        'date': 'Oct 15, 11:45 AM',
        'icon': Icons.send,
        'color': LoanDeskTheme.primaryPink,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audit Timeline',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: event['color'],
                              shape: BoxShape.circle,
                              border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
                            ),
                            child: Icon(event['icon'], size: 20, color: LoanDeskTheme.primaryBlack),
                          ),
                          if (index != events.length - 1)
                            Container(
                              height: 40,
                              width: 2,
                              color: LoanDeskTheme.primaryBlack,
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: NeoCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      event['title'],
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    event['date'],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event['subtitle'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NeoTextField(
                  label: 'Add a note to timeline...',
                  controller: TextEditingController(),
                ),
              ),
              const SizedBox(width: 8),
              NeoButton(
                text: 'ADD',
                color: LoanDeskTheme.primaryBlack,
                textColor: LoanDeskTheme.primaryWhite,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note added to timeline!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
