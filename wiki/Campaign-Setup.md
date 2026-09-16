# Campaign setup wizard

The local macOS/Linux wizard is a development feature for choosing Cosmere or D&D 5e content and managing local credential references. It does not yet provision a server, verify premium entitlement, install content, or create a world.

Follow the repository's [local campaign setup guide](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/docs/CAMPAIGN_SETUP.md) for installation, browser pairing, pasteable credential fields, OS-store configuration, recovery, validation, and the remaining release gates. That guide is the source of truth for current capability.

Saving requires an allowed macOS Keychain or Linux Secret Service/KWallet backend; there is no plaintext fallback. Deleting a local credential does not revoke it at its provider. Unknown entitlement blocks protected content. All six profiles require live qualification before full end-to-end support can be claimed.
