---
name: skill-builder
description: Build new LifeMaestro skills. USE WHEN user wants to create, design, or scaffold a new skill.
---

# Skill Builder

Meta-skill for creating new LifeMaestro skills following best practices.

## Variables
- enabled: true
- auto_scaffold: true

## Purpose
Help design and create new skills that follow LifeMaestro patterns:
- Progressive disclosure (SKILL.md → cookbook → tools)
- Shared tools between CLI and agent
- Token-efficient architecture
- Core Four principles (Context, Model, Prompt, Tools)

## Instructions

### When user wants to CREATE a new skill:

1. **First, gather requirements:**
   - What problem does this skill solve?
   - What's the trigger? (When should it activate?)
   - What tools/APIs does it need?
   - Should it be CLI, agent, or both?

2. **Read the principles:**
   - Read `CLAUDE.md` for skill development guidelines
   - Read `cookbook/skill-design.md` for architecture patterns

3. **Design the skill:**
   - Define the file structure
   - Plan the progressive disclosure
   - Identify shared tools

4. **Scaffold the skill:**
   - Run `tools/scaffold-skill.sh <name> [options]`
   - This creates the directory structure and templates

5. **Implement the skill:**
   - Edit SKILL.md with routing logic
   - Write cookbook documentation
   - Implement tool scripts

### When user wants to IMPROVE an existing skill:

1. Read the current skill files
2. Read `cookbook/skill-patterns.md` for best practices
3. Suggest improvements based on principles

## Examples

- "Create a skill for fetching weather" → Design + scaffold weather skill
- "Build a code review skill" → Design + scaffold code-review skill
- "Help me improve the ticket-lookup skill" → Analyze and suggest improvements
- "What's wrong with this skill?" → Review against best practices
