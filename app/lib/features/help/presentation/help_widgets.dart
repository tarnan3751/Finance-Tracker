/// The pieces the help and the privacy page are written in
/// (`docs/reference/onboarding.md`, **Help**): a heading, a paragraph and a list of
/// bullets, each from one ARB message, laid out to grow with the text size. No Markdown.
library;

import 'package:flutter/material.dart';

/// A heading inside a help page, read as one by screen readers.
class HelpHeading extends StatelessWidget {
  const HelpHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

/// A paragraph of a help page.
class HelpParagraph extends StatelessWidget {
  const HelpParagraph(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
  );
}

/// A list of bullets in a help page; screen readers read each item alone.
class HelpBullets extends StatelessWidget {
  const HelpBullets(this.items, {super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final String item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: SizedBox(width: 20, child: Text('•', style: style)),
                  ),
                  Expanded(child: Text(item, style: style)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
