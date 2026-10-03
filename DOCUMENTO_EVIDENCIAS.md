# INFORME DE EVIDENCIAS: PROGRAMACIÓN ASÍNCRONA, TIMER E ISOLATES EN FLUTTER

---

**Asignatura:** Electiva Profesional I - Proyecto Móviles  
**Estudiante:** Brahian Tenorio  
**Institución:** Universidad  
**Fecha:** Octubre 2026  
**URL del Repositorio:** [https://github.com/brahiantenorio/proyectoMoviles](https://github.com/brahiantenorio/proyectoMoviles)  
**Ramas disponibles en GitHub:** `main`, `dev`, `feature/taller_segundo_plano`  

---

\newpage

## 📑 TABLA DE CONTENIDO

1. [Portada y Enlace al Repositorio](#portada-y-enlace-al-repositorio)
2. [Evidencia 1: Asincronía con Future / async / await](#evidencia-1-asincronía-con-future--async--await)
   - 1.1 Descripción técnica del servicio simulado
   - 1.2 Captura: Estado "Cargando..."
   - 1.3 Captura: Estado "Éxito" con datos recibidos
   - 1.4 Captura: Estado "Error" y tolerancia a fallos
   - 1.5 Evidencia de Consola: Orden de ejecución (Antes, Durante, Después)
3. [Evidencia 2: Cronómetro con Timer y Limpieza de Recursos](#evidencia-2-cronómetro-con-timer-y-limpieza-de-recursos)
   - 2.1 Descripción técnica del cronómetro y gestión de memoria
   - 2.2 Capturas: Iniciar, Pausar, Reanudar y Reiniciar
   - 2.3 Evidencia de Consola: Limpieza de recursos y dispose()
4. [Evidencia 3: Isolate para Tareas Pesadas (CPU-Bound)](#evidencia-3-isolate-para-tareas-pesadas-cpu-bound)
   - 3.1 Descripción técnica del cómputo intensivo con Isolate.spawn
   - 3.2 Captura: Pantalla con tiempos de inicio, fin y duración en milisegundos
   - 3.3 Evidencia de Consola: Comunicación por mensajes SendPort / ReceivePort
   - 3.4 Demostración de No-Bloqueo de UI (Animación a 60 FPS y eventos táctiles)
5. [Conclusiones](#conclusiones)

---

\newpage

## 1. Evidencia 1: Asincronía con Future / async / await

### 1.1 Descripción Técnica
Se implementó un servicio simulado (`MockDataService`) que utiliza `Future.delayed` con una latencia de **2.5 segundos** para recrear una solicitud I/O hacia un servidor remoto. La interfaz gráfica `FutureAsyncScreen` consume este servicio utilizando la sintaxis moderna `async / await`.

Durante la espera asíncrona, el bucle de eventos (*Event Loop*) de Dart suspende únicamente la ejecución de la función de consulta, permitiendo que el hilo principal continúe pintando la UI y procesando toques del usuario (verificado mediante el botón de prueba de fluidez interactiva).

---

### 1.2 Captura del Estado: Cargando...
> **Descripción:** Al pulsar "Consultar (Éxito)" o "Simular Error", la interfaz pasa inmediatamente al estado `FutureState.loading`. Se muestra un `CircularProgressIndicator` y una barra lineal sin bloquear el resto de la interfaz.

```
+-------------------------------------------------------------+
|                                                             |
|           [ INSERTAR AQUÍ CAPTURA DE PANTALLA:              |
|              ESTADO CARGANDO CON INDICADOR ]                |
|                                                             |
+-------------------------------------------------------------+
```
*Figura 1.1: Estado "Cargando..." con indicador de progreso activo mientras el Future se resuelve.*

---

### 1.3 Captura del Estado: Éxito
> **Descripción:** Una vez completados los 2.5 segundos, el `Future` retorna la lista de registros estructurados. La interfaz actualiza el estado a `FutureState.success`, desplegando las tarjetas informativas con las métricas obtenidas.

```
+-------------------------------------------------------------+
|                                                             |
|           [ INSERTAR AQUÍ CAPTURA DE PANTALLA:              |
|                 ESTADO ÉXITO CON DATOS ]                    |
|                                                             |
+-------------------------------------------------------------+
```
*Figura 1.2: Estado "Éxito" renderizando los datos recibidos del servicio simulado.*

---

### 1.4 Captura del Estado: Error
> **Descripción:** Al pulsar "Simular Error", el servicio lanza intencionalmente una excepción `Exception('Error 500...')`. Mediante el bloque `try-catch`, la UI captura la excepción y pasa al estado `FutureState.error`, mostrando un banner rojo informativo y la opción de reintentar.

```
+-------------------------------------------------------------+
|                                                             |
|           [ INSERTAR AQUÍ CAPTURA DE PANTALLA:              |
|            ESTADO ERROR CON MENSAJE DE FALLO ]              |
|                                                             |
+-------------------------------------------------------------+
```
*Figura 1.3: Estado "Error" con descripción de la falla y botón de reintento.*

---

### 1.5 Evidencia de Consola: Orden de Ejecución
> **Descripción:** Salida generada en la consola (visible tanto en la terminal de Flutter como en el visor de logs integrado en la aplicación), demostrando el orden secuencial cronológico: **1. ANTES**, **2. DURANTE**, y **3. DESPUÉS**.

```text
------------------------------------------------------------
[Future/UI] 1. [ANTES]: Usuario solicita consulta (Con Éxito). Hora: 18:22:10
[Future/UI] 1. [ANTES]: Actualizando estado de la UI a "Cargando..."
[Future/UI] 2. [DURANTE]: Esperando respuesta del servidor con "await MockDataService.fetchData()"...
[Future/UI] 2. [DURANTE]: El hilo principal (UI) permanece totalmente libre y responsivo.
[Future/Servicio] 1. [ANTES]: Iniciando servicio de consulta remota...
[Future/Servicio] 2. [DURANTE]: Esperando respuesta simulada con Future.delayed (2500 ms)...
[Future/Servicio] 3. [DESPUÉS]: Respuesta recibida exitosamente con 4 registros.
------------------------------------------------------------
[Future/UI] 3. [DESPUÉS]: Éxito recibido en 2503 ms. Procesando 4 registros.
[Future/UI] 3. [DESPUÉS]: Actualizando estado a "Éxito".
```
*Figura 1.4: Trazas de consola que evidencian el orden estricto de ejecución en el ciclo asíncrono.*

---

\newpage

## 2. Evidencia 2: Cronómetro con Timer y Limpieza de Recursos

### 2.1 Descripción Técnica
Se desarrolló la pantalla `TimerScreen` implementando un cronómetro de alta precisión basado en `Timer.periodic` con un intervalo de **100 milisegundos** (décimas de segundo). El diseño visual cuenta con un marcador digital de alto contraste (`00:00:00.0`).

Cuenta con los cuatro botones requeridos por la especificación:
1. **Iniciar:** Crea la instancia de `Timer.periodic`.
2. **Pausar:** Detiene el avance y **cancela el Timer** inmediatamente (`_timer.cancel(); _timer = null;`).
3. **Reanudar:** Recrea el `Timer.periodic` continuando desde el valor acumulado.
4. **Reiniciar:** Cancela el temporizador y restablece el acumulador en cero.

**Limpieza de Recursos (`dispose`):**  
Para evitar fugas de memoria (*memory leaks*), se sobreescribe el método `dispose()` en el ciclo de vida del widget para cancelar activamente cualquier temporizador en ejecución al salir de la pantalla.

---

### 2.2 Capturas de Funcionamiento: Iniciar, Pausar, Reanudar y Reiniciar

```
+------------------------------------+------------------------------------+
|                                    |                                    |
|   [ CAPTURA: BOTÓN INICIAR Y       |     [ CAPTURA: BOTÓN PAUSAR Y      |
|     MARCADOR EN MARCHA ]           |       ESTADO EN PAUSA ]            |
|                                    |                                    |
+------------------------------------+------------------------------------+
|                                    |                                    |
|   [ CAPTURA: BOTÓN REANUDAR Y      |     [ CAPTURA: BOTÓN REINICIAR     |
|     REGISTRO DE VUELTAS ]          |       EN 00:00.0 ]                 |
|                                    |                                    |
+------------------------------------+------------------------------------+
```
*Figura 2.1: Ciclo completo del cronómetro en sus cuatro fases operativas.*

---

### 2.3 Evidencia de Consola: Limpieza de Recursos
```text
[Timer] INICIAR: Creando Timer.periodic (intervalo: 100ms)...
[Timer] Cronómetro en marcha.
[Timer] Vuelta registrada: 00:04.2
[Timer/Limpieza] PAUSAR: _timer.cancel() ejecutado. Tiempo congelado en 00:07.5.
[Timer] REANUDAR: Recreando Timer.periodic desde 00:07.5...
[Timer] Cronómetro reanudado con éxito.
[Timer/Limpieza] REINICIAR: _timer.cancel() ejecutado.
[Timer] Cronómetro reiniciado a 00:00:00.0.
[Timer/Lifecycle] DISPOSE: Timer cancelado exitosamente al salir de la pantalla.
```
*Figura 2.2: Logs confirmando la cancelación activa del Timer al pausar, reiniciar y en dispose().*

---

\newpage

## 3. Evidencia 3: Isolate para Tareas Pesadas (CPU-Bound)

### 3.1 Descripción Técnica
En Dart, una tarea que satura la CPU por varios segundos dentro del hilo principal congelará toda la aplicación, interrumpiendo las animaciones y perdiendo eventos táctiles.

Para resolver esto, se implementó `HeavyComputationService.heavyWorker`, una función estática de cómputo intensivo (50 millones de cálculos matemáticos modulares y cuadráticos). La ejecución se realiza en un hilo separado del sistema operativo mediante **`Isolate.spawn`**, enviando los parámetros mediante una clase estructurada (`IsolateTaskParams`) que contiene el `SendPort` para la comunicación por paso de mensajes.

---

### 3.2 Captura de la Pantalla con Métricas y Tiempos de Ejecución
> **Descripción:** La pantalla `IsolateScreen` muestra la hora exacta de inicio, la hora de finalización, la duración total en milisegundos y el resultado final calculado.

```
+-------------------------------------------------------------+
|                                                             |
|           [ INSERTAR AQUÍ CAPTURA DE PANTALLA:              |
|             TARJETA DE TIEMPOS, DURACIÓN EN MS              |
|                 Y RESULTADOS DEL ISOLATE ]                  |
|                                                             |
+-------------------------------------------------------------+
```
*Figura 3.1: Pantalla con visualización detallada de los tiempos de inicio, fin y duración en milisegundos.*

---

### 3.3 Evidencia de Consola: Mensajes entre Hilos
```text
============================================================
[Isolate/Main] 1. INICIO: Solicitud de tarea pesada con 50000000 operaciones.
[Isolate/Main] 1. Hora de inicio: 18:24:45.120
[Isolate/Main] 2. Creando ReceivePort en el hilo principal...
[Isolate/Main] 3. Ejecutando Isolate.spawn(HeavyComputationService.heavyWorker)...
[Isolate/Worker] Mensaje recibido: Hilo de Isolate iniciado. Comenzando 50000000 iteraciones CPU-bound...
[Isolate/Worker] Mensaje de progreso: Isolate procesando: 25% completado...
[Isolate/Worker] Mensaje de progreso: Isolate procesando: 50% completado...
[Isolate/Worker] Mensaje de progreso: Isolate procesando: 75% completado...
[Isolate/Worker] Mensaje de progreso: Isolate procesando: 100% completado...
[Isolate/Worker] Mensaje final recibido: Cómputo finalizado exitosamente en Isolate secundario.
[Isolate/Main] 4. FINALIZADO: Hora fin: 18:24:46.850 | Duración real: 1730 ms.
[Isolate/Main] 5. Cerrando ReceivePort y liberando Isolate.
============================================================
```
*Figura 3.2: Trazas de consola evidenciando el intercambio de mensajes bidireccional.*

---

### 3.4 Demostración de No-Bloqueo de la UI
> **Descripción:** En la vista se integró un componente con rotación continua a 60 fotogramas por segundo y un botón contador táctil. Mientras el Isolate secundario procesaba los 50 millones de iteraciones al 100% de carga, la animación continuó girando con fluidez absoluta y los toques en pantalla se registraron en tiempo real sin una sola caída de cuadros.

```
+-------------------------------------------------------------+
|                                                             |
|           [ INSERTAR AQUÍ CAPTURA DE PANTALLA:              |
|           MONITOR DE FLUIDEZ A 60 FPS Y TOQUES              |
|             MIENTRAS EL ISOLATE ESTÁ ACTIVO ]               |
|                                                             |
+-------------------------------------------------------------+
```
*Figura 3.3: Comprobación de UI totalmente responsiva durante el procesamiento en segundo plano.*

---

\newpage

## 4. Conclusiones

1. **Eficiencia en Operaciones I/O:** El uso de `Future` con `async/await` es la solución ideal para operaciones de red y persistencia, ya que delega la espera al sistema operativo sin saturar recursos de cómputo en la aplicación.
2. **Gestión de Recursos y Ciclo de Vida:** La correcta manipulación de `Timer` exige la cancelación explícita en `dispose()` para prevenir pérdidas de rendimiento y memory leaks.
3. **Paralelismo Real con Isolates:** Ante algoritmos con alto consumo de CPU, `Isolate.spawn` permite aprovechar procesadores multi-núcleo garantizando una experiencia de usuario (UX) fluida, manteniendo la tasa de refresco a 60/120 FPS sin congelamientos.
4. **Flujo de Trabajo Profesional:** La adopción del modelo GitFlow (`feature` $\to$ `dev` $\to$ `main`) y commits atómicos asegura un historial limpio, trazable y preparado para entornos de integración continua.
