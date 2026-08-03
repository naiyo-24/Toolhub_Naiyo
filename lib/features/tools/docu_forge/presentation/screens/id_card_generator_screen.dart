import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:signature/signature.dart';

class IdCardGeneratorScreen extends StatefulWidget {
  const IdCardGeneratorScreen({super.key});

  @override
  State<IdCardGeneratorScreen> createState() => _IdCardGeneratorScreenState();
}

class _IdCardGeneratorScreenState extends State<IdCardGeneratorScreen> {
  final GlobalKey _globalKey = GlobalKey();
  
  // Form Data
  String _template = 'corporate';
  final TextEditingController _orgController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _authorizerRoleController = TextEditingController(text: 'CEO / Director');
  
  File? _profileImage;
  File? _signatureImage;
  File? _companyLogo;
  File? _authorizerSignature;

  Future<void> _pickImage(void Function(File) onPicked) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        onPicked(File(pickedFile.path));
      });
    }
  }

  Future<void> _openSignatureDialog(void Function(File) onSigned) async {
    final result = await showDialog<File>(
      context: context,
      builder: (context) => const _SignatureDialog(),
    );

    if (result != null) {
      setState(() {
        onSigned(result);
      });
    }
  }

  Future<void> _exportIdCard({required bool share}) async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/id_card_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        if (share) {
          // ignore: deprecated_member_use
          await Share.shareXFiles([XFile(file.path)], text: 'My ID Card');
        } else {
          final hasAccess = await Gal.hasAccess();
          if (!hasAccess) await Gal.requestAccess();
          await Gal.putImage(file.path);
          if (mounted) SnackbarUtils.showNeoSnackBar(context, message: 'ID Card saved to Gallery!');
        }
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Failed to export: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          title: Text('ID Card Generator', style: AppTextStyles.screenHeading.copyWith(color: Colors.white, fontSize: 24)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: AppColors.primaryYellow,
            tabs: [
              Tab(text: 'Enter Details', icon: Icon(Icons.edit_document)),
              Tab(text: 'Live Preview', icon: Icon(Icons.preview)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFormTab(),
            _buildPreviewTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  "1. Enter card details and select a template in this tab.\n2. Add optional logo and profile photo.\n3. Switch to 'Live Preview' tab to view and generate the ID.",
                  style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          NeoCard(
            backgroundColor: AppColors.primaryYellow,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Design Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _template,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'corporate', child: Text('Corporate Modern')),
                    DropdownMenuItem(value: 'school', child: Text('Classic School / College')),
                    DropdownMenuItem(value: 'minimal', child: Text('Minimalist')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _template = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          NeoCard(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Card Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                _buildTextField(_orgController, 'Organization/School Name', Icons.business),
                _buildTextField(_nameController, 'Full Name', Icons.person),
                _buildTextField(_idNumberController, 'ID Number / Roll No', Icons.badge),
                _buildTextField(_roleController, 'Designation / Class', Icons.work),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_dobController, 'DOB', Icons.cake)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(_bloodGroupController, 'Blood Grp', Icons.bloodtype)),
                  ],
                ),
                _buildTextField(_contactController, 'Contact / Phone', Icons.phone),
              ],
            ),
          ),
          const SizedBox(height: 20),
          NeoCard(
            backgroundColor: AppColors.primaryPink,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Media', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage((f) => _profileImage = f),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 8)),
                        icon: const Icon(Icons.add_a_photo, size: 20),
                        label: const Text('User Photo', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openSignatureDialog((f) => _signatureImage = f),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 8)),
                        icon: const Icon(Icons.draw, size: 20),
                        label: const Text('User Sign', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage((f) => _companyLogo = f),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 8)),
                        icon: const Icon(Icons.business, size: 20),
                        label: const Text('Org Logo', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openSignatureDialog((f) => _authorizerSignature = f),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 8)),
                        icon: const Icon(Icons.verified, size: 20),
                        label: const Text('Auth Sign', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _authorizerRoleController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Authorizer Role (e.g. CEO)',
                    prefixIcon: const Icon(Icons.stars, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                if (_profileImage != null || _signatureImage != null || _companyLogo != null || _authorizerSignature != null) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_profileImage != null)
                        const Chip(label: Text('Photo ✅'), backgroundColor: Colors.white),
                      if (_signatureImage != null)
                        const Chip(label: Text('User Sign ✅'), backgroundColor: Colors.white),
                      if (_companyLogo != null)
                        const Chip(label: Text('Logo ✅'), backgroundColor: Colors.white),
                      if (_authorizerSignature != null)
                        const Chip(label: Text('Auth Sign ✅'), backgroundColor: Colors.white),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildPreviewTab() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text('This is how your ID Card will look.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: RepaintBoundary(
              key: _globalKey,
              child: _buildIdCardTemplate(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportIdCard(share: true),
                  icon: const Icon(Icons.share_rounded, color: Colors.black),
                  label: const Text('SHARE', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportIdCard(share: false),
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text('SAVE TO LOCAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdCardTemplate() {
    // Basic shared values
    final org = _orgController.text.isEmpty ? 'YOUR ORGANIZATION' : _orgController.text.toUpperCase();
    final name = _nameController.text.isEmpty ? 'John Doe' : _nameController.text;
    final role = _roleController.text.isEmpty ? 'Employee' : _roleController.text;
    final idNum = _idNumberController.text.isEmpty ? 'ID-123456' : _idNumberController.text;
    
    // We constrain the ID card to standard vertical CR80 ratio (e.g. 2.125" x 3.375")
    const double cardWidth = 260;
    const double cardHeight = 413;

    if (_template == 'corporate') {
      return Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Header
              Container(
                height: 100,
                color: Colors.indigo.shade900,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 15, left: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_companyLogo != null) ...[
                      Image.file(_companyLogo!, height: 30),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(org, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              // Photo
              Positioned(
                top: 60,
                left: cardWidth / 2 - 45,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    image: _profileImage != null ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover) : null,
                  ),
                  child: _profileImage == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                ),
              ),
              // Details
              Positioned(
                top: 160,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(role, style: TextStyle(fontSize: 14, color: Colors.indigo.shade600, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    _buildDetailRow('ID', idNum),
                    _buildDetailRow('DOB', _dobController.text.isEmpty ? '01/01/1990' : _dobController.text),
                    _buildDetailRow('Blood', _bloodGroupController.text.isEmpty ? 'O+' : _bloodGroupController.text),
                    _buildDetailRow('Phone', _contactController.text.isEmpty ? '+1 234 567 8900' : _contactController.text),
                  ],
                ),
              ),
              // Signature
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        if (_signatureImage != null)
                          Image.file(_signatureImage!, height: 30)
                        else
                          Container(height: 30, alignment: Alignment.center, child: const Text('Signature', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                        Container(width: 70, height: 1, color: Colors.black),
                        const SizedBox(height: 4),
                        const Text('Holder', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      children: [
                        if (_authorizerSignature != null)
                          Image.file(_authorizerSignature!, height: 30)
                        else
                          Container(height: 30, alignment: Alignment.center, child: const Text('Signature', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                        Container(width: 70, height: 1, color: Colors.black),
                        const SizedBox(height: 4),
                        Text(_authorizerRoleController.text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_template == 'school') {
      return Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Container(
                color: Colors.red.shade700,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  children: [
                    if (_companyLogo != null)
                      Image.file(_companyLogo!, height: 40)
                    else
                      const Icon(Icons.school, color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(org, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade700, width: 2),
                  image: _profileImage != null ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover) : null,
                ),
                child: _profileImage == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
              ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              Text(role, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ID No:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(idNum, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Divider(indent: 20, endIndent: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('DOB:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(_dobController.text.isEmpty ? '01/01/2000' : _dobController.text, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                color: Colors.red.shade50,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        if (_signatureImage != null)
                          Image.file(_signatureImage!, height: 30)
                        else
                          const SizedBox(height: 30),
                        const Text('Student', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        if (_authorizerSignature != null)
                          Image.file(_authorizerSignature!, height: 30)
                        else
                          const SizedBox(height: 30),
                        Text(_authorizerRoleController.text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    } else {
      // Minimalist
      return Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(org, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(40),
                image: _profileImage != null ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover) : null,
              ),
              child: _profileImage == null ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            const SizedBox(height: 20),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w300)),
            Text(role.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 20),
            Text('ID: $idNum', style: const TextStyle(fontSize: 12)),
            Text('BLD: ${_bloodGroupController.text.isEmpty ? 'O+' : _bloodGroupController.text}', style: const TextStyle(fontSize: 12)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_signatureImage != null)
                  Image.file(_signatureImage!, height: 30)
                else
                  const SizedBox(height: 30, width: 50),
                if (_authorizerSignature != null)
                  Column(
                    children: [
                      Image.file(_authorizerSignature!, height: 30),
                      Text(_authorizerRoleController.text.toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  )
                else if (_companyLogo != null)
                  Image.file(_companyLogo!, height: 40)
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}

// Reusing SignatureDialog
class _SignatureDialog extends StatefulWidget {
  const _SignatureDialog();
  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Draw Signature'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Signature(
          controller: _signatureController,
          backgroundColor: Colors.grey.shade200,
        ),
      ),
      actions: [
        TextButton(onPressed: _signatureController.clear, child: const Text('Clear')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_signatureController.isNotEmpty) {
              final bytes = await _signatureController.toPngBytes();
              if (bytes != null) {
                final tempDir = await getTemporaryDirectory();
                final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
                await file.writeAsBytes(bytes);
                if (context.mounted) Navigator.pop(context, file);
              }
            } else {
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
