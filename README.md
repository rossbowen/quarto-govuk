# Quarto GOV.UK

A [Quarto](https://quarto.org/) extension that produces HTML documents styled with the [GOV.UK Design System](https://design-system.service.gov.uk/).


## Quick start

### Installation

```bash
quarto use template rossbowen/quarto-govuk
```

This will install the extension and create an example `.qmd` file to get started.

### Basic usage

Create a `.qmd` file with GOV.UK styling:

```yaml
---
title: "My GOV.UK Document"
subtitle: "A subtitle that describes the document"
author: "Your Name"
date: today
format: quarto-govuk-html
---

## Introduction

Your content here following the GOV.UK Design System.
```

Render your document:

```bash
quarto render document.qmd
```

## Document options

Configure your document in the YAML frontmatter:

```yaml
---
title: "Document Title"                  # Required: Main heading
subtitle: "Brief description"            # Optional: Appears under title
author: "Author Name"                    # Optional: Document author(s)
date: today                              # Optional: Publication date
date-modified: last-modified             # Optional: Last update date
format: quarto-govuk-html
toc: true                                # Optional: Table of contents
---
```

### Available metadata fields

| Field | Description | Example |
|-------|-------------|---------|
| `title` | Main document heading | `"Annual Report 2024"` |
| `subtitle` | Descriptive subtitle | `"Performance and outcomes"` |
| `author` | Author name(s) | `"Jane Smith"` or `["Jane Smith", "John Doe"]` |
| `date` | Publication date | `today` or `"2024-01-15"` |
| `date-modified` | Last modification | `last-modified` or `"2024-01-20"` |
| `toc` | Show table of contents | `true` or `false` |

## Components

This extension includes custom GOV.UK-styled components:

### Masthead

The masthead appears at the top of your document with the title and subtitle:

```yaml
---
title: "Your Title"
subtitle: "Your subtitle appears here"
---
```

### Metadata box

Document metadata (authors, dates) displays in a highlighted box:

```yaml
---
author: ["Author 1", "Author 2"]
date: "15 January 2024"
date-modified: "20 January 2024"
---
```

### Figures

Images with captions following GOV.UK styling:

```markdown
![This is the figure caption](images/chart.png)
```

### Code blocks

Syntax-highlighted code with copy buttons:

````markdown
```python
def hello():
    print("Hello, GOV.UK!")
```
````

### Tables

GOV.UK-styled tables:

```markdown
| Header 1 | Header 2 |
|----------|----------|
| Data 1   | Data 2   |
```

## Project structure

```
quarto-govuk/
├── _extensions/quarto-govuk/
│   ├── stylesheets/
│   │   ├── govuk-frontend.min.css       # GOV.UK Frontend framework
│   │   ├── quarto-govuk.css             # Custom components (entry point)
│   │   ├── syntax-highlighting.css      # Code syntax theme
│   │   └── components/                  # Component-specific styles
│   │       ├── masthead.css
│   │       ├── metadata.css
│   │       ├── figure.css
│   │       ├── code-block.css
│   │       ├── line-block.css
│   │       └── lists.css
│   ├── javascripts/
│   │   └── govuk-frontend.min.js        # GOV.UK Frontend JS
│   ├── assets/                          # GOV.UK Frontend assets
│   │   ├── fonts/
│   │   ├── images/
│   │   └── rebrand/
│   ├── template.html                    # Quarto template
│   ├── filter.lua                       # Pandoc filter
│   └── _extension.yml                   # Extension config
├── update-govuk-frontend.sh             # Update automation script
└── example.qmd                          # Example document
```

## Component naming convention

Following [GOV.UK Publishing Components conventions](https://components.publishing.service.gov.uk/component-conventions.html):

- `.app-c-*` - Components specific to this Quarto extension
- `.govuk-*` - Components from GOV.UK Frontend (don't modify)

### Adding custom components

1. Create a new file in `_extensions/quarto-govuk/stylesheets/components/`
2. Use the `.app-c-your-component` naming pattern
3. Import it in `quarto-govuk.css`:
   ```css
   @import "components/your-component.css";
   ```
4. Add it to resources in `filter.lua`

See [stylesheets/components/README.md](_extensions/quarto-govuk/stylesheets/components/README.md) for details.

## Development

### Requirements

- [Quarto](https://quarto.org/) >= 1.3.0
- Bash shell (for update script)

### Building from source

1. Clone the repository:
   ```bash
   git clone https://github.com/rossbowen/quarto-govuk.git
   cd quarto-govuk
   ```

2. Test the extension:
   ```bash
   quarto render example.qmd
   ```

3. Make your changes to components in `_extensions/quarto-govuk/`

4. Test your changes:
   ```bash
   quarto render example.qmd
   ```


### Maintaining GOV.UK frontend

This extension includes automated tools to keep GOV.UK Frontend up to date.

#### Updating to latest version

```bash
./update-govuk-frontend.sh
```

#### Updating to specific version

```bash
./update-govuk-frontend.sh 5.13.0
```

#### What the update script does

The automated update process:

1. **Fetches** the latest (or specified) release from [alphagov/govuk-frontend](https://github.com/alphagov/govuk-frontend)
2. **Downloads** and extracts release assets
3. **Backs up** existing GOV.UK Frontend files to `.govuk-backups/` (keeps 3 most recent)
4. **Installs** new files:
   - CSS framework
   - JavaScript modules
   - Assets (fonts, images, icons)
5. **Fixes** asset paths for Quarto's structure
6. **Updates** source map references
7. **Records** version in `_extensions/quarto-govuk/.govuk-frontend-version`
8. **Cleans up** temporary files

**Note:** Your custom components in `stylesheets/components/` are never touched by the update script.

#### Checking your version

```bash
cat _extensions/quarto-govuk/.govuk-frontend-version
```

### Testing updates

Before committing updates to GOV.UK Frontend:

1. Run the update script:
   ```bash
   ./update-govuk-frontend.sh
   ```

2. Test with example document:
   ```bash
   quarto render example.qmd
   ```

3. Check the rendered output in your browser

4. If there are issues, restore from backup:
   ```bash
   ls .govuk-backups/
   # Manually restore files from the most recent backup
   ```

## Resources

### GOV.UK Design System
- [Design System](https://design-system.service.gov.uk/)
- [Frontend Toolkit](https://github.com/alphagov/govuk-frontend)
- [Component Conventions](https://components.publishing.service.gov.uk/component-conventions.html)

### Quarto
- [Quarto Documentation](https://quarto.org/)
- [Creating Formats](https://quarto.org/docs/extensions/formats.html)
- [Lua Filters](https://quarto.org/docs/extensions/lua.html)
- [Pandoc Templates](https://pandoc.org/MANUAL.html#templates)

## License

MIT License - see [LICENSE](LICENSE) for details.

This project builds upon:
- [GOV.UK Frontend](https://github.com/alphagov/govuk-frontend) - MIT License
- [Quarto](https://github.com/quarto-dev/quarto-cli) - GPL v2

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Example

See [example.qmd](example.qmd) for a complete example document demonstrating all features.

