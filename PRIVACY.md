# Privacy

This page says what leaves your device and what stays on it.

## With your own server

When you use your own server, these go off the device, and only to the places named:

- Your changes and settings, to the server you set up, so your devices stay in step.
- This device's model name, to that server, as the device's name in your list of devices.
- The receipt photos you attach, stored on that server so your other devices can show them.
- Bank data does not come from this device: your server pulls it from Plaid. The app itself never calls Plaid's API.
- Linking a bank opens Plaid Link, Plaid's own screen, which talks to Plaid directly. Your bank sign-in goes to Plaid, not to the app or your server.
- Merchant logos are loaded from the addresses Plaid supplies, so Plaid's logo host sees this device's requests.

Nothing goes to anyone else.

## What stays on this device

- The app's own code has no analytics, crash reporting or advertising. Plaid Link is Plaid's component, and while it is open it may send its own diagnostics to Plaid.
- The app does not write amounts, merchants or tokens to its log, and the release app keeps its log on the device, with tokens and email addresses removed.
- The database is encrypted, with its key kept by Android's keystore.
- Android's automatic backup of the app's data is turned off.
- A backup is encrypted with your passphrase and goes only where you save or share it.
- Notifications and reminders are scheduled on the device itself.

## In the demo

Nothing leaves the device. The sample households are made up on the device, and no account or server is involved.
