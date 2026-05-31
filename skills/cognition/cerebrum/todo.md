- Create setup.sh script (for bootstrapping)
- Include guidance for the AI to finalize setup when the skill is used for its very first time (separate file, tiny pointer for the AI to find, but easily if setup)
- Automate Hindsight installation & configuration + memory overwriting (all Hermes config, I assume, but we need to look at how to do this properly)


SKILL.md body section order and length. Hermes prescribes a specific structure: Skill title, 2-3 sentence intro stating what it does and doesn't do, ## When to Use, ## Prerequisites, ## How to Run, ## Quick Reference, ## Procedure, ## Pitfalls, ## Verification. Target ~200 lines for a complex skill, ~100 lines for a simple one. Our SKILL.md uses different headings (Anthropic-style). It'd need re-sectioning to match Hermes' order.

Description length cap. Hermes enforces a hard limit: assert len(m.group(1)) <= 60 on the description frontmatter. Our description is far longer than 60 chars (it's the Anthropic "pushy paragraph" style). This would fail Hermes' validator. That's a must-fix, and it's a meaningful divergence — Anthropic skills want verbose trigger-rich descriptions; Hermes wants ≤60 chars. 