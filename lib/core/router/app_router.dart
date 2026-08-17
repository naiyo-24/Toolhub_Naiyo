import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/notification_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/daily_utility_screen.dart';
import '../../features/tools/minima/presentation/screens/minima_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/file_sharing_screen.dart';
import '../../features/tools/ai_tools/presentation/screens/ai_tools_screen.dart';
import '../../features/tools/student_toolkit/presentation/screens/student_toolkit_screen.dart';

import '../../features/tools/student_toolkit/presentation/screens/cgpa_calculator_screen.dart';
import '../../features/tools/student_toolkit/presentation/screens/sgpa_calculator_screen.dart';
import '../../features/tools/student_toolkit/presentation/screens/attendance_calculator_screen.dart';
import '../../features/tools/student_toolkit/presentation/screens/exam_countdown_screen.dart';
import '../../features/tools/student_toolkit/presentation/screens/notes_maker_screen.dart';
import '../../features/tools/student_toolkit/presentation/screens/flashcards_screen.dart';

import '../../features/tools/student_toolkit/presentation/screens/timetable_screen.dart';
import '../../features/tools/student_toolkit/presentation/screens/study_planner_screen.dart';
import '../../features/tools/student_toolkit/presentation/screens/assignment_planner_screen.dart';
import '../../features/tools/docu_forge/presentation/screens/docuforge_home_screen.dart';
import '../../features/tools/docu_forge/presentation/screens/pdf_viewer_screen.dart';
import '../../features/tools/docu_forge/data/models/document_model.dart';
import '../../features/tools/docu_forge/presentation/screens/resume_builder_form_screen.dart';
import '../../features/tools/docu_forge/presentation/screens/resume_template_selection_screen.dart';
import '../../features/tools/docu_forge/presentation/screens/resume_preview_screen.dart';
import '../../features/tools/docu_forge/presentation/screens/ats_checker_screen.dart';
import '../../features/tools/docu_forge/presentation/screens/cover_letter_form_screen.dart';
import '../../features/tools/docu_forge/presentation/screens/cover_letter_preview_screen.dart';
import '../../features/tools/docu_forge/presentation/screens/docu_forge_tool_screen.dart';
import '../../features/tools/docu_forge/presentation/screens/external_intent_screen.dart';
import '../../features/tools/docu_forge/data/resume_model.dart';
import '../../features/tools/docu_forge/data/cover_letter_model.dart';
import '../../features/tools/business_toolkit/presentation/screens/business_toolkit_screen.dart';
import '../../features/tools/business_toolkit/presentation/screens/business_analytics_screen.dart';
import '../../features/tools/business_toolkit/presentation/screens/profit_calculator_screen.dart';
import '../../features/tools/business_toolkit/presentation/screens/inventory_list_screen.dart';
import '../../features/tools/business_toolkit/presentation/screens/invoice_generator_screen.dart';
import '../../features/tools/business_toolkit/presentation/screens/quotation_gen_screen.dart';
import '../../features/tools/business_toolkit/presentation/screens/receipt_gen_screen.dart';
import '../../features/tools/business_toolkit/presentation/screens/business_card_screen.dart';
import '../../features/tools/business_toolkit/presentation/screens/inventory_manager_screen.dart';
import '../../features/tools/business_toolkit/presentation/screens/inventory_scanner_screen.dart';
import '../../features/tools/business_toolkit/presentation/screens/sales_tracker_screen.dart';
import '../../features/tools/business_toolkit/presentation/screens/expense_manager_screen.dart';
import '../../features/tools/business_toolkit/presentation/screens/pos_billing_screen.dart';
import '../../features/auth/presentation/screens/business_login_screen.dart';
import '../../features/auth/presentation/screens/create_profile_screen.dart';
import '../../features/tools/finance/presentation/screens/finance_tools_screen.dart';
import '../../features/tools/finance/presentation/screens/finance_calculator_screen.dart';
import '../../features/tools/finance/presentation/screens/expense_tracker_screen.dart';
import 'package:tool_hub/features/tools/business_toolkit/presentation/screens/purchase_invoice_screen.dart';
import 'package:tool_hub/features/tools/social_tools/presentation/screens/social_tools_screen.dart';
import 'package:tool_hub/features/tools/social_tools/presentation/screens/social_tool_screen.dart';
import 'package:tool_hub/features/tools/travel_tools/presentation/screens/travel_tools_screen.dart';
import 'package:tool_hub/features/tools/docu_forge/presentation/screens/id_card_generator_screen.dart';
import '../../features/tools/health_lifestyle/presentation/screens/health_lifestyle_screen.dart';
import '../../features/tools/health_lifestyle/presentation/screens/health_tool_screen.dart';
import '../../features/tools/productivity/presentation/screens/productivity_screen.dart';
import '../../features/tools/productivity/presentation/screens/productivity_tool_screen.dart';
import '../../features/tools/docu_forge/presentation/screens/utilities/images_to_pdf_screen.dart';

