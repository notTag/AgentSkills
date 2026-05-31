# todo

Display the `TODO.md` file with incomplete items sorted by priority at the top and completed items grouped at the bottom. Supports adding, completing, and prioritizing items.

## Usage
- `/todo` — display the sorted list (incomplete by priority on top, completed grouped at the bottom).
- `/todo add <text>` — append a new incomplete item; asks for priority if not specified.
- `/todo done <partial text>` — mark the matching item complete.
- `/todo priority <partial text> <P1|P2|P3|P4>` — update the priority tag on an item.

## Trigger
`/todo`, "show my todos", "add a todo", "complete a todo".
