# NestJS DTOs with Missing class-validator Decorators

## The Silent Rejection Pattern

A DTO with **properties but zero decorators** will silently fail validation.
NestJS + class-validator treat undecorated properties as "nothing to validate"
and strip them from the request body — the controller receives an empty object
with no error.

## Real Example — TriggerSosDto

```typescript
// BROKEN — panic button never accepted a real request since launch
export class TriggerSosDto {
  alertType?: AlertType;      // no decorator → stripped from body
  locationLat?: number;        // no decorator → stripped from body
  locationLng?: number;        // no decorator → stripped from body
  locationDescription?: string; // no decorator → stripped from body
}
```

Every SOS request was silently discarded. No error, no crash, just nothing
happened. This shipped to production for weeks.

```typescript
// FIXED — add IsOptional + type validators
export class TriggerSosDto {
  @IsOptional()
  @IsEnum(AlertType)
  alertType?: AlertType;

  @IsOptional()
  @IsNumber()
  locationLat?: number;

  @IsOptional()
  @IsNumber()
  locationLng?: number;

  @IsOptional()
  @IsString()
  locationDescription?: string;
}
```

## Detection

```bash
# Find DTOs that may have no decorators
grep -L "@Is\|@IsOptional\|@IsString\|@IsNumber\|@IsEnum\|@ValidateNested" backend/src/**/dto/*.dto.ts
```

## Rule

Every DTO property must have at least `@IsOptional()`. Properties that are
NOT optional must have a type-specific validator (`@IsString()`, `@IsNumber()`,
`@IsEnum()`, etc.). A DTO with zero decorators anywhere is a bug.
