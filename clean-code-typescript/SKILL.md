---
name: clean-code-typescript
description: Clean Code TypeScript practices for refactoring frontend React/Vue applications. Use when improving naming conventions, breaking down complex functions, organizing code structure, or eliminating code smells in existing TypeScript codebases.
---

# Clean Code TypeScript

Refactoring patterns for maintainable TypeScript in frontend applications

## When to Apply

- Refactoring functions with unclear names or multiple responsibilities
- Breaking down complex components into smaller, focused modules
- Eliminating magic numbers and improving variable naming
- Organizing import statements and file structure

## Critical Rules

**Meaningful Names**: Replace generic variables with descriptive ones

```typescript
// WRONG - requires mental mapping
const u = getUser();
const s = getSubscription();
const t = charge(u, s);

// RIGHT - explicit and searchable
const user = getUser();
const subscription = getSubscription();
const transaction = charge(user, subscription);
```

**Single Responsibility Functions**: Split functions doing multiple things

```typescript
// WRONG - handles filtering and action
function emailActiveClients(clients: Client[]) {
  clients
    .filter(client => database.lookup(client).isActive())
    .forEach(email);
}

// RIGHT - separate concerns
function emailActiveClients(clients: Client[]) {
  clients.filter(isActiveClient).forEach(email);
}

function isActiveClient(client: Client) {
  const clientRecord = database.lookup(client);
  return clientRecord.isActive();
}
```

**Named Constants**: Replace magic numbers with searchable constants

```typescript
// WRONG - what is 86400000?
setTimeout(restart, 86400000);

// RIGHT - self-documenting
const MILLISECONDS_PER_DAY = 24 * 60 * 60 * 1000;
setTimeout(restart, MILLISECONDS_PER_DAY);
```

## Key Patterns

### Function Decomposition

```typescript
// Extract single-level abstractions
function parseCode(code: string) {
  const tokens = tokenize(code);
  const syntaxTree = parse(tokens);
  return syntaxTree;
}

function tokenize(code: string): Token[] {
  const statements = code.split(' ');
  // tokenization logic
  return tokens;
}
```

### Class Organization

```typescript
// Separate data access from notifications
class UserService {
  constructor(private readonly db: Database) {}
  
  async getUser(id: number): Promise<User> {
    return await this.db.users.findOne({ id });
  }
}

class UserNotifier {
  constructor(private readonly emailSender: EmailSender) {}
  
  async sendWelcome(): Promise<void> {
    await this.emailSender.send('Welcome!');
  }
}
```

### Import Organization

```typescript
// Group and order imports consistently
import 'reflect-metadata';

import fs from 'fs';
import { Container } from 'inversify';

import { UserService } from '@services/UserService';
import { ApiCredentials } from './common/api/authorization';

import type { Customer } from '../model/types';
```

### Error Handling

```typescript
// Always use Error objects
function calculateTotal(items: Item[]): number {
  if (items.length === 0) {
    throw new Error('Cannot calculate total for empty items');
  }
  // calculation logic
}

// Handle promises properly
try {
  const user = await getUser();
  await sendEmail(user.email, 'Welcome!');
} catch (error) {
  logger.log(error);
}
```

## Common Mistakes

- **Boolean flags in parameters** — Split into separate functions instead
- **Generic variable names** — Use `user` not `u`, `transaction` not `t`
- **Multi-responsibility classes** — Extract cohesive services
- **Magic numbers** — Define named constants
- **Console.log for errors** — Use proper error logging