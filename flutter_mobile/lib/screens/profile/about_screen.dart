import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/brand/medclues_logo_image.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: MedcluesLogoImage(size: MedcluesLogoSize.auth),
          ),
          const SizedBox(height: 20),
          Text(
            'About MEDCLUES',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Revolutionizing healthcare through modern technology and patient-centric solutions.',
            style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _section(
            context,
            title: 'Our Mission',
            body:
                'MEDCLUES transforms healthcare through innovation and technology. We help patients book appointments, access medical records, and connect with trusted doctors and hospitals — securely and conveniently.',
          ),
          _section(
            context,
            title: 'What We Offer',
            body:
                'Emergency services, doctor booking, video consultations, lab reports, payment history, and secure health records — all in one platform.',
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, {required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
