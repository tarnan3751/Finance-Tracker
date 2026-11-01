# Design system

Spendthrift prints in the **Riso** direction the owner chose (`PLAN.md` §12, 2026-11-02,
"Brand: Riso"; the board is on the branding canvas,
https://claude.ai/artifact/NWUqdjFVbQFFaDLJ3HgVaZ): two inks on paper, flat fills, an ink
line around what can be touched, one solid block per screen with its pink copy slipped
off register. This file is the system as code holds it: the tokens, the schemes, the
type, the component rules, the hero card, how to add a color, and the fonts' licences.
Where a screen composes these is each feature's own reference file.

## Where it lives

| What | Where |
|---|---|
| The tokens | `app/lib/core/theme/tokens.dart` (`SpendthriftTokens`) |
| The schemes, the type, the component themes | `app/lib/core/theme/app_theme.dart` (`AppTheme`) |
| The semantic colors and the chart inks | `app/lib/core/theme/finance_colors.dart` (`FinanceColors`) |
| The hero card, the empty state, amounts, avatars, the flavor banner | `app/lib/core/widgets/` |
| The demo strip | `app/lib/features/onboarding/presentation/demo_strip.dart` |
| The fonts and their licences | `app/assets/fonts/`, `app/lib/features/help/application/licenses.dart` |
| The launcher icon, the splash, the widgets' colors | `app/android/app/src/main/res/` (`build.md`, **Icon and splash**; `widgets.md`, **Colours**) |
| The tests | `app/test/core/theme/`, `app/test/core/widgets/hero_card_test.dart`, `empty_state_test.dart` |

## Tokens

`SpendthriftTokens`: radius 8 (cards, buttons, fields, the floating button), 16
(`radiusLarge`: sheets and dialogs), 999 (`radiusPill`: chips, the switchers, the
navigation indicator); the ink line 1.5 and the focus line 2; spacing 4, 8, 12, 16, 24,
32 (`space4` to `space32`); the misregistration 5 (the hero card's and the floating
button's pink copy) and 3 (`iconMisregistration`, an icon's); a chart's line 2.5
(`chartStroke`), a bar's top radius 4 (`barTopRadius`), an ink's tint 20 % (`tint`).
Elevation is zero everywhere, so there is no elevation token.

## Schemes

Both `ColorScheme`s are built by hand (`AppTheme.lightScheme`, `AppTheme.darkScheme`),
never from a seed, and carry no surface tint (`surfaceTint` transparent).

| Role | Light (paper) | Dark (night print) |
|---|---|---|
| surface / onSurface | `F7F3EA` / `1F1F1F` | `16151C` / `F1ECE1` |
| onSurfaceVariant | `5C574C` | `B5AFA3` |
| surfaceContainerLowest, Low, (plain), High, Highest | `FFFFFF`, `F3EEE3`, `EFE9DC`, `E9E2D3`, `E2DAC8` | `0F0E13`, `1B1A21`, `1F1E27`, `27262F`, `302F39` |
| primary / onPrimary | `1F4FE0` / `FFFFFF` | `8FA8FF` / `0E1230` |
| primaryContainer / on | `D6E0FF` / `0E1E60` | `2A3F8F` / `E0E7FF` |
| secondary / onSecondary | `FF3EA5` / `1F1F1F` | `FF7AC3` / `2A0A1C` |
| secondaryContainer / on | `FFD6EC` / `4A0A2B` | `6E1F4A` / `FFDCEE` |
| tertiary / onTertiary | `F2B705` / `1F1F1F` | `FFD24D` / `2A2000` |
| tertiaryContainer / on | `FFF0B8` / `3A2D00` | `5E4A00` / `FFF0B8` |
| error / onError | `C32237` / `FFFFFF` | `FF6B6B` / `3A0000` |
| errorContainer / on | `FFDAD9` / `410006` | `7A1C1C` / `FFDAD9` |
| outline (the ink line) / outlineVariant | `1F1F1F` / `B9B2A3` | `73727F` / `3A3944` |
| inverseSurface / on / inversePrimary | `1F1F1F` / `F7F3EA` / `8FA8FF` | `F1ECE1` / `16151C` / `1F4FE0` |

`FinanceColors`, the semantic extension both themes carry (`FinanceColors.of(context)`):

| Color | Light | Dark | Use |
|---|---|---|---|
| `inflow` | `19743E` | `5FD38B` | money in, as text |
| `outflow` | `BC2170` | `FF7AC3` | money out, as text |
| `warning` | `806000` | `FFD24D` | warning text (a budget near its limit) |
| `accent` | `FF3EA5` | `FF7AC3` | the pink overprint: the hero card's copy, the floating button's, an icon's; never body text on paper |
| `inks` | `1F4FE0`, `FF3EA5`, `F2B705`, `1E8A4A`, `1F1F1F` | `8FA8FF`, `FF7AC3`, `FFD24D`, `5FD38B`, `F1ECE1` | the charts: blue, pink, yellow, green, ink; `ink(i)` cycles, `tint(i)` is ink `i` at 20 % for bands and fills |

**Contrast.** Every text color reaches 4.5:1 on every surface up to
`surfaceContainerHigh`, light and dark, and every on-color on its color;
`app/test/core/theme/app_theme_test.dart` proves it, and the accessibility suite checks
every screen. The board's own text pink, green, yellow and red (`D6267F`, `1E8A4A`,
`B88A00`, `D7263D`) fall below 4.5:1 on paper (4.27, 3.96, 2.84, 4.48), so the text
colors above are the same hues darkened until they pass on `surfaceContainerHigh`; the
board's values stay where no text sits (the chart inks). `onSurfaceVariant`, which the
board leaves open, is a warm grey that passes on every container. The ink line
(`outline`) reaches 3:1 on `surface` and `surfaceContainerHigh` in both themes (WCAG
1.4.11: it is what marks a text field), so the night print's is `73727F` rather than the
board's `4A4955` (2.05:1); `outlineVariant`, for dividers, is decorative and stays. The
snack bar's action is the accent on ink in light, and on the night print's light inverse
surface the light theme's text pink (`BC2170`, 4.97:1).

