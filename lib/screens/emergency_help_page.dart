import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/emergency_contacts.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Opens a link or a tel: address. Injected in tests so no real call starts.
typedef UriOpener = Future<bool> Function(Uri uri);

Future<bool> _openWithSystem(Uri uri) => launchUrl(uri);

/// Emergency numbers for India, with tap-to-call, copy, and the sources they
/// were checked against. Other countries are not shown, and the page says so.
class EmergencyHelpPage extends StatelessWidget {
  final UriOpener opener;

  const EmergencyHelpPage({super.key, this.opener = _openWithSystem});

  Future<void> _call(BuildContext context, EmergencyContact contact) async {
    final uri = Uri(scheme: 'tel', path: contact.dialDigits);
    await _open(context, uri, 'Could not open the phone app. Dial ${contact.number} on your phone instead.');
  }

  Future<void> _openSource(BuildContext context, EmergencySource source) async {
    await _open(context, Uri.parse(source.url), 'Could not open the link. Copy it from the list: ${source.url}');
  }

  Future<void> _open(BuildContext context, Uri uri, String failure) async {
    bool opened;
    try {
      opened = await opener(uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      showAppMessage(context, failure, error: true);
    }
  }

  Future<void> _copy(BuildContext context, EmergencyContact contact) async {
    await Clipboard.setData(ClipboardData(text: contact.number));
    if (context.mounted) showAppMessage(context, 'Copied ${contact.number}.');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final contacts = EmergencyDirectory.india;
    final emergency = contacts.first;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Emergency help')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              Container(
                key: const Key('emergency-top'),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.danger,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In an emergency in ${EmergencyDirectory.indiaName}, call ${emergency.number}.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tripora cannot place calls for you. Tapping Call opens your '
                      "phone's dialler on a phone.",
                      style: TextStyle(color: Colors.white, height: 1.4, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const Key('emergency-top-call'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: palette.danger,
                      ),
                      onPressed: () => _call(context, emergency),
                      icon: const Icon(Icons.call_rounded),
                      label: Text('Call ${emergency.number}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionHeader(
                title: 'Numbers for ${EmergencyDirectory.indiaName}',
                subtitle: 'Checked against official sources on ${EmergencyDirectory.checkedOn}.',
              ),
              const SizedBox(height: 12),
              for (final contact in contacts) ...[
                _ContactCard(
                  contact: contact,
                  onCall: () => _call(context, contact),
                  onCopy: () => _copy(context, contact),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                key: const Key('emergency-international-note'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.warningSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.warningBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.public_rounded, color: palette.warningText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        EmergencyDirectory.internationalNote,
                        style: TextStyle(color: palette.warningText, height: 1.45, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Other steps'),
              const SizedBox(height: 10),
              _Panel(
                children: const [
                  _Step('Get to a safe place, and ask people nearby for help.'),
                  _Step('Contact your embassy or consulate for lost passports, legal problems or urgent travel documents.'),
                  _Step('Block lost or stolen cards with your bank, using the number on the back of the card or on its official website.'),
                  _Step('Keep your travel insurer\'s 24-hour helpline written down offline. Tripora does not store your insurance details.'),
                ],
              ),
              const SizedBox(height: 18),
              const SectionHeader(
                title: 'Sources',
                subtitle: 'Tap a source to open it in your browser.',
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < _sources().length; i++) ...[
                Material(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    key: Key('source-$i'),
                    leading: Icon(Icons.open_in_new_rounded, color: palette.blue),
                    title: Text(
                      _sources()[i].title,
                      style: TextStyle(color: palette.text, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: Text(
                      _sources()[i].url,
                      style: TextStyle(color: palette.muted, fontSize: 11.5),
                    ),
                    onTap: () => _openSource(context, _sources()[i]),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static List<EmergencySource> _sources() => const [
        EmergencyDirectory.mhaSource,
        EmergencyDirectory.touristSource,
        EmergencyDirectory.ndmaSource,
      ];
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCall;
  final VoidCallback onCopy;

  const _ContactCard({required this.contact, required this.onCall, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contact.service,
            style: TextStyle(color: palette.text, fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          SelectableText(
            contact.number,
            key: Key('number-${contact.dialDigits}'),
            style: TextStyle(color: palette.danger, fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            contact.whenToCall,
            style: TextStyle(color: palette.muted, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: Key('call-${contact.dialDigits}'),
                onPressed: onCall,
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text('Call'),
              ),
              OutlinedButton.icon(
                key: Key('copy-${contact.dialDigits}'),
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy number'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final List<Widget> children;

  const _Panel({required this.children});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Step extends StatelessWidget {
  final String text;

  const _Step(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 18, color: palette.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: palette.text, height: 1.4, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}
