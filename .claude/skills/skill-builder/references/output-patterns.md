# Output Patterns

Official patterns from github.com/anthropics/skills for producing consistent, high-quality output.

## Template Pattern

Provide templates for output format. Match strictness to requirements.

### Strict Template (for API responses, data formats)

```markdown
## Report Structure

ALWAYS use this exact template:

# [Analysis Title]

## Executive Summary
[One-paragraph overview of key findings]

## Key Findings
- Finding 1 with supporting data
- Finding 2 with supporting data
- Finding 3 with supporting data

## Recommendations
1. Specific actionable recommendation
2. Specific actionable recommendation
```

### Flexible Template (when adaptation is useful)

```markdown
## Report Structure

Here is a sensible default format, but use your best judgment:

# [Analysis Title]

## Executive Summary
[Overview]

## Key Findings
[Adapt sections based on what you discover]

## Recommendations
[Tailor to the specific context]

Adjust sections as needed for the specific analysis type.
```

## Examples Pattern

For skills where quality depends on seeing examples, provide input/output pairs:

```markdown
## Commit Message Format

Generate commit messages following these examples:

**Example 1:**
Input: Added user authentication with JWT tokens
Output:
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware

**Example 2:**
Input: Fixed bug where dates displayed incorrectly in reports
Output:
fix(reports): correct date formatting in timezone conversion

Use UTC timestamps consistently across report generation

Follow this style: type(scope): brief description, then detailed explanation.
```

**Why examples work:** They help Claude understand desired style and detail level more clearly than descriptions alone.

## Structured Output Pattern

For machine-readable output:

```markdown
## Output Format

Return results as JSON:

{
  "status": "success" | "error",
  "data": {
    "field1": "value",
    "field2": "value"
  },
  "errors": []
}

Always include all fields, even if empty.
```

## Quality Checklist Pattern

For outputs requiring validation:

```markdown
## Before Returning Output

Verify:
- [ ] All required sections present
- [ ] No placeholder text remaining
- [ ] Data is accurate and cited
- [ ] Format matches specification
- [ ] No sensitive information exposed
```

## Progressive Detail Pattern

For outputs that may need varying detail:

```markdown
## Output Detail Levels

**Summary** (default): 2-3 sentences
**Standard**: 1-2 paragraphs with key points
**Detailed**: Full analysis with supporting data

Ask user preference if unclear, default to Standard.
```
