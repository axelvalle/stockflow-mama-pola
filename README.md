# Mamapola - Sistema de Gestión de Inventario

## 🆕 Novedades
- **Abril 2024:**
  - Mejora en la pantalla de perfil de usuario: ahora el cambio de contraseña incluye validación visual y un toggle para mostrar/ocultar la contraseña en cada campo, mejorando la experiencia y seguridad del usuario.

## 📋 Descripción

Mamapola es una aplicación móvil desarrollada en Flutter que proporciona un sistema completo de gestión de inventario para pequeñas y medianas empresas. La aplicación permite gestionar productos, categorías, proveedores, almacenes, movimientos de inventario y generar reportes analíticos.

## 🚀 Características Principales

### 🔐 Autenticación y Usuarios
- **Sistema de Login/Registro**: Autenticación segura con Supabase
- **Gestión de Roles**: Diferentes niveles de acceso (Admin/User)
- **Inactividad**: Sistema de cierre automático por inactividad
- **Gestión de Usuarios**: Administración completa de usuarios del sistema
- **Cambio de Contraseña Mejorado**: En el perfil de usuario, el cambio de contraseña ahora cuenta con validación visual y opción de mostrar/ocultar la contraseña en cada campo para mayor comodidad y seguridad.

### 📦 Gestión de Productos
- **Catálogo de Productos**: Lista completa con filtros y búsqueda
- **Información Detallada**: Nombre, precio, categoría, proveedor, estado
- **Generación de Catálogos PDF**: Exportación de productos en formato PDF
- **CRUD Completo**: Crear, leer, actualizar y eliminar productos

### 🏷️ Categorías y Proveedores
- **Gestión de Categorías**: Organización jerárquica de productos
- **Gestión de Proveedores**: Información completa de proveedores
- **Relaciones**: Asociación de productos con categorías y proveedores

### 🏪 Almacenes
- **Múltiples Almacenes**: Gestión de varios almacenes
- **Inventario por Almacén**: Control de stock por ubicación
- **Distribución**: Visualización de productos por almacén

### 📊 Movimientos de Inventario
- **Tipos de Movimiento**: Entrada, Salida, Ajuste
- **Historial Completo**: Registro detallado de todos los movimientos
- **Trazabilidad**: Seguimiento completo de cambios en inventario
- **No Editable**: Los movimientos quedan como historial permanente

### 📈 Analytics y Reportes
- **Dashboard Analítico**: Métricas en tiempo real
- **Reportes PDF**: Generación de reportes ejecutivos
- **Métricas Clave**:
  - Inventario por almacén
  - Movimientos recientes
  - Productos con bajo stock
  - Distribución por categorías
  - Movimientos por categoría

### 🎓 Tutorial Interactivo
- **Guía para Nuevos Usuarios**: Tutorial paso a paso automático
- **Explicación de Funciones**: Descripción detallada de cada módulo
- **Opcional**: Posibilidad de saltar el tutorial
- **Persistencia**: Estado guardado localmente
- **Módulos Cubiertos**:
  - Inventario y gestión de productos
  - Movimientos de inventario
  - Estadísticas y reportes
  - Categorías y proveedores
  - Generación de catálogos PDF

### 🎨 Interfaz de Usuario
- **Material Design 3**: Diseño moderno y responsive
- **Tema Adaptativo**: Soporte para modo claro/oscuro
- **Navegación Intuitiva**: Interfaz fácil de usar
- **Indicadores Visuales**: Estados de carga y feedback
- **Tutorial Interactivo**: Guía paso a paso para nuevos usuarios

## 🛠️ Tecnologías Utilizadas

### Frontend
- **Flutter**: Framework de desarrollo móvil
- **Dart**: Lenguaje de programación
- **Material Design 3**: Sistema de diseño

### Backend y Base de Datos
- **Supabase**: Backend-as-a-Service
- **PostgreSQL**: Base de datos relacional
- **Row Level Security (RLS)**: Seguridad a nivel de fila

### Dependencias Principales
- `supabase_flutter`: Cliente de Supabase para Flutter
- `pdf`: Generación de documentos PDF
- `path_provider`: Acceso al sistema de archivos
- `open_file`: Apertura de archivos generados
- `intl`: Internacionalización y formateo de fechas
- `shared_preferences`: Almacenamiento local para preferencias

## 📱 Estructura del Proyecto

```
lib/
├── logic/                    # Lógica de negocio
│   ├── almacen/             # Controladores de almacén
│   ├── auth/                # Autenticación y autorización
│   ├── categoria/           # Gestión de categorías
│   ├── empresa/             # Gestión de empresas
│   ├── inventario/          # Control de inventario
│   ├── movimiento_inventario/ # Movimientos de inventario
│   ├── producto/            # Gestión de productos
│   ├── proveedor/           # Gestión de proveedores
│   ├── user/                # Gestión de usuarios
│   ├── injection/           # Inyección de dependencias
│   └── utils/               # Utilidades generales
├── model/                   # Modelos de datos
│   ├── entities/            # Entidades del dominio
│   ├── exceptions/          # Manejo de excepciones
│   └── repository/          # Patrón repositorio
├── services/                # Servicios especializados
│   ├── analytics_service.dart    # Generación de reportes
│   ├── catalogo_service.dart     # Generación de catálogos
│   └── tutorial_service.dart     # Sistema de tutorial interactivo
├── view/                    # Interfaces de usuario
│   ├── auth/                # Pantallas de autenticación
│   ├── categoria/           # Gestión de categorías
│   ├── empresa/             # Gestión de empresas
│   ├── inicio/              # Dashboard y pantallas principales
│   ├── inventario/          # Gestión de inventario
│   ├── movimiento_inventario/ # Movimientos de inventario
│   ├── producto/            # Gestión de productos
│   ├── proveedor/           # Gestión de proveedores
│   └── user/                # Gestión de usuarios
└── main.dart                # Punto de entrada de la aplicación
```

