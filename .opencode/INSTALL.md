# Installing Superpowers Brain for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

Add Superpowers Brain to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["superpowers-brain@git+https://github.com/Rob-Morris/superpowers.git"]
}
```

Restart OpenCode. That's it — the plugin auto-installs and registers all skills.

Verify by asking: "Tell me about your superpowers"

## Existing superpowers installs

No migration cleanup is required here. Existing `superpowers` installs and paths are outside the scope of this fork's install instructions and should be left alone. If you need to update or remove an upstream install, follow the upstream project's OpenCode guide: https://github.com/obra/superpowers/blob/main/docs/README.opencode.md

## Usage

Use OpenCode's native `skill` tool:

```
use skill tool to list skills
use skill tool to load superpowers-brain:brainstorming
```

## Updating

Superpowers Brain updates automatically when you restart OpenCode.

To pin a specific version:

```json
{
  "plugin": ["superpowers-brain@git+https://github.com/Rob-Morris/superpowers.git#v5.0.7"]
}
```

## Troubleshooting

### Plugin not loading

1. Check logs: `opencode run --print-logs "hello" 2>&1 | grep -i superpowers`
2. Verify the plugin line in your `opencode.json`
3. Make sure you're running a recent version of OpenCode

### Skills not found

1. Use `skill` tool to list what's discovered
2. Check that the plugin is loading (see above)

### Tool mapping

When skills reference Claude Code tools:
- `TodoWrite` → `todowrite`
- `Task` with subagents → `@mention` syntax
- `Skill` tool → OpenCode's native `skill` tool
- File operations → your native tools

## Getting Help

- Report issues: https://github.com/Rob-Morris/superpowers/issues
- Full documentation: https://github.com/Rob-Morris/superpowers/blob/main/docs/README.opencode.md