**Dynamic color** stays a Settings switch, off by default, so the brand shows. When it is
on and the device has dynamic schemes (Android 12 and later), those replace both schemes
and every `FinanceColors` color is harmonized with the scheme's primary
(`FinanceColors.harmonized`, dynamic_color's `harmonizeWith`: the hue moves toward the
primary's by at most 15 degrees, the tone stays, so the contrast holds). A color the user
chose that a chart draws (a category's slice) goes through `FinanceColors.custom`:
harmonized toward the brand's blue with the brand schemes, toward the device's primary
with dynamic color.

## Type

Syne (700, 800) for the display and headline styles and `titleLarge` (800 for display,
700 otherwise, tracked at -0.02 em); Work Sans (400, 500, 600, 700) for `titleMedium` and
smaller, body and label styles, with tabular figures (`AppTheme.tabularFigures`) so
amounts line up; `ThemeData.fontFamily` is Work Sans. The sizes are Material 3's (the
theme's styles carry none; `Theme` merges in the script's geometry), so no layout grows.
`AmountText` sets its amount in Work Sans with tabular figures whatever the style's face:
every number is Work Sans. `AppTheme.figure(style)` is a money figure: Work Sans 700,
tabular, at the style's size (the net-worth headline, the hero card). Component themes
that take whole text styles (the navigation bar's and rail's labels, the list tile's
title) carry Material 3's English sizes under the theme's faces.

The fonts are static TTFs from Google Fonts under `app/assets/fonts/`, declared in
`app/pubspec.yaml` as the families `Syne` and `WorkSans`, with their OFL-1.1 licence
files (`Syne-OFL.txt`, `WorkSans-OFL.txt`) registered by `registerBundledLicenses()` for
Settings → About → Open-source licences beside Roboto's (the PDF report keeps Roboto,
whose bytes are a golden). The CI goldens obscure text as Ahem blocks but lay them out
with the bundled fonts' metrics, so a change of face or tracking moves them (the type
commit moved all 166, the text blocks some 10 to 20 % wider); the glyphs themselves are
seen only on a device.

## Components

All in `app_theme.dart`; elevation zero and no tint on every surface:

- **App bar** flat on paper, its title the Syne `titleLarge`, no scroll tint.
- **Navigation bar** paper with a 1.5 px ink top line (drawn by `AppShell`, which the bar's
  theme cannot), the indicator `primaryContainer`, the selected icon and label primary.
  The **rail** the same, with an ink divider beside it.
- **Card** paper with the ink-line border, radius 8, no margin: the screens space their
  cards.
- **List tile** a step tighter (vertical density -1), titles Work Sans 500; dividers
  `outlineVariant`.
