YAML Wildcard Highlighter (injection)

This tiny extension injects a TextMate grammar into YAML files to give `$`-prefixed wildcard identifiers a dedicated scope: `variable.other.wildcard.renamer.yaml`.

How to use

1. In VS Code open the folder `c:\REAPER\reascripts` in the workspace (or add this extension folder to your workspace).
2. Run the Extension Development Host (`Run Extension` or press F5 in the extension debug view).
3. Open a YAML file containing `$animals` and use Developer: Inspect Editor Tokens and Scopes to confirm the token has the scope `variable.other.wildcard.renamer.yaml`.
4. Add a token color customization in your workspace settings to color that scope (example provided in the workspace `.vscode/settings.json`).

Notes
- This is a local, development-style extension. If you want to make it installable across machines, package it with `vsce`.

To Package .vsix

1. Update package versioning accordingly in package.json
2. Open 'C:\REAPER\reascripts\.vscode\extensions\yaml-wildcard-inject' in integrated terminal 
3. npx vsce package
4. code --install-extension .\yaml-wildcard-inject-0.0.1.vsix