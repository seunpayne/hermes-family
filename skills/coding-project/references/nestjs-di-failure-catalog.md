# NestJS Dependency Injection Failure Catalog

All fatal startup errors from NestJS DI that hit the controller init phase.
Each failure halts the container with a pattern you can match in ~5s from the log.

---

## 1. UnknownExportException

### Pattern
```
UnknownExportException: Nest cannot export a provider/module that is not
a part of the currently processed module (NotificationModule).
Please verify whether the exported EmailService is available in this
particular context.
```

### Root cause
`exports: [EmailService]` but `providers: [...]` doesn't include `EmailService`.

### Fix
```typescript
providers: [NotificationService, EmailService],  // ← add missing provider
exports: [NotificationService, EmailService],     // ← matches
```

### Detection
```bash
grep -A2 "exports:" module.ts | grep -v "exports:" | grep -v "^$" > /tmp/exports.txt
grep -A2 "providers:" module.ts | grep -v "providers:" | grep -v "^$" > /tmp/providers.txt
diff /tmp/exports.txt /tmp/providers.txt  # anything in exports but not providers = bug
```

---

## 2. UnknownDependenciesException (missing module import)

### Pattern
```
UnknownDependenciesException: Nest can't resolve dependencies of the
SOSController (SOSService, ?). Please make sure that the argument
ResidentsService at index [1] is available in the SOSModule context.

Potential solutions:
- If ResidentsService is exported from a separate @Module, is that module
  imported within SOSModule?
  @Module({ imports: [ /* the Module containing ResidentsService */ ] })
```

### Root cause
A controller injects a service owned by another module, but the consuming
module doesn't import the provider's module. NestJS cannot resolve
cross-module providers without an explicit import.

### Fix
```typescript
// Add import statement
import { ResidentsModule } from '../resident/residents.module';

// Add to @Module decorator
@Module({
  imports: [NotificationModule, ResidentsModule, PrismaModule],
  // ...
})
```

### Pre-flight check
When adding `private readonly otherService: OtherService` to a controller:
```bash
# 1. Find which module owns the service
grep -r "OtherService" --include="*.module.ts" backend/src/ | grep "providers"

# 2. Verify that module exports the service
grep "exports.*OtherService" path/to/module.module.ts

# 3. Verify the consuming module imports it
grep "imports.*OtherModule" this-module.module.ts
```

---

## 3. @Public() on controller class (not method)

### Pattern
```
Nest can't resolve dependencies of the ContactController (?).
Please make sure that the argument Object at index [0] is available...

user=undefined, authInfo=false, headers=true
```

### Root cause
`@Public()` at the controller CLASS level applies to ALL methods.
JwtAuthGuard skips entirely → `request.user` is never set.
RolesGuard throws "User not authenticated" because `request.user` is undefined.

### Fix
```typescript
// BEFORE — @Public() on class, all routes bypass auth
@Public()
@Controller('demo')
export class DemoController { ... }

// AFTER — @Public() only on specific methods
@Controller('demo')
export class DemoController {
  @Public() @Post('waitlist')  // this route is public
  async waitlist() { ... }

  @UseGuards(JwtAuthGuard)     // this route requires auth
  @Get('slots')
  async getSlots() { ... }
}
```

### Detection
```bash
grep -n "@Public()" controller.ts | head -3
# If it appears near @Controller (line 2-5), not on a method (line 20+),
# it's a class-level override and will break auth.
```

---

## Quick Triage Table

| Error text substring | Failure | Fix |
|---|---|---|
| `cannot export a provider/module` | Export without provide | Add to providers |
| `can't resolve dependencies` + `at index [N]` | Missing module import | Add module to imports |
| `can't resolve dependencies` + `at index [0]` + no deps | @Public() on class | Move to methods |
| `is not available in the current context` | Same as #2 | Add module import |
