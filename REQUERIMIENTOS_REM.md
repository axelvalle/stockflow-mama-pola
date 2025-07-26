# Especificación de Requerimientos de Software (REM)

## 1. Introducción

### 1.1 Propósito
Este documento describe los requerimientos funcionales y no funcionales del sistema de gestión de inventarios "MamaPola App". El objetivo es definir de manera clara y precisa las funcionalidades y restricciones del sistema para su desarrollo, validación y mantenimiento.

### 1.2 Alcance
El sistema permite la gestión integral de inventarios, productos, proveedores, empresas y usuarios, incluyendo autenticación segura, reportes, análisis y experiencia de usuario moderna, dirigido a pequeñas y medianas empresas.

### 1.3 Definiciones, acrónimos y abreviaturas
- **REM:** Requerimientos de Especificación de Software
- **2FA:** Autenticación en dos pasos
- **CRUD:** Crear, Leer, Actualizar, Eliminar
- **UI:** Interfaz de Usuario

---

## 2. Requerimientos Funcionales

### RF-01. Gestión de Usuarios
- RF-01.01 Registro de nuevos usuarios con validación de correo y contraseña fuerte.
- RF-01.02 Inicio de sesión con autenticación segura.
- RF-01.03 Recuperación de contraseña mediante correo electrónico y soporte para 2FA (código de respaldo).
- RF-01.04 Edición de perfil y cambio de contraseña.
- RF-01.05 Gestión de sesiones y control de actividad del usuario.
- RF-01.06 Soporte para roles de usuario (admin, user) y control de permisos.

### RF-02. Gestión de Inventario
- RF-02.01 Visualización y administración de productos, categorías, proveedores y empresas.
- RF-02.02 Agregar, editar y eliminar productos, categorías, proveedores y empresas.
- RF-02.03 Visualización de inventario con filtros y búsqueda avanzada.
- RF-02.04 Visualización de detalles de producto con información enriquecida.
- RF-02.05 Control de stock mínimo y alertas de inventario bajo.

### RF-03. Movimientos de Inventario
- RF-03.01 Registro y consulta de movimientos de inventario (entradas, salidas, ajustes).
- RF-03.02 Visualización de historial de movimientos.

### RF-04. Reportes y Análisis
- RF-04.01 Visualización de estadísticas y reportes de inventario.
- RF-04.02 Generación de reportes PDF (catálogo, análisis, etc.).

### RF-05. Seguridad y Autenticación
- RF-05.01 Soporte para autenticación en dos pasos (2FA) y códigos de respaldo.
- RF-05.02 Validación de correo electrónico y control de usuarios baneados o inactivos.
- RF-05.03 Control de intentos de login y bloqueo de usuario por intentos fallidos.

### RF-06. Interfaz de Usuario y Experiencia
- RF-06.01 Pantallas adaptadas a modo claro y oscuro.
- RF-06.02 Tutorial interactivo para nuevos usuarios en el dashboard.
- RF-06.03 Manual de usuario y sección de ayuda accesible.
- RF-06.04 Pantallas de políticas, FAQ y "Quiénes somos".
- RF-06.05 Navegación intuitiva con AppBar, NavigationBar y FloatingActionButton contextuales.
- RF-06.06 Animaciones y transiciones visuales modernas.

### RF-07. Otras Funcionalidades
- RF-07.01 Soporte para deep links en recuperación de contraseña.
- RF-07.02 Visualización y gestión de códigos de respaldo para 2FA.
- RF-07.03 Registro de actividad del usuario y logs de acciones importantes.
- RF-07.04 Soporte para múltiples plataformas (Android, iOS, Web, Desktop).

---

## 3. Requerimientos No Funcionales

### RNF-01. Seguridad
- RNF-01.01 Almacenamiento seguro de contraseñas y datos sensibles.
- RNF-01.02 Uso de autenticación segura y cifrado en las comunicaciones.
- RNF-01.03 Protección contra accesos no autorizados y validación de roles.

### RNF-02. Usabilidad
- RNF-02.01 Interfaz intuitiva y amigable para usuarios principiantes y avanzados.
- RNF-02.02 Mensajes de error claros y ayuda contextual.
- RNF-02.03 Soporte para modo oscuro y claro.
- RNF-02.04 Tutorial interactivo para onboarding de nuevos usuarios.

### RNF-03. Rendimiento
- RNF-03.01 Respuesta rápida en la navegación y operaciones CRUD.
- RNF-03.02 Carga eficiente de datos y uso de paginación/filtros donde sea necesario.

### RNF-04. Mantenibilidad
- RNF-04.01 Código modular y organizado por entidades y funcionalidades.
- RNF-04.02 Uso de patrones de diseño para escalabilidad.
- RNF-04.03 Separación clara entre lógica de negocio, servicios y vistas.

### RNF-05. Compatibilidad
- RNF-05.01 Soporte multiplataforma (Flutter: Android, iOS, Web, Desktop).
- RNF-05.02 Adaptabilidad a diferentes tamaños de pantalla y dispositivos.

### RNF-06. Disponibilidad y Recuperación
- RNF-06.01 Manejo de errores y caídas de red con mensajes amigables.
- RNF-06.02 Persistencia de estado relevante usando almacenamiento local.

### RNF-07. Accesibilidad
- RNF-07.01 Uso de colores y contrastes adecuados para accesibilidad visual.
- RNF-07.02 Soporte para textos alternativos y tooltips en iconos y botones.

---

## 4. Anexos
- Diagrama de arquitectura (opcional)
- Glosario de términos (opcional)
- Referencias a estándares y buenas prácticas (opcional) 