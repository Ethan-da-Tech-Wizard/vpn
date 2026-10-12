# WireGuard VPN Tools

WireGuard setup helpers, configuration templates, and a local Node.js administration dashboard.

**Status:** Administration-tool prototype  
**Built with:** Shell, WireGuard, Node.js, Express

[Project guide](docs/PROJECT_GUIDE.md) · [Every file explained](docs/FILE_GUIDE.md) · [Licenses and dependencies](docs/LICENSE_REVIEW.md)

## Start here

- [FREE_VPN_GUIDE.md](FREE_VPN_GUIDE.md) — Documentation: Complete Free & Secure WireGuard VPN Guide. Covers 🛡️ Why Self-Hosted WireGuard VPN?; 🔒 How This Protects You; ☁️ 100% Free Cloud Server Options.
- [setup.sh](setup.sh) — Command-line automation for setup; review prerequisites and side effects before executing.
- [manage-vpn.sh](manage-vpn.sh) — Command-line automation for manage vpn; review prerequisites and side effects before executing.
- [dashboard/server.js](dashboard/server.js) — Source module for server; defines `runCmd`.

[Detailed setup, usage, and development notes](PROJECT_NOTES.md) preserve the previous project documentation.

## Repository layout

| Path | Role |
| --- | --- |
| [config/](config/) | Configuration and templates (2 tracked entries). |
| [dashboard/](dashboard/) | Project-specific dashboard components (4 tracked entries). |
| [docs/](docs/) | Project documentation, decisions, and reference material (5 tracked entries). |

## Scope and current limits

No private keys are included. Setup scripts change networking and require careful review; the dashboard should not be exposed publicly without a separate authentication and deployment review.

## License

Original project code retains **MIT** terms in [LICENSE](LICENSE). Third-party libraries, media, data, models, and tools retain their own terms. See the [license review](docs/LICENSE_REVIEW.md) and [dependency inventory](docs/DEPENDENCIES.csv).
