# Technical Architecture Spec: FEAT-001 Autenticación de Usuarios

> **Iniciativa:** FEAT-001-user-auth  
> **Arquitecto:** Software Architect  
> **Estado:** Approved  

---

## 1. Contratos de API (REST)

### `POST /api/v1/auth/register`
- **Request Body:** `{ email: string, password: string, name: string }`
- **Response 201:** `{ userId: string, email: string }`
- **Errors:** `400 Bad Request`, `409 Conflict (Email ya registrado)`

### `POST /api/v1/auth/login`
- **Request Body:** `{ email: string, password: string }`
- **Response 200:** `{ accessToken: string }`
- **Set-Cookie:** `refreshToken=...; HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth/refresh`

---

## 2. Modelo de Datos (Prisma / PostgreSQL)
```prisma
model User {
  id           String   @id @default(uuid())
  email        String   @unique
  passwordHash String
  name         String
  createdAt    DateTime @default(now())
  refreshTokens RefreshToken[]
}

model RefreshToken {
  id        String   @id @default(uuid())
  tokenHash String   @unique
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  expiresAt DateTime
}
```
