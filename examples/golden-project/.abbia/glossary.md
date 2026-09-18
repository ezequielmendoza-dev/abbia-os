# Glosario del Dominio

| Término | Definición | Contexto / Notas |
| :--- | :--- | :--- |
| **Checkout** | Proceso transaccional en el que el usuario confirma los items del carrito e inicia el pago. | Flujo crítico de negocio |
| **Orden** | Entidad inmutable que representa la compra confirmada de uno o más productos. | Persistida en PostgreSQL |
| **Sesión de Pago** | Período temporal de 15 minutos en el que se reservan los ítems antes de expirar. | Ver regla RN-002 |
