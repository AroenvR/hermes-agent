Set defaults or provide a guide for the setup process:

---

$ podman exec -it hermes-gateway hermes setup

┌─────────────────────────────────────────────────────────┐
│             ⚕ Hermes Agent Setup Wizard                │
├─────────────────────────────────────────────────────────┤
│  Let's configure your Hermes Agent installation.       │
│  Press Ctrl+C at any time to exit.                     │
└─────────────────────────────────────────────────────────┘


◆ Reconfigure
✓ You already have Hermes configured.
  Running the full wizard — each prompt shows your current value.
  Press Enter to keep it, or type a new value to change it.
  
  Tip: jump straight to a section with 'hermes setup model|terminal|
       gateway|tools|agent', or fill only missing items with --quick.

◆ Configuration Location
  Config file:  /home/hermes/.hermes/config.yaml
  Secrets file: /home/hermes/.hermes/.env
  Data folder:  /home/hermes/.hermes
  Install dir:  /home/hermes/.hermes/hermes-agent

  You can edit these files directly or use 'hermes config edit'

◆ Inference Provider
  Choose how to connect to your main chat model.
     Guide: https://hermes-agent.nousresearch.com/docs/integrations/providers


  Current model:    gpt-5.5
  Active provider:  OpenAI Codex


  OpenAI Codex credentials: ✓

    1. Use existing credentials
    2. Reauthenticate (new OAuth login)
    3. Cancel

  Choice [1/2/3]: 1

Default model set to: gpt-5.5 (via OpenAI Codex)


◆ Text-to-Speech Provider (optional)
  Current: Edge TTS

    Skipped (keeping current)


◆ Terminal Backend
  Choose where Hermes runs shell commands and code.
  This affects tool execution, file access, and isolation.
     Guide: https://hermes-agent.nousresearch.com/docs/developer-guide/environments

    Skipped (keeping current)

  Keeping current backend: local

◆ Agent Settings
     Guide: https://hermes-agent.nousresearch.com/docs/user-guide/configuration

  Maximum tool-calling iterations per conversation.
  Higher = more complex tasks, but costs more tokens.
  Press Enter to keep 120. Use 90 for most tasks or 150+ for open exploration.
Max iterations [120]: 120
✓ Max iterations set to 120
  
  Tool Progress Display
  Controls how much tool activity is shown (CLI and messaging).
    off     — Silent, just the final response
    new     — Show tool name only when it changes (less noise)
    all     — Show every tool call with a short preview
    verbose — Full args, results, and debug logs
Tool progress mode [new]: all
✓ Tool progress set to: all

◆ Context Compression
  Automatically summarizes old messages when context gets too long.
  Higher threshold = compress later (use more context). Lower = compress sooner.
Compression threshold (0.5-0.95) [0.5]:     
✓ Context compression threshold set to 0.5

◆ Session Reset Policy
  Messaging sessions (Telegram, Discord, etc.) accumulate context over time.
  Each message adds to the conversation history, which means growing API costs.
  
  To manage this, sessions can automatically reset after a period of inactivity
  or at a fixed time each day. When a reset happens, the agent saves important
  things to its persistent memory first — but the conversation context is cleared.
  
  You can also manually reset anytime by typing /reset in chat.
  
    Skipped (keeping current)

  Inactivity timeout (minutes) [720]: 
  Daily reset hour (0-23, local time) [2]: 
✓ Sessions reset after 720 min idle or daily at 2:00

◆ Messaging Platforms
  Connect to messaging platforms to chat with Hermes from anywhere.
  Toggle with Space, confirm with Enter.


◆ Telegram
  Telegram: already configured
Reconfigure Telegram? [y/N]: N

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Messaging platforms configured!

  Restart the gateway to pick up changes? [Y/n]: n
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚕ Hermes Tool Configuration
  Enable or disable tools per platform.
  Tools that need API keys will be configured when enabled.
  Guide: https://hermes-agent.nousresearch.com/docs/user-guide/features/tools

  - 🖱️  Computer Use (macOS)
  - kanban
  ✓ Saved 🖥️  CLI configuration


  Tool configuration saved to ~/.hermes/config.yaml
  Changes take effect on next 'hermes' or gateway restart.

  Previous config backed up to: /home/hermes/.hermes/config.yaml.bak.20260531_172214
  If setup changed a value you customized, restore it with:
    cp /home/hermes/.hermes/config.yaml.bak.20260531_172214 /home/hermes/.hermes/config.yaml


◆ Tool Availability Summary
  7/10 tool categories available:

   ✓ Vision (image analysis)
   ✗ Mixture of Agents (missing OPENROUTER_API_KEY)
   ✗ Web Search & Extract (missing EXA_API_KEY, PARALLEL_API_KEY, FIRECRAWL_API_KEY/FIRECRAWL_API_URL, TAVILY_API_KEY, or SEARXNG_URL)
   ✓ Browser Automation (Local browser)
   ✓ Image Generation (OpenAI (Codex auth))
   ✓ Text-to-Speech (Edge TTS)
   ✗ Skills Hub (GitHub) (missing GITHUB_TOKEN)
   ✓ Terminal/Commands
   ✓ Task Planning (todo)
   ✓ Skills (view, create, edit)

⚠ Some tools are disabled. Run 'hermes setup tools' to configure them,
⚠ or edit ~/.hermes/.env directly to add the missing API keys.


┌─────────────────────────────────────────────────────────┐
│              ✓ Setup Complete!                          │
└─────────────────────────────────────────────────────────┘
