# Feature Spec: FEAT-001 Autenticación de Usuarios

> **Iniciativa:** FEAT-001-user-auth  
> **Estado:** Approved (Archivado)  
> **Analista:** Product Analyst  

---

## 1. Resumen y Objetivo de Negocio
Permitir a los usuarios registrarse con email y contraseña, iniciar sesión para obtener un token JWT seguro y refrescar la sesión automáticamente.

---

## 2. Casos de Uso y Criterios de Aceptación

### UC-01: Registro de Usuario
```gherkin
Given un usuario no registrado con email válido y contraseña de 8+ caracteres
When envía el formulario de registro a /auth/register
Then el sistema crea la cuenta con contraseña hasheada y retorna código 201
```

### UC-02: Inicio de Sesión
```gherkin
Given un usuario registrado con credenciales correctas
When envía el formulario a /auth/login
Then el sistema retorna un Access Token (JWT) y setea una cookie HttpOnly con el Refresh Token
```