- **Buttons** at radius 8: filled blue, outlined in ink, text in primary.
- **Segmented button** (the Plan and Insights switchers) ink-outlined pills, the selected
  segment filled blue with `onPrimary` text.
- **Chips** outlined pills in ink. **Fields** outlined in ink at radius 8, a 2 px blue
  focus line, errors in the error color.
- **Dialogs and sheets** paper, radius 16, ink border. **Menus and dropdown menus**
  paper, radius 8, ink border. The legacy `DropdownButtonFormField` popups (the bill,
  category, rule and transaction editors, the import mapping, the developer screen) take
  no theme: they are built with elevation 0 and carry no ink border until they move to
  `DropdownMenu`.
- **Snack bar** in ink (the inverse surface) with paper text and a pink action.
- **Progress** blue on an `outlineVariant` track; switches, checkboxes and radios blue
  through the scheme.
- **Floating button** a blue rounded square (radius 8) with its pink copy offset by the
  misregistration: its shape (`_MisregisteredBorder`) paints the copy where it shows past
  the button, so every floating button gets it through the theme and the copy never
  covers the button.

## The hero card and misregistration

`HeroCard` (`core/widgets/hero_card.dart`) is a screen's one solid block: primary blue,
radius 8, its text in paper (the scheme's surface); a `label` in Work Sans 600 capitals
tracked at 0.08 em (read by screen readers as written), a `figure` widget whose text
takes `AppTheme.figure` at the `headlineMedium` size, an optional `caption` and an
optional `trailing` widget at the end; the label, figure and caption are one semantics
node and the trailing widget is its own, so a button there stays a button. Its pink copy
is a second `DecoratedBox` in the accent, offset 5 down and to the end, not a shadow, so
it is flat and shows in the CI goldens. The Accounts screen's header is one (the totals
per currency, captioned by what they add); other screens take one each at most.

Misregistration is the brand's one ornament: the pink copy under the hero card and the
floating button (5), and under the empty state's icon (3, two `Icon`s, blue over pink).
Nothing else is offset, and nothing casts a shadow.

## Strips

The flavor banner (DEV, DEMO) is an ink strip with paper text (the inverse surface and
its on-color, so it stands out on the night print too); the demo strip (the demo in dev
and prod) is a pink strip (the secondary) with ink text and its Leave button
(`onSecondary`). Each sets the status bar's icons to black or white by real contrast
against it (`statusBarStyleOn`, in `flavor_banner.dart`; Material's estimate rates the
pink as dark), since both fill the status bar's area, and sets only the status bar's
fields, as an app bar does, so the navigation bar keeps its own.

## Charts

The fl_chart charts (`forecast_chart.dart`, `net_worth_chart.dart`,
`allocation_chart.dart`, `value_history.dart`, `report_charts.dart`) print in
`FinanceColors.inks`: a single series in blue; the forecast's band in the pink tint and
its lowest point in yellow; net worth in blue, assets in green and liabilities in pink;
income in green and spending in blue; the donuts' slices in the inks, then the scheme's
containers. Lines are 2.5, bars flat with a 4 px top radius, tooltips in ink with paper
text, axis labels Work Sans `labelSmall`, no grid. Every chart keeps its table.

## Adding a color

A color is a role, not a hex value at a call site: add it to the scheme when Material has
the role, else to `FinanceColors` (both the light and the dark value, `copyWith`, `lerp`
and `harmonized`), then pin it in `app_theme_test.dart` or `finance_colors_test.dart`,
and if text is drawn in it, add it to the contrast test's text colors. A color for text
must reach 4.5:1 on `surfaceContainerHigh`; darken the hue until it does rather than
using the board's value. The home-screen widgets and the splash keep their own copies in
`res/values*/` (`widget_colors.xml`, `colors.xml`), which change with the palette.

## Goldens

A change to a token, a scheme or a component theme moves most CI goldens (colors, shapes
and borders, and the faces' metrics too, since the obscured text blocks are laid out
with the bundled fonts): regenerate them on purpose with `CI=1 flutter test
--update-goldens --tags golden` in `app/` and look at a sample (`testing-tools.md`,
goldens). `hero_card_{light,dark}` and `empty_state_{light,dark}` are the system's own.
CI checks them on Linux with a tolerance for the anti-aliasing of the block ends and the
1.5 px ink lines (`testing-tools.md`, **Goldens**); a real change of colour or position
still fails.
