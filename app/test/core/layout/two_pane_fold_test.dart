// The panes on a foldable: split on a vertical fold or hinge that is flat or half open
// (the start pane ends where it starts, the end pane starts where it ends), in either
// text direction, with the rail kept narrow; a horizontal fold, a folded foldable, a
// fold outside the panes or one leaving a pane too narrow for a list leaves the usual
// split.
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:finance_tracker/core/layout/two_pane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

const Key _start = Key('start');
const Key _end = Key('end');

/// A [TwoPane] [paneWidth] wide at the window's end edge of a window [size] wide with
/// [features], in [direction].
Widget _panes(
  Size size,
  double paneWidth,
  List<DisplayFeature> features, {
  TextDirection direction = TextDirection.ltr,
}) => MediaQuery(
  data: MediaQueryData(size: size, displayFeatures: features),
  child: Directionality(
    textDirection: direction,
    child: Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: paneWidth,
        height: size.height,
        child: const TwoPane(
          start: SizedBox.expand(key: _start),
          end: SizedBox.expand(key: _end),
        ),
      ),
    ),
  ),
);

Future<void> _pumpPanes(
  WidgetTester tester,
  Size size,
  double paneWidth,
  List<DisplayFeature> features, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    _panes(size, paneWidth, features, direction: direction),
  );
}

DisplayFeature _fold(
  Rect bounds, {
  DisplayFeatureType type = DisplayFeatureType.fold,
  DisplayFeatureState state = DisplayFeatureState.postureFlat,
}) => DisplayFeature(bounds: bounds, type: type, state: state);

void main() {
  testWidgets('a flat fold splits the panes on it', (tester) async {
    // The rail's 80 dp at the start, the panes the rest.
    await _pumpPanes(tester, foldSize, 761, [_fold(foldBounds)]);

    expect(tester.getRect(find.byKey(_start)).left, 80);
    expect(tester.getRect(find.byKey(_start)).right, 420.5);
    expect(tester.getRect(find.byKey(_end)).left, 421.5);
    expect(tester.getRect(find.byKey(_end)).right, 841);
  });

  testWidgets('a half-open hinge keeps both panes off it', (tester) async {
    const Rect hinge = Rect.fromLTWH(400, 0, 40, 701);
    await _pumpPanes(tester, foldSize, 761, [
      _fold(
        hinge,
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      ),
    ]);

    expect(tester.getRect(find.byKey(_start)).right, 400);
    expect(tester.getRect(find.byKey(_end)).left, 440);
  });

  testWidgets('right to left, the start pane is right of the fold', (
    tester,
  ) async {
    await tester.pumpWidget(
      _panes(foldSize, 761, [_fold(foldBounds)], direction: TextDirection.rtl),
    );

    expect(tester.getRect(find.byKey(_start)).left, 420.5);
    expect(tester.getRect(find.byKey(_start)).right, 761);
    expect(tester.getRect(find.byKey(_end)).left, 0);
    expect(tester.getRect(find.byKey(_end)).right, 419.5);
  });

  for (final (String name, List<DisplayFeature> features) in [
    ('no fold', const []),
    ('a horizontal fold', [_fold(const Rect.fromLTWH(0, 350, 1280, 0))]),
    (
      'a fold of unknown posture',
      [
        _fold(
          const Rect.fromLTWH(640, 0, 0, 800),
          state: DisplayFeatureState.unknown,
        ),
      ],
    ),
    ('a fold under the rail', [_fold(const Rect.fromLTWH(100, 0, 0, 800))]),
    (
      'a fold too close to the start for a list',
      [_fold(const Rect.fromLTWH(450, 0, 0, 800))],
    ),
    (
      'a cutout',
      [
        _fold(
          const Rect.fromLTWH(600, 0, 40, 800),
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        ),
      ],
    ),
  ]) {
    testWidgets('$name leaves the usual split', (tester) async {
      await _pumpPanes(tester, expandedSize, 1024, features);

      // Two fifths of 1024, within 320 and 440.
      expect(tester.getSize(find.byKey(_start)).width, 409.6);
      expect(tester.getRect(find.byKey(_end)).left, 256 + 409.6 + 1);
    });
  }

  testWidgets('the shell keeps the rail narrow on a fold and splits on it', (
    tester,
  ) async {
    tester.view.displayFeatures = [_fold(foldBounds)];
    addTearDown(tester.view.resetDisplayFeatures);
    await pumpApp(
      tester,
      size: foldSize,
      overrides: [storeOverride(seededStore())],
    );

    final NavigationRail rail = tester.widget(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    final Finder start = find.byWidgetPredicate(
      (w) => w is PaneScope && w.role == PaneRole.start,
    );
    expect(tester.getRect(start).right, 420.5);
  });

  testWidgets('a folded foldable shows one pane', (tester) async {
    // The outer display: no fold, a compact window.
    await pumpApp(
      tester,
      initialLocation: '/accounts/$checkingId',
      size: const Size(412, 900),
      overrides: [storeOverride(seededStore())],
    );

    expect(find.byType(PaneScope), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
