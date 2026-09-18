# Reglas de Negocio del Sistema

Reglas inmutables y de dominio que todo agente y desarrollador debe respetar.

| ID | Regla | Descripción | Entidad Afectada | Estado |
| :--- | :--- | :--- | :--- | :--- |
| RN-001 | Autenticación Obligatoria en Checkout | Todo usuario debe estar autenticado con email verificado antes de iniciar el pago. | Usuario, Carrito | ACTIVA |
| RN-002 | Expiración de Sesión de Pago | Una orden en estado pendiente de pago expira automáticamente tras 15 minutos sin confirmación. | Orden, Transacción | ACTIVA |
