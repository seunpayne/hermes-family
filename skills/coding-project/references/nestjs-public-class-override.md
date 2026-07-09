# NestJS `@Public()` class-level override gotcha

## The bug

When `@Public()` is applied at the **controller class level**, it overrides ALL method-level
`@UseGuards(JwtAuthGuard)` — including routes that should require authentication.

```typescript
// ❌ BAD — @Public() at class level makes EVERY route public
@Controller('v1/demo')
@Public()  // ← this overrides everything below
export class DemoController {
  @Get('leads')
  @UseGuards(JwtAuthGuard, RolesGuard)  // ← IGNORED — still public
  @Roles('super_admin')
  async getLeads() { ... }
}

// ✅ GOOD — @Public() only on specific routes
@Controller('v1/demo')
export class DemoController {
  @Public()
  @Get('slots')
  async getSlots() { ... }

  @Get('leads')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin')
  async getLeads() { ... }
}
```

## How JwtAuthGuard checks for public

```typescript
// jwt-auth.guard.ts, canActivate()
const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
  context.getHandler(),   // method-level decorators
  context.getClass(),     // class-level decorators — THIS IS THE ISSUE
]);
if (isPublic) return true;  // skips ALL auth, request.user is never set
```

The `getAllAndOverride` checks both the handler (method) AND the class.
If EITHER has `@Public()`, the route is public. The class-level one
overrides method-level `@UseGuards()`.

## Diagnostic: "User not authenticated" from RolesGuard

When `JwtAuthGuard` skips (isPublic = true), it never sets `request.user`.
Then `RolesGuard` runs, finds `request.user === undefined`, and throws
`"User not authenticated"`.

To confirm this is the issue from a browser console (no Railway log access):

```js
// Add diagnostic to RolesGuard error:
throw new UnauthorizedException(
  `User not authenticated (user=${JSON.stringify(user)})`
);
```

- `user=undefined` → JwtAuthGuard never set it (isPublic or guard skipped)
- `user=null` → JwtAuthGuard set it to null (different bug)
- `user={"roles":[],"sub":"..."}` → JwtAuthGuard ran, roles are empty

## Detection

```bash
# Find all controllers with class-level @Public()
grep -B1 "@Public()" src/modules/*/ --include="*.controller.ts" | grep -A1 "@Controller"
```

## Fix

Remove `@Public()` from the class. Apply it ONLY to specific methods
that should be public (slots, request, webhook endpoints, etc.).

## Related

This is separate from the `@UseGuards()` method-vs-class overriding in NestJS
(which also applies — method-level guards REPLACE class-level guards).
The `@Public()` issue is specific to how the IS_PUBLIC_KEY metadata
propagates via `getAllAndOverride`.
