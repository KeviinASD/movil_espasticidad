🧠 INDICADORES CUANTITATIVOS SELECCIONADOS (VERSIÓN FINAL)
Resumen · Qué miden · Cómo se calculan

1️⃣ Modified Ashworth Scale (MAS)
🔹 ¿Qué mide?
Mide el grado de aumento del tono muscular, evaluando la resistencia al movimiento pasivo de una articulación.
Refleja la severidad clínica global de la espasticidad, pero no distingue entre componentes neurales y mecánicos.

🔹 ¿Cómo se calcula?
No se basa en una fórmula matemática.
El médico moviliza pasivamente la articulación.


Evalúa la resistencia ofrecida por el músculo.


Asigna un valor según criterios clínicos estandarizados.


Escala válida:
0, 1, 1.5, 2, 3, 4


🔹 Tipo de dato
Ordinal (input manual del clínico)



2️⃣ Frecuencia real de espasmos musculares (reemplazo de PSFS)
🔹 ¿Qué mide?
Mide la cantidad real de espasmos musculares involuntarios en un periodo de tiempo definido.
Evalúa directamente la actividad motora involuntaria asociada a la espasticidad, sin categorización subjetiva.

🔹 ¿Cómo se calcula?
Se cuentan los espasmos musculares durante un intervalo fijo.
Puede obtenerse mediante:
Observación clínica


Autorregistro del paciente


Detección automática con EMG


Fórmula básica:
Frecuencia de espasmos = Número total de espasmos / unidad de tiempo

Ejemplos:
espasmos/hora


espasmos/24 h



🔹 Rango típico
0 – >50 espasmos/hora

(no tiene límite superior teórico)

🔹 Tipo de dato
Entero (count)


Variable continua discreta


Ideal para modelos IA



3️⃣ H-Reflex Ratio (Hmax / Mmax)
🔹 ¿Qué mide?
Mide la excitabilidad de las motoneuronas espinales, reflejando la hiperexcitabilidad refleja típica de la espasticidad.
Es un biomarcador neurofisiológico objetivo.

🔹 ¿Cómo se calcula?
Se estimula eléctricamente un nervio periférico.


Se registra la señal EMG.


Se determinan:


Hmax: amplitud máxima del reflejo H


Mmax: amplitud máxima de la respuesta motora directa


Fórmula:
H-Reflex Ratio = Hmax / Mmax


🔹 Rango válido
0.0 – 1.0

Valores más altos indican mayor excitabilidad espinal.

🔹 Tipo de dato
Numérico continuo (float)



4️⃣ Stretch Reflex Threshold (SRT)
🔹 ¿Qué mide?
Mide la velocidad mínima de estiramiento muscular necesaria para activar el reflejo de estiramiento espástico.
Evalúa la sensibilidad del sistema reflejo a la velocidad, un mecanismo central de la espasticidad.

🔹 ¿Cómo se calcula?
Se estira pasivamente el músculo a diferentes velocidades.


Se registra la actividad EMG.


Se identifica la velocidad angular en la que aparece por primera vez la activación reflejo.


Definición:
SRT = velocidad (°/s) al inicio del reflejo EMG


🔹 Rango típico
10 – 300 °/s

Valores más bajos indican mayor severidad espástica.

🔹 Tipo de dato
Numérico continuo (float)


