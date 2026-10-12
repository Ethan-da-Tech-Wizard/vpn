# License review — WireGuard VPN Tools

Reviewed 2026-10-12. Original project code retains **MIT** terms in [LICENSE](../LICENSE).

The owner selected MIT for previously unlicensed original code. Existing licenses were preserved. This choice does not relicense copied code, dependencies, datasets, model weights, fonts, logos, or game assets.

## Preserved notices

- [LICENSE](../LICENSE)

## Dependency evidence

[DEPENDENCIES.csv](DEPENDENCIES.csv) lists 102 manifest and lockfile records. Repeated packages can appear under different manifests, versions, or development scopes. Registry metadata is evidence, not a replacement for the actual license text. For unpinned ranges, `metadata_version` is the version inspected and is not a claim about every install. Go and system/build tools can require notices beyond package-manager metadata.

| Component | Declared version | License evidence |
| --- | --- | --- |
| npm: express | ^4.19.2 | [MIT](https://registry.npmjs.org/express/latest) |
| npm: qrcode | ^1.5.3 | [MIT](https://registry.npmjs.org/qrcode/latest) |
| npm: cors | ^2.8.5 | [MIT](https://registry.npmjs.org/cors/latest) |

## Project-specific considerations

No private keys are included. Setup scripts change networking and require careful review; the dashboard should not be exposed publicly without a separate authentication and deployment review.

## Remaining work before binary distribution

No unresolved registry-license lookup remains in the listed package records. System packages, downloaded tools/models, optional plugins, release binaries, and externally obtained assets need a build-specific inventory. This source review is not a blanket legal certification or a claim that every release artifact has been audited.
