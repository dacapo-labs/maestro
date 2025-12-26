# Workflow Patterns

Official patterns from github.com/anthropics/skills for structuring skill workflows.

## Sequential Workflows

For complex tasks, break operations into clear, sequential steps. Give Claude an overview at the start:

```markdown
## Process Overview

Filling a PDF form involves these steps:

1. Analyze the form (run scripts/analyze_form.py)
2. Create field mapping (edit fields.json)
3. Validate mapping (run scripts/validate_fields.py)
4. Fill the form (run scripts/fill_form.py)
5. Verify output (run scripts/verify_output.py)
```

## Conditional Workflows

For tasks with branching logic, guide Claude through decision points:

```markdown
## Workflow

1. Determine the modification type:
   - **Creating new content?** → Follow "Creation workflow" below
   - **Editing existing content?** → Follow "Editing workflow" below

### Creation Workflow
1. Step one
2. Step two
3. Step three

### Editing Workflow
1. Step one
2. Step two
3. Step three
```

## Domain-Specific Organization

For skills with multiple domains, organize by domain to avoid loading irrelevant context:

```
bigquery-skill/
├── SKILL.md (overview and navigation)
└── references/
    ├── finance.md (revenue, billing metrics)
    ├── sales.md (opportunities, pipeline)
    ├── product.md (API usage, features)
    └── marketing.md (campaigns, attribution)
```

When user asks about sales, Claude only reads `references/sales.md`.

## Framework/Variant Organization

For skills supporting multiple frameworks:

```
cloud-deploy/
├── SKILL.md (workflow + provider selection)
└── references/
    ├── aws.md (AWS deployment patterns)
    ├── gcp.md (GCP deployment patterns)
    └── azure.md (Azure deployment patterns)
```

SKILL.md routes to the correct reference based on user's choice.

## Conditional Details Pattern

Show basic content, link to advanced:

```markdown
## Creating Documents

Use docx-js for new documents. Basic usage:
[simple example]

**For tracked changes**: See references/redlining.md
**For OOXML details**: See references/ooxml.md
```

Claude reads advanced docs only when needed.

## Guidelines

- **Avoid deeply nested references** - Keep one level deep from SKILL.md
- **Structure longer files** - Add table of contents for files >100 lines
- **Route clearly** - Make it obvious which reference to read for each case
