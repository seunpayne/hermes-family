# NestJS Multi-Tenant Architecture Patterns

Multi-tenancy is a common requirement for SaaS projects. This file captures the patterns used in the Streetwise build.

## Approach: Discriminator Column (community_id)

Every entity has a `communityId` foreign key to the Community (tenant root) table. All queries filter by this column.

**Schema pattern:**
```prisma
model Community {
  id    String    @id @default(cuid())
  name  String
  slug  String    @unique
  // ... tenant-specific fields

  compounds   Compound[]
  residents   Resident[]
  // ... all other entity relations
}

model Compound {
  id          String   @id @default(cuid())
  communityId String
  // ... entity-specific fields

  community   Community @relation(fields: [communityId], references: [id], onDelete: Cascade)

  @@index([communityId])
}
```

## RLS Equivalent: Application-Layer Middleware

In NestJS, use middleware to attach `communityId` to every request:

```typescript
// community-scope.middleware.ts
@Injectable()
export class CommunityScopeMiddleware implements NestMiddleware {
  use(req: Request & { communityId?: string }, _res: Response, next: NextFunction) {
    // Priority 1: JWT payload
    const token = req.headers.authorization?.split(' ')[1];
    if (token) {
      try {
        const payload = JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString());
        if (payload?.community_id) req.communityId = payload.community_id;
      } catch { /* fall through */ }
    }
    // Priority 2: x-community-id header (dev)
    if (!req.communityId && req.headers['x-community-id'])
      req.communityId = req.headers['x-community-id'] as string;
    next();
  }
}
```

Apply globally in AppModule:
```typescript
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(CommunityScopeMiddleware).forRoutes('*');
  }
}
```

## Controller Pattern

Every controller method receives `communityId` from middleware and passes it to the service:

```typescript
@Get()
@Roles('estate_admin')
findAll(@Req() req: any, @Query('page') page?: string) {
  return this.service.findAll(req.communityId, page ? parseInt(page) : 1);
}
```

## Service Pattern

Every service method takes `communityId` as its first parameter and includes it in all Prisma queries:

```typescript
async findAll(communityId: string, page = 1, limit = 20) {
  return this.prisma.compound.findMany({
    where: { communityId },
    // ... pagination, includes
  });
}
```
