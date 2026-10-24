/// The persona engine's command line.
///
///     dart run persona_engine --persona <name> --seed <int> --output <dir>
///         [--format demo|sandbox-user|injection|all] [--days 730]
///         [--as-of 2026-10-24] [--no-interest-legs]
///
/// Writes the chosen outputs into `<dir>/<persona>/`. The as-of date defaults to the day
/// the goldens were generated, never to today, so a run is reproducible; the engine reads
/// no clock.
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';

/// The default as-of date: the date of the committed goldens.
const String defaultAsOf = '2026-10-24';

final ArgParser _parser = ArgParser()
  ..addOption(
    'persona',
    mandatory: true,
    allowed: [for (final p in PersonaId.values) p.slug],
    help: 'The household to generate.',
  )
  ..addOption('seed', mandatory: true, help: 'The seed, an integer.')
  ..addOption('output', mandatory: true, help: 'The directory to write into.')
  ..addOption(
    'format',
    defaultsTo: 'all',
    allowed: ['all', for (final f in OutputFormat.values) f.flag],
    help: 'Which outputs to write.',
  )
  ..addOption(
    'days',
    defaultsTo: '$maxWindowDays',
    help: 'The window length in days, 1 to $maxWindowDays.',
  )
  ..addOption(
    'as-of',
    defaultsTo: defaultAsOf,
    help: 'The window\'s last day, yyyy-MM-dd.',
  )
  ..addFlag(
    'interest-legs',
    defaultsTo: true,
    help:
        'Include card and loan interest charges in the Sandbox outputs '
        '(--no-interest-legs leaves them to Sandbox\'s own accrual).',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

Future<void> main(List<String> arguments) async {
  exitCode = await run(arguments, stdout, stderr);
}

/// Runs the command line with [arguments]; returns the exit code.
Future<int> run(List<String> arguments, IOSink out, IOSink err) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    out.writeln(_parser.usage);
    return 0;
  }
  final ArgResults args;
  final PersonaId persona;
  final String output;
  final int seed;
  final int days;
  final LocalDate asOf;
  try {
    args = _parser.parse(arguments);
    persona = PersonaId.fromSlug(args.option('persona')!);
    output = args.option('output')!;
    seed = int.parse(args.option('seed')!);
    days = int.parse(args.option('days')!);
    if (days < 1 || days > maxWindowDays) {
      throw FormatException('--days must be 1 to $maxWindowDays', '$days');
    }
    asOf = LocalDate.parse(args.option('as-of')!);
  } on ArgParserException catch (e) {
    err
      ..writeln('persona_engine: ${e.message}')
      ..writeln(_parser.usage);
    return 64;
  } on ArgumentError catch (e) {
    err
      ..writeln('persona_engine: ${e.message}')
      ..writeln(_parser.usage);
    return 64;
  } on FormatException catch (e) {
    err
      ..writeln(
        'persona_engine: ${e.message}${e.source == null ? '' : ': ${e.source}'}',
      )
      ..writeln(_parser.usage);
    return 64;
  }
  final format = args.option('format')!;
  final formats = format == 'all'
      ? {...OutputFormat.values}
      : {OutputFormat.values.firstWhere((f) => f.flag == format)};
  final files = renderOutputs(
    persona,
    seed: seed,
    asOf: asOf,
    days: days,
    formats: formats,
    includeInterestLegs: args.flag('interest-legs'),
  );
  final dir = Directory('$output/${persona.slug}');
  await dir.create(recursive: true);
  for (final entry in files.entries) {
    final file = File('${dir.path}/${entry.key}');
    await file.writeAsString(entry.value);
    out.writeln('${file.path} (${entry.value.length} bytes)');
  }
  return 0;
}
