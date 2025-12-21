# 🚌 TerminalSmart - Sistema de Gestión Automatizada de Transporte

> Modernización del control de flujo, recaudo y logística para terminales de pasajeros. Proyecto piloto: **Charallave, Venezuela**.

![Status](https://img.shields.io/badge/Status-Fase%201%20(En%20Desarrollo)-blue)
![Platform](https://img.shields.io/badge/Platform-Flutter%20%7C%20Supabase-02569B)
![License](https://img.shields.io/badge/License-MIT-green)

## 📋 Sobre el Proyecto

**TerminalSmart** nace de la necesidad de optimizar los tiempos de salida y la gestión financiera en el terminal de pasajeros de Charallave. Actualmente, el proceso de pago de "Listín" (tasa de salida) y el control de unidades se realiza de forma manual y dependiente del efectivo, lo cual genera retrasos (colas en taquilla), ineficiencia y riesgos de seguridad.

Este proyecto propone un ecosistema digital que **elimina el uso de efectivo en taquilla**, automatiza la validación de salidas y escala hacia un sistema de monitoreo en tiempo real y cobro digital de pasajes.

## 🚀 Hoja de Ruta (Roadmap)

El proyecto está dividido en tres fases estratégicas para asegurar su implementación progresiva:

### 📍 Fase 1: MVP - Automatización de Salida (Actual)
El objetivo es que choferes y colectores no pierdan tiempo en taquilla.
- [ ] **App Chofer:** Login y Billetera Digital (Wallet).
- [ ] **QR Dinámico:** Generación de tickets de salida validados con criptografía (offline-first).
- [ ] **App Fiscal (Garita):** Validación y escaneo de QR para registrar salidas.
- [ ] **Alertas:** Notificaciones Push/SMS para saldo bajo.
- [ ] **Backend:** Panel administrativo para control de ingresos y conciliación de Pago Móvil.

### 📍 Fase 2: Experiencia del Pasajero & GPS
Aprovechamiento del dispositivo del chofer como rastreador.
- [ ] **Driver App en Segundo Plano:** Envío de telemetría (Lat/Long) eficiente.
- [ ] **App Pasajeros:** Visualización de unidades en tiempo real y tiempos estimados de llegada (ETA).
- [ ] **Algoritmo de Inferencia:** Detección de estados "En Túnel" o "Sin Señal" para mantener la ubicación proyectada en el mapa sin generar falsas alarmas.

### 📍 Fase 3: Ecosistema "Cashless" y LPR
Eliminación total del efectivo y seguridad avanzada.
- [ ] **Monedero de Usuario:** Pasajeros pagan acercando su celular o tarjeta QR al abordar.
- [ ] **LPR (Reconocimiento de Placas):** Cámaras en la salida del terminal con *Edge Computing* para validar cruces vs. pagos QR.
- [ ] **Detección de Anomalías:** Sistema de alertas si un bus sale sin registro o se desconecta por tiempos inusuales.

## 🛠️ Stack Tecnológico

La arquitectura está diseñada para ser escalable y económica (Serverless y Multiplataforma).

| Componente | Tecnología | Motivo |
| :--- | :--- | :--- |
| **Frontend Móvil** | **Flutter (Dart)** | Desarrollo único para Android/iOS con excelente rendimiento en gamas bajas. |
| **Backend / DB** | **Supabase** | Base de datos PostgreSQL en tiempo real, Auth y Edge Functions. |
| **Validación** | **JWT / QR Cifrado** | Seguridad para generar tokens efímeros. |
| **IoT / LPR (Futuro)** | **Python + OpenCV** | Procesamiento de imágenes para reconocimiento de placas en Raspberry Pi. |

## 📐 Arquitectura del Sistema

### Flujo de Pago de Salida (Listín)
1. **Chofer:** Recarga saldo vía Pago Móvil -> App acredita saldo en Wallet.
2. **Generación:** Chofer solicita salida -> App verifica saldo -> Genera QR Dinámico (Vigencia 5 min).
3. **Validación:** Fiscal escanea QR -> Backend marca ticket `USADO` -> Barrera se levanta (Físico o Lógico).

### Lógica de Monitoreo (Fase 2)
El sistema implementa una lógica de "Latido" (Heartbeat):
```python
IF ultimo_heartbeat > 5_min:
    IF ubicacion in zonas_baja_cobertura (Tunel, Autopista):
        STATUS = "POSIBLE_DESCONEXION_RED" (Espera pasiva)
    ELSE:
        STATUS = "ALERTA_INCIDENCIA" (Notificar a central)