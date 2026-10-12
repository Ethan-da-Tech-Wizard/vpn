# WireGuard VPN Tools

WireGuard setup helpers, configuration templates, and a local Node.js administration dashboard.

**Status:** Administration-tool prototype  
**Built with:** Shell, WireGuard, Node.js, Express

## Reading order

1. Read the root README for project purpose and setup navigation.
2. Follow the entry points below to find the implementation.
3. Use the file guide to locate individual modules, tests, assets, and configuration.
4. Check component licenses before redistributing dependencies or assets.

## Important paths

- [FREE_VPN_GUIDE.md](../FREE_VPN_GUIDE.md) — Documentation: Complete Free & Secure WireGuard VPN Guide. Covers 🛡️ Why Self-Hosted WireGuard VPN?; 🔒 How This Protects You; ☁️ 100% Free Cloud Server Options.
- [setup.sh](../setup.sh) — Command-line automation for setup; review prerequisites and side effects before executing.
- [manage-vpn.sh](../manage-vpn.sh) — Command-line automation for manage vpn; review prerequisites and side effects before executing.
- [dashboard/server.js](../dashboard/server.js) — Source module for server; defines `runCmd`.

## Structure

| Path | Role |
| --- | --- |
| [config/](../config/) | Configuration and templates (2 tracked entries). |
| [dashboard/](../dashboard/) | Project-specific dashboard components (4 tracked entries). |
| [docs/](../docs/) | Project documentation, decisions, and reference material (5 tracked entries). |

## Scope

No private keys are included. Setup scripts change networking and require careful review; the dashboard should not be exposed publicly without a separate authentication and deployment review.

## Maintaining the guide

The file catalog is a source-inspection snapshot, not proof that every runtime path works. Update it when moving files or changing module responsibilities. The 2026-10-12 documentation review did not run every application, deploy services, or validate all historical performance claims.
