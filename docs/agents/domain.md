# Domain Docs

This repo uses a single-context domain layout.

## Before exploring, read these

- `GLOSSARY.md` at the repo root.
- ADRs in `docs/adr/` that touch the area you are about to work in.

If these files do not exist, proceed silently. The `domain-modeling` skill creates them when terms or decisions are resolved.

## File structure

- `GLOSSARY.md`: shared domain vocabulary.
- `docs/adr/NNNN-<decision-slug>.md`: architecture decision records.

## Use the glossary's vocabulary

When naming a domain concept in an issue title, refactor proposal, hypothesis, or test name, use the term defined in `GLOSSARY.md`.

If a concept is missing, reconsider whether it belongs to the project's language. Note real vocabulary gaps for `domain-modeling`.

## Flag ADR conflicts

When a proposal contradicts an existing ADR, name the ADR and explain why the decision should be reopened.
