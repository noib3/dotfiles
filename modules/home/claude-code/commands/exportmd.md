Export the current conversation to a markdown file with the following requirements:

1. Remove all tool execution metadata (tool names, results, status indicators, etc.)
2. Keep only the conversational content (user messages and assistant responses)
3. Reflow all lines to a maximum width of 80 characters
4. Preserve markdown formatting (headers, code blocks, lists, etc.)
5. Save to a file named `conversation-export-YYYY-MM-DD.md` in the current directory

Format the output as clean markdown with:
- User messages prefixed with `## User`
- Assistant messages prefixed with `## Assistant`
- Proper spacing between message blocks
- Code blocks properly preserved with their language tags
- No metadata about tool calls, execution status, or system messages
