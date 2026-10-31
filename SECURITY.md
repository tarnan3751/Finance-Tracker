# Security policy

## Supported versions

Only the latest tagged release (the newest `v*` tag on the Releases page) receives fixes. An
older release is fixed by moving to the latest one.

## Reporting a vulnerability

Report a vulnerability privately through GitHub's private vulnerability reporting: open the
repository's **Security** tab and choose **Report a vulnerability**. Please do not open a public
issue, pull request or discussion for it. Include what you found, the version or commit, and the
steps that show it. The project has a single maintainer, who acknowledges a report as soon as
they can and keeps you informed until it is fixed or explained; the fix ships in a new release,
and you are credited in its notes unless you ask not to be.

## What the app sends

The app keeps its data on the device in an encrypted database whose key is held in the Android
Keystore, and it has no analytics, crash reporting or advertising code. Signed in, it talks to
the server you point it at and syncs your accounts, transactions, categories, budgets and other
records, and your receipt photos, so that your devices agree; the server, not the app, talks to
Plaid, and the app never holds a Plaid key. Two things go elsewhere. Linking a bank opens Plaid
Link, Plaid's own screen, which sends what you type there to Plaid. And a transaction from a
linked bank may carry a merchant logo address that Plaid supplies, which the app loads straight
from that address, so a signed-in device with linked transactions fetches those logos. The demo
sends nothing at all (its seeded transactions carry no logo addresses). A backup file leaves the
device only where you save or share it, encrypted with your passphrase.
[`PRIVACY.md`](PRIVACY.md) says in full what leaves the device and what does not.

## Scope

The development server in `server/` is never deployed by this project and is meant to run on
your own machine; a report about it is welcome, but its threat model is a local developer
server. Plaid's own SDK and service are Plaid's: report those to Plaid.
