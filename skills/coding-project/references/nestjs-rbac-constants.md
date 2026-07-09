# NestJS RBAC with Role Constants

## Problem

Controllers use inline `@Roles()` decorators with hardcoded role names. When a new role is added or the hierarchy changes, every controller must be updated individually. Inconsistent role checks lead to 401s ("Insufficient permissions") that are hard to debug.

## Solution: Centralised Role Constants

Create a single file that defines permission groups as arrays. All controllers reference these arrays.

### File: `backend/src/common/constants/roles.constants.ts`

```typescript
// Role hierarchy — higher roles inherit all permissions of lower roles
// super_admin > estate_admin > secretariat > security > resident > institution_admin

export const ADMIN_ROLES = ['super_admin', 'estate_admin'] as const;
export const STAFF_ROLES = ['super_admin', 'estate_admin', 'secretariat'] as const;
export const SECURITY_ROLES = ['super_admin', 'estate_admin', 'secretariat', 'security'] as const;
export const ALL_AUTHENTICATED = ['super_admin', 'estate_admin', 'secretariat', 'security', 'resident', 'institution_admin'] as const;
```

### Usage in Controllers

```typescript
import { ADMIN_ROLES, STAFF_ROLES, SECURITY_ROLES } from '../../common/constants/roles.constants';

@Controller('v1/compounds')
export class CompoundController {

  @Get()
  @Roles(...STAFF_ROLES)          // estate_admin, secretariat, super_admin
  async findAll() { ... }

  @Post()
  @Roles(...ADMIN_ROLES)          // super_admin, estate_admin only
  async create() { ... }
}
```

**Note:** `as const` makes the arrays readonly tuples. Spreading them with `@Roles(...STAFF_ROLES)` works correctly because the `@Roles()` decorator accepts `...roles: string[]`.

### Audit Checklist

When adding a new controller or endpoint:
1. Check the PRD role hierarchy — which roles need access?
2. Use the broadest constant that fits: prefer `ALL_AUTHENTICATED` > `STAFF_ROLES` > `ADMIN_ROLES`
3. Never inline `@Roles('secretariat')` without also including `estate_admin` and `super_admin`
4. Verify: `GET` with each role token returns 200 (not 403)

### Migration from Inline Roles

1. Create the constants file
2. For each controller, replace:
   ```typescript
   @Roles('secretariat')              →  @Roles(...STAFF_ROLES)
   @Roles('estate_admin')             →  @Roles(...ADMIN_ROLES)
   @Roles('estate_admin', 'secretariat', 'super_admin')  →  @Roles(...STAFF_ROLES)
   ```
3. Add import: `import { STAFF_ROLES, ADMIN_ROLES } from '../../common/constants/roles.constants';`
4. Run `npm run build` — verify zero errors
5. Run acceptance: `GET /v1/compounds` with each role token