import 'package:tool_hub/features/tools/travel_tools/presentation/screens/travel_tool_screen.dart';
import '../../features/tools/form_builder/presentation/screens/form_builder_screen.dart';
import '../../features/tools/form_builder/presentation/screens/create_form_screen.dart';
import '../../features/tools/form_builder/presentation/screens/my_forms_screen.dart';
import '../../features/tools/form_builder/presentation/screens/form_details_screen.dart';
import '../../features/tools/form_builder/presentation/screens/submit_form_screen.dart';
import '../../features/legal/presentation/screens/terms_screen.dart';
import '../../features/legal/presentation/screens/privacy_screen.dart';
import '../../features/legal/presentation/screens/about_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/calculators/emi_calculator_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/calculators/age_calculator_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/calculators/bmi_calculator_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/converters/unit_converter_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/converters/currency_converter_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/converters/base_converter_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/text_utils/case_converter_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/text_utils/text_counter_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/time_utils/stopwatch_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/time_utils/timer_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/time_utils/world_clock_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/time_utils/calendar_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/security_utils/password_generator_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/security_utils/password_checker_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/scanners/qr_generator_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/scanners/barcode_generator_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/scanners/scanner_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/calculators/gst_calculator_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/calculators/sip_calculator_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/calculators/loan_calculator_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/calculators/percentage_calculator_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/calculators/discount_calculator_screen.dart';
import '../../features/tools/daily_utility/presentation/screens/calculators/scientific_calculator_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/internet_tools_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/url_shortener_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/url_expander_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/link_checker_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/email_validator_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/wifi_qr_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/upi_qr_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/ip_finder_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/dns_lookup_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/status_checker_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/ping_test_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/web_screenshot_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/speed_test_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/json_formatter_screen.dart';
import '../../features/tools/internet_tools/presentation/screens/base64_encoder_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/zip_extractor_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/zip_creator_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/image_compressor_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/pdf_compressor_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/format_converter_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/merge_pdf_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/pdf_password_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/ocr_scanner_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/duplicate_finder_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/storage_analyzer_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/file_share_screen.dart';
import '../../features/tools/file_sharing/presentation/screens/file_rename_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(bool hasSeenOnboarding, bool launchedFromNotification) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: launchedFromNotification ? '/calendar' : (hasSeenOnboarding ? '/' : '/onboarding'),
    errorBuilder: (context, state) {
      final uriStr = state.uri.toString();
      if (uriStr.startsWith('content://') || uriStr.startsWith('file://')) {
        return ExternalIntentScreen(uri: uriStr);
      }
      return const HomeScreen();
    },
    routes: [
      GoRoute(
        path: '/internet-tools',
        builder: (context, state) => const InternetToolsScreen(),
      ),
      GoRoute(
        path: '/internet-tools/url-shortener',
        builder: (context, state) => const UrlShortenerScreen(),
      ),
      GoRoute(
        path: '/internet-tools/url-expander',
        builder: (context, state) => const UrlExpanderScreen(),
      ),
      GoRoute(
        path: '/internet-tools/link-checker',
        builder: (context, state) => const LinkCheckerScreen(),
      ),
      GoRoute(
        path: '/internet-tools/email-validator',
        builder: (context, state) => const EmailValidatorScreen(),
      ),
      GoRoute(
        path: '/internet-tools/wifi-qr',
        builder: (context, state) => const WifiQrScreen(),
      ),
      GoRoute(
        path: '/internet-tools/upi-qr',
        builder: (context, state) => const UpiQrScreen(),
      ),
      GoRoute(
        path: '/internet-tools/ip-finder',
        builder: (context, state) => const IpFinderScreen(),
      ),
      GoRoute(
        path: '/internet-tools/dns-lookup',
        builder: (context, state) => const DnsLookupScreen(),
      ),
      GoRoute(
        path: '/internet-tools/site-status',
        builder: (context, state) => const StatusCheckerScreen(),
      ),
      GoRoute(
        path: '/internet-tools/ping-test',
        builder: (context, state) => const PingTestScreen(),
      ),
      GoRoute(
        path: '/internet-tools/web-screenshot',
        builder: (context, state) => const WebScreenshotScreen(),
      ),
      GoRoute(
        path: '/internet-tools/speed-test',
        builder: (context, state) => const SpeedTestScreen(),
      ),
      GoRoute(
        path: '/internet-tools/json-formatter',
        builder: (context, state) => const JsonFormatterScreen(),
      ),
      GoRoute(
        path: '/internet-tools/base64-tool',
        builder: (context, state) => const Base64EncoderScreen(),
      ),
      GoRoute(
        path: '/gst-calculator',
        builder: (context, state) => const GstCalculatorScreen(),
      ),
      GoRoute(
        path: '/sip-calculator',
        builder: (context, state) => const SipCalculatorScreen(),
      ),
      GoRoute(
        path: '/loan-calculator',
        builder: (context, state) => const LoanCalculatorScreen(),
      ),
      GoRoute(
        path: '/percentage-calculator',
        builder: (context, state) => const PercentageCalculatorScreen(),
      ),
      GoRoute(
        path: '/discount-calculator',
        builder: (context, state) => const DiscountCalculatorScreen(),
      ),
      GoRoute(
        path: '/scientific-calculator',
        builder: (context, state) => const ScientificCalculatorScreen(),
      ),
      GoRoute(
        path: '/cgpa-calculator',
        builder: (context, state) => const CgpaCalculatorScreen(),
      ),
      GoRoute(
        path: '/sgpa-calculator',
        builder: (context, state) => const SgpaCalculatorScreen(),
      ),
      GoRoute(
        path: '/attendance-calculator',
        builder: (context, state) => const AttendanceCalculatorScreen(),
      ),
      GoRoute(
        path: '/exam-countdown',
        builder: (context, state) => const ExamCountdownScreen(),
      ),
      GoRoute(
        path: '/notes-maker',
        builder: (context, state) => const NotesMakerScreen(),
      ),
      GoRoute(
        path: '/flashcards',
        builder: (context, state) => const FlashcardsScreen(),
      ),
      GoRoute(
        path: '/timetable',
        builder: (context, state) => const TimetableScreen(),
      ),
      GoRoute(
        path: '/study-planner',
        builder: (context, state) => const StudyPlannerScreen(),
      ),
      GoRoute(
        path: '/assignment-planner',
        builder: (context, state) => const AssignmentPlannerScreen(),
      ),
      GoRoute(
        path: '/resume-builder',
        builder: (context, state) => const ResumeBuilderFormScreen(),
      ),
      GoRoute(
        path: '/resume-templates',
        builder: (context, state) {
          final resumeData = state.extra as ResumeData;
          return ResumeTemplateSelectionScreen(resumeData: resumeData);
        },
      ),
      GoRoute(
        path: '/resume-preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ResumePreviewScreen(
            resumeData: extra['resumeData'] as ResumeData,
            templateId: extra['templateId'] as String,
          );
        },
      ),
      GoRoute(
        path: '/ats-checker',
        builder: (context, state) => const ATSCheckerScreen(),
      ),
      GoRoute(
        path: '/cover-letter',
        builder: (context, state) => const CoverLetterFormScreen(),
      ),
      GoRoute(
        path: '/cover-letter-preview',
        builder: (context, state) {
          final data = state.extra as CoverLetterData;
          return CoverLetterPreviewScreen(data: data);
        },
      ),
      GoRoute(
        path: '/docuforge-tool',
        builder: (context, state) {
          final config = state.extra as Map<String, dynamic>;
          return DocuForgeToolScreen(toolConfig: config);
        },
      ),
      GoRoute(
        path: '/qr-generator',
        builder: (context, state) => const QrGeneratorScreen(),
      ),
      GoRoute(
        path: '/barcode-generator',
        builder: (context, state) => const BarcodeGeneratorScreen(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const ScannerScreen(scannerType: 'QR'),
      ),
      GoRoute(
        path: '/barcode-scanner',
        builder: (context, state) => const ScannerScreen(scannerType: 'Barcode'),
      ),
      GoRoute(
        path: '/password-generator',
        builder: (context, state) => const PasswordGeneratorScreen(),
      ),
      GoRoute(
        path: '/password-checker',
        builder: (context, state) => const PasswordCheckerScreen(),
      ),
      GoRoute(
        path: '/stopwatch',
        builder: (context, state) => const StopwatchScreen(),
      ),
      GoRoute(
        path: '/timer',
        builder: (context, state) => const TimerScreen(),
      ),
      GoRoute(
        path: '/world-clock',
        builder: (context, state) => const WorldClockScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/unit-converter',
        builder: (context, state) => const UnitConverterScreen(),
      ),
      GoRoute(
        path: '/currency-converter',
        builder: (context, state) => const CurrencyConverterScreen(),
      ),
      GoRoute(
        path: '/case-converter',
        builder: (context, state) => const CaseConverterScreen(),
      ),
      GoRoute(
        path: '/base-converter',
        builder: (context, state) => const BaseConverterScreen(),
      ),
      GoRoute(
        path: '/text-counter',
        builder: (context, state) => const TextCounterScreen(),
      ),
      GoRoute(
        path: '/emi-calculator',
        builder: (context, state) => const EmiCalculatorScreen(),
      ),
      GoRoute(
        path: '/age-calculator',
        builder: (context, state) => const AgeCalculatorScreen(),
      ),
      GoRoute(
        path: '/bmi-calculator',
        builder: (context, state) => const BmiCalculatorScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/daily-utility',
        builder: (context, state) => const DailyUtilityScreen(),
      ),
      GoRoute(
        path: '/minima',
        builder: (context, state) => const MinimaScreen(),
      ),
      GoRoute(
        path: '/file-sharing',
        builder: (context, state) => const FileSharingScreen(),
      ),
      GoRoute(
        path: '/file-tools/file-share',
        builder: (context, state) => const FileShareScreen(),
      ),
      GoRoute(
        path: '/file-tools/rename-files',
        builder: (context, state) => const FileRenameScreen(),
      ),
      GoRoute(
        path: '/file-tools/zip-extractor',
        builder: (context, state) => const ZipExtractorScreen(),
      ),
      GoRoute(
        path: '/file-tools/zip-creator',
        builder: (context, state) => const ZipCreatorScreen(),
      ),
      GoRoute(
        path: '/file-tools/image-compressor',
        builder: (context, state) => const ImageCompressorScreen(),
      ),
      GoRoute(
        path: '/file-tools/pdf-compressor',
        builder: (context, state) => const PdfCompressorScreen(),
      ),
      GoRoute(
        path: '/file-tools/format-converter',
        builder: (context, state) => const FormatConverterScreen(),
      ),
      GoRoute(
        path: '/file-tools/merge-pdf',
        builder: (context, state) => const MergePdfScreen(),
      ),
      GoRoute(
        path: '/file-tools/pdf-password',
        builder: (context, state) => const PdfPasswordScreen(),
      ),
      GoRoute(
        path: '/file-tools/ocr-scanner',
        builder: (context, state) => const OcrScannerScreen(),
      ),
      GoRoute(
        path: '/file-tools/duplicate-finder',
        builder: (context, state) => const DuplicateFinderScreen(),
      ),
      GoRoute(
        path: '/file-tools/storage-analyzer',
        builder: (context, state) => const StorageAnalyzerScreen(),
      ),
      GoRoute(
        path: '/ai-tools',
        builder: (context, state) => const AiToolsScreen(),
      ),
      GoRoute(
        path: '/student-toolkit',
        builder: (context, state) => const StudentToolkitScreen(),
      ),
      GoRoute(
        path: '/docu-forge',
        builder: (context, state) => const DocuForgeHomeScreen(),
      ),
      GoRoute(
        path: '/pdf-viewer',
        builder: (context, state) {
          final doc = state.extra as Document;
          return PdfViewerScreen(document: doc);
        },
      ),
      GoRoute(
        path: '/images-to-pdf',
        builder: (context, state) => const ImagesToPdfScreen(),
      ),
      GoRoute(
        path: '/id-card-generator',
        builder: (context, state) => const IdCardGeneratorScreen(),
      ),
      GoRoute(
        path: '/business-toolkit',
        builder: (context, state) => const BusinessToolkitScreen(),
      ),
      GoRoute(
        path: '/business-analytics',
        builder: (context, state) => const BusinessAnalyticsScreen(),
      ),
      GoRoute(
        path: '/profit-calculator',
        builder: (context, state) => const ProfitCalculatorScreen(),
      ),
      GoRoute(
        path: '/invoice-generator',
        builder: (context, state) => const InvoiceGeneratorScreen(isGst: false),
      ),
      GoRoute(
        path: '/pos-billing',
        builder: (context, state) => const PosBillingScreen(),
      ),
      GoRoute(
        path: '/gst-billing',
        builder: (context, state) => const InvoiceGeneratorScreen(isGst: true),
      ),
      GoRoute(
        path: '/quotation-gen',
        builder: (context, state) => const QuotationGenScreen(),
      ),
      GoRoute(
        path: '/receipt-gen',
        builder: (context, state) => const ReceiptGenScreen(),
      ),
      GoRoute(
        path: '/business-card',
        builder: (context, state) => const BusinessCardScreen(),
      ),
      GoRoute(
        path: '/inventory-list',
        builder: (context, state) => const InventoryListScreen(),
      ),
      GoRoute(
        path: '/inventory-manager',
        builder: (context, state) => const InventoryManagerScreen(),
      ),
      GoRoute(
        path: '/inventory-scanner',
        builder: (context, state) {
          final inventory = state.extra as List<dynamic>? ?? [];
          return InventoryScannerScreen(inventory: inventory);
        },
      ),
      GoRoute(
        path: '/sales-tracker',
        builder: (context, state) => const SalesTrackerScreen(),
      ),
      GoRoute(
        path: '/business-expense-manager',
        builder: (context, state) => const ExpenseManagerScreen(),
      ),
      GoRoute(
        path: '/business-login',
        builder: (context, state) => const BusinessLoginScreen(),
      ),
      GoRoute(
        path: '/purchase-invoice',
        builder: (context, state) => const PurchaseInvoiceScreen(),
      ),
      GoRoute(
        path: '/create-profile',
        builder: (context, state) => const CreateProfileScreen(isEditing: false),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const CreateProfileScreen(isEditing: true),
      ),
      GoRoute(
        path: '/finance-tools',
        builder: (context, state) => const FinanceToolsScreen(),
      ),
      GoRoute(
        path: '/finance-tools/calculator',
        builder: (context, state) {
          final tool = state.extra as Map<String, dynamic>;
          return FinanceCalculatorScreen(tool: tool);
        },
      ),
      GoRoute(
        path: '/finance-tools/expense-tracker',
        builder: (context, state) {
          final tool = state.extra as Map<String, dynamic>;
          return ExpenseTrackerScreen(tool: tool);
        },
      ),
      GoRoute(
        path: '/social-tools',
        builder: (context, state) => const SocialToolsScreen(),
      ),
      GoRoute(
        path: '/social-tools/tool',
        builder: (context, state) {
          final tool = state.extra as Map<String, dynamic>;
          return SocialToolScreen(tool: tool);
        },
      ),
      GoRoute(
        path: '/health-lifestyle',
        builder: (context, state) => const HealthLifestyleScreen(),
      ),
      GoRoute(
        path: '/health-lifestyle/tool',
        builder: (context, state) {
          final tool = state.extra as Map<String, dynamic>;
          return HealthToolScreen(tool: tool);
        },
      ),
      GoRoute(
        path: '/productivity',
        builder: (context, state) => const ProductivityScreen(),
      ),
      GoRoute(
        path: '/productivity/tool',
        builder: (context, state) {
          final tool = state.extra as Map<String, dynamic>;
          return ProductivityToolScreen(tool: tool);
        },
      ),
      GoRoute(
        path: '/travel-tools',
        builder: (context, state) => const TravelToolsScreen(),
      ),
      GoRoute(
        path: '/travel/tool',
        builder: (context, state) {
          final tool = state.extra as Map<String, dynamic>;
          return TravelToolScreen(tool: tool);
        },
      ),
      GoRoute(
        path: '/form-builder',
        builder: (context, state) => const FormBuilderScreen(),
      ),
      GoRoute(
        path: '/create-form',
        builder: (context, state) {
          final formType = state.extra as String? ?? 'Survey';
          return CreateFormScreen(initialFormType: formType);
        },
      ),
      GoRoute(
        path: '/edit-form/:id',
        builder: (context, state) {
          final formType = state.extra as String? ?? 'Survey';
          final id = state.pathParameters['id']!;
          return CreateFormScreen(initialFormType: formType, formId: id);
        },
      ),
      GoRoute(
        path: '/my-forms',
        builder: (context, state) => const MyFormsScreen(),
      ),
      GoRoute(
        path: '/form-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FormDetailsScreen(formId: id);
        },
      ),
      GoRoute(
        path: '/submit-form/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SubmitFormScreen(formId: id);
        },
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
}
