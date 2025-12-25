import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/app_helper.dart';
import '../l10n/app_localizations.dart';

class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      icon: const Icon(Icons.info_outline),
      onPressed: () {
        showAboutDialog(
          context: context,
          // Використовуємо системне поле для назви
          applicationName: AppHelper.getTitleByPlatform(),
          // Переносимо версію сюди — вона буде красиво під назвою
          applicationVersion: AppHelper.appVersion,
          applicationIcon: Image.asset(
            "lib/assets/images/solar-energy.png",
            width: 50,
          ),
          children: [
            const Divider(), // Розділювач одразу під назвою/версією
            Text(
              l10n.aboutDialogTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.aboutDialogMessage,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text('${l10n.authorInfo} ${l10n.author}'),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              children: [
                Text(l10n.gitHub),
                InkWell(
                  onTap: () => _launchUrl(l10n.githubUrl),
                  child: Text(
                    l10n.githubUrl,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Text(
              l10n.aboutDialogTitleDop,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.aboutDialogMessageSettingsBms,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              children: [
                Text(l10n.gitHub),
                InkWell(
                  onTap: () => _launchUrl(l10n.githubUrlSettingsBms),
                  child: Text(
                    l10n.githubUrlSettingsBms,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}