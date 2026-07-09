# NestJS Guard Pitfalls

## @Public() at Class Level

**THE BUG:** When `@Public()` is applied to a controller **class**, it marks EVERY route as public — including routes that have `@UseGuards(JwtAuthGuard, RolesGuard)` at the method level. The `JwtAuthGuard` sees `isPublic = true` at the class level and returns immediately without setting `request.user`. Then `RolesGuard` finds `request.user = undefined` and throws `401 Unauthorized`.

**Root cause:** In NestJS, `Reflector.getAllAndOverride()` checks both method AND class metadata. Class-level `@Public()` overrides method-level guards.

**Wrong (causes the bug):**
```typescript
@Controller('v1/demo')
@Public()   // ← THIS MARKS EVERY ROUTE PUBLIC
export class DemoController {
  @Get('leads')
  @UseGuards(JwtAuthGuard, RolesGuard)  // ← IGNORED — class-level @Public() wins
  @Roles('super_admin')
  async getLeads() { ... }
}
```

**Correct:**
```typescript
@Controller('v1/demo')
export class DemoController {
  @Public()  // ← ONLY on the routes that need it
  @Get('slots')
  async getSlots() { ... }

  @Get('leads')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin')
  async getLeads() { ... }
}
```

**Diagnosis:** If you see `RolesGuard: "User not authenticated"` but `JwtAuthGuard` is definitely applied, add a log to the JwtAuthGuard's `isPublic` check. If it fires on a route that SHOULDN'T be public, the `@Public()` decorator is applied at the class level somewhere.

**Diagnostic code to add to JwtAuthGuard:**
```typescript
const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
  context.getHandler(),
  context.getClass(),
]);
if (isPublic) {
  this.logger.warn(`Route marked as PUBLIC — skipping auth for ${context.getHandler().name}`);
  return true;
}
```
This will appear in Rails logs as: `[JwtAuthGuard] Route marked as PUBLIC — skipping auth for getLeads`

## @Public() on `@Post('create')` in a class with NO class-level guard

Another pitfall: if a class has NO `@UseGuards()` at class level, and individual methods have `@Public()` and `@UseGuards()`, NestJS respects the method-level decorators correctly. The bug only occurs when `@Public()` is at the CLASS level.