## 🔧 Configuración e Instalación

### Prerrequisitos
- Flutter SDK (versión 3.0 o superior)
- Dart SDK
- Android Studio / VS Code
- Cuenta de Supabase

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone [URL_DEL_REPOSITORIO]
   cd mamapola_app_v1
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Supabase**
   - Crear proyecto en Supabase
   - Configurar las variables de entorno
   - Ejecutar las migraciones de base de datos

4. **Configurar variables de entorno**
   ```dart
   // lib/main.dart
   const supabaseUrl = 'TU_URL_DE_SUPABASE';
   const supabaseAnonKey = 'TU_ANON_KEY';
   ```

5. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 📊 Base de Datos

### Tablas Principales
- `usuarios`: Gestión de usuarios del sistema
- `productos`: Catálogo de productos
- `categorias`: Categorías de productos
- `proveedores`: Información de proveedores
- `almacenes`: Ubicaciones de almacenamiento
- `inventario`: Stock actual por producto y almacén
- `movimiento_inventario`: Historial de movimientos

### Vistas Principales
- `vw_inventario_por_almacen`: Inventario agrupado por almacén
- `vw_movimientos_recientes`: Últimos movimientos de inventario
- `vw_productos_bajo_inventario`: Productos con stock bajo
- `vw_productos_por_categoria`: Distribución por categorías

## 🔐 Seguridad

### Autenticación
- Autenticación basada en JWT con Supabase
- Gestión de sesiones segura
- Cierre automático por inactividad

### Autorización
- Control de acceso basado en roles
- Row Level Security (RLS) en Supabase
- Validación de permisos en frontend y backend

### Validaciones
- Validación de datos en frontend
- Validaciones de negocio en backend
- Manejo de errores robusto
- **Validación visual y funcional en cambio de contraseña**: El formulario de cambio de contraseña en el perfil de usuario valida que la nueva contraseña cumpla requisitos de seguridad, sea diferente a la actual y permite mostrar/ocultar el texto de cada campo para evitar errores de tipeo.

## 📱 Funcionalidades por Rol

### Usuario Administrador
- Acceso completo a todas las funcionalidades
- Gestión de usuarios del sistema
- Configuración de parámetros globales
- Generación de reportes ejecutivos

### Usuario Regular
- Consulta de productos y catálogos
- Visualización de inventario
- Generación de catálogos PDF
- Acceso limitado a reportes

## 🚀 Despliegue

### Android
1. Generar keystore para firma
2. Configurar `android/app/build.gradle`
3. Ejecutar `flutter build apk --release`

### iOS
1. Configurar certificados en Xcode
2. Ejecutar `flutter build ios --release`
3. Subir a App Store Connect

## 📈 Reportes Disponibles

### Reporte de Analytics
- Resumen ejecutivo del inventario
- Estadísticas generales
- Inventario por almacén
- Movimientos por categoría
- Productos con bajo stock
- Distribución por categorías

### Catálogo de Productos
- Lista completa de productos
- Información detallada
- Estadísticas de precios
- Formato profesional PDF

## 🔄 Flujo de Trabajo

1. **Configuración Inicial**
   - Crear categorías y proveedores
   - Configurar almacenes
   - Registrar productos iniciales

2. **Operaciones Diarias**
   - Registrar movimientos de inventario
   - Monitorear stock bajo
   - Generar reportes según necesidad

3. **Mantenimiento**
   - Actualizar información de productos
   - Gestionar usuarios del sistema
   - Revisar y optimizar procesos

## 🐛 Solución de Problemas

### Errores Comunes
- **Error de conexión**: Verificar configuración de Supabase
- **Problemas de autenticación**: Revisar tokens y sesiones
- **Errores de PDF**: Verificar permisos de archivos

### Logs y Debugging
- Usar `flutter logs` para debugging
- Revisar logs de Supabase en el dashboard
- Implementar logging personalizado

## 🤝 Contribución

1. Fork el proyecto
2. Crear rama para nueva funcionalidad
3. Commit los cambios
4. Push a la rama
5. Abrir Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 📞 Soporte

Para soporte técnico o consultas:
- Crear un issue en el repositorio
- Contactar al equipo de desarrollo
- Revisar la documentación de Supabase

## 🔮 Roadmap

### Próximas Funcionalidades
- [x] Tutorial interactivo para nuevos usuarios

- [ ] Integración con códigos de barras
- [ ] Reportes personalizados
- [ ] Exportación a Excel
- [ ] Backup automático de datos
- [ ] Modo offline
- [ ] Multiidioma

### Mejoras Técnicas
- [ ] Optimización de rendimiento
- [ ] Mejoras en la UI/UX
- [ ] Tests automatizados
- [ ] CI/CD pipeline
- [ ] Monitoreo y analytics

---

**Desarrollado con ❤️ para la gestión eficiente de inventarios**
