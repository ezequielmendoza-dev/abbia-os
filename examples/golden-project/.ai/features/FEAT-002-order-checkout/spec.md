# Feature Spec: FEAT-002 Flujo de Checkout de Órdenes

> **Iniciativa:** FEAT-002-order-checkout  
> **Estado:** In Progress (Fase Spec completada)  
> **Analista:** Product Analyst  

---

## 1. Resumen y Objetivo de Negocio
Permitir a los usuarios autenticados transformar los productos de su carrito de compras en una orden formal con sesión de pago bloqueada por 15 minutos (RN-002).

---

## 2. Casos de Uso y Criterios de Aceptación

### UC-01: Creación de Orden desde Carrito
```gherkin
Given un usuario autenticado con 1+ items en su carrito
When presiona el botón "Proceder al Pago"
Then el sistema valida el stock, genera una Orden en estado PENDING_PAYMENT y reserva stock por 15 min
```

### UC-02: Expiración Automática de Orden
```gherkin
Given una orden en estado PENDING_PAYMENT
When transcurren más de 15 minutos sin confirmación de pago del gateway
Then el sistema cancela la orden y libera el stock reservado
```
