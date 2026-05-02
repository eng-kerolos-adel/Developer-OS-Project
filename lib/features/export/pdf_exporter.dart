import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:developer_os/features/profile/domain/models/developer_profile.dart';
import 'package:developer_os/features/projects/domain/models/project.dart';

class PortfolioPDFExporter {
  // ميثود معالجة العربي - مضمونة ومجربة
  static String _fixText(String text) {
    if (text.isEmpty) return text;
    
    bool hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    if (!hasArabic) return text;

    final reshaper = ArabicReshaper();
    // تشكيل الحروف (Reshaping)
    String reshaped = reshaper.reshape(text);
    
    // عكس النص برمجياً لأن الـ PDF يعرضه معكوساً في بيئة LTR
    return reshaped.split('').reversed.join();
  }

  static Future<void> export({
    required DeveloperProfile profile,
    required List<DeveloperSkill> skills,
    required List<Project> projects,
    required List<Certificate> certs,
    required List<DeveloperLink> links,
    required List<String> techStacks,
  }) async {
    try {
      // تحميل الخط يدوياً من الـ Assets لضمان عدم حدوث Error في الـ Build
      final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
      final ttfBase = pw.Font.ttf(fontData);
      
      final fontBoldData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
      final ttfBold = pw.Font.ttf(fontBoldData);

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: ttfBase,
          bold: ttfBold,
        ),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          textDirection: pw.TextDirection.ltr, // الأساس إنجليزي
          header: (context) => _buildHeader(profile),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildAbout(profile),
            if (links.isNotEmpty) _buildLinks(links),
            pw.SizedBox(height: 15),
            if (techStacks.isNotEmpty) _buildTechStacks(techStacks),
            pw.SizedBox(height: 15),
            if (skills.isNotEmpty) _buildSkills(skills),
            pw.SizedBox(height: 15),
            if (projects.isNotEmpty) _buildProjects(projects),
            pw.SizedBox(height: 15),
            if (certs.isNotEmpty) _buildCertificates(certs),
          ],
        ),
      );

      // 1. حفظ الملف في التمب
      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final fileName = '${profile.name.replaceAll(' ', '_')}_Portfolio.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // 2. مشاركة الملف باستخدام share_plus (النسخة الحديثة)
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'My Professional Portfolio',
      );
      
    } catch (e) {
      // لإمساك أي خطأ متعلق بالـ Assets أو الـ File System
      print("PDF Export Error: $e");
    }
  }

  static pw.Widget _buildHeader(DeveloperProfile profile) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _fixText(profile.name),
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                if (profile.specialization != null)
                  pw.Text(_fixText(profile.specialization!), 
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.Text(profile.experienceLevel, style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (profile.location != null) pw.Text(_fixText(profile.location!), style: const pw.TextStyle(fontSize: 8)),
                pw.Text(profile.email, style: const pw.TextStyle(fontSize: 8)),
                if (profile.website != null) pw.Text(profile.website!, style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1, color: PdfColors.black),
      ],
    );
  }

  static pw.Widget _buildAbout(DeveloperProfile profile) {
    if (profile.bio == null || profile.bio!.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('About'),
        pw.Text(_fixText(profile.bio!), style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildTechStacks(List<String> techStacks) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tech Stack'),
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: techStacks.map((tech) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(3),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Text(tech, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          )).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildProjects(List<Project> projects) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Projects'),
        ...projects.map((p) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(_fixText(p.name), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text(p.status, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
              pw.Text(_fixText(p.description), style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Tools: ${p.techStack.join(", ")}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
        )),
      ],
    );
  }

  static pw.Widget _buildSkills(List<DeveloperSkill> skills) {
    final grouped = <String, List<DeveloperSkill>>{};
    for (var s in skills) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Skills'),
        ...grouped.entries.map((e) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: '${_fixText(e.key)}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.TextSpan(text: e.value.map((s) => _fixText(s.name)).join(', '), style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  static pw.Widget _buildLinks(List<DeveloperLink> links) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Links'),
        pw.Wrap(
          spacing: 12,
          children: links.map((l) => pw.Text('${l.label}: ${l.url}', 
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue700))).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildCertificates(List<Certificate> certs) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Certificates'),
        ...certs.map((c) => pw.Bullet(
          text: _fixText('${c.title} - ${c.issuer}'),
          style: const pw.TextStyle(fontSize: 9),
        )),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text('Page ${context.pageNumber}/${context.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 10),
        pw.Text(title.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 4),
      ],
    );
  }
}