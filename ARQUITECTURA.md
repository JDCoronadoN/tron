DISEÑO DE ARQUITECTURA, SPRINTS Y RAMAS
Rol: Diseñadora / Arquitecta – Nayeli
Motor: Godot

1. Arquitectura del sistema
El proyecto (juego en Godot) se organizará con una arquitectura de dos capas:
•	Capa de Lógica:
Maneja el flujo del juego, control de estados, mecánicas, interacción del jugador, validaciones internas del sistema.
•	Capa de Diseño / Presentación:
Gestiona la interfaz gráfica, menús, HUD, animaciones, modelos 3D, íconos y elementos visuales del juego.
Así mismo, se trabajará con dos ambientes:
•	Desarrollo, para creación y pruebas.
•	Producción, para la versión estable del juego.

2. Organización de Requerimientos Funcionales por Sprints
Los 12 requerimientos funcionales definidos en la Wiki se organizaron por prioridad y dependencias de la siguiente manera:
•	Sprint 0: RF-001, RF-002, RF-012
•	Sprint 1: RF-003, RF-005, RF-009
•	Sprint 2: RF-004, RF-006
•	Sprint 3: RF-007, RF-010
•	Sprint 4: RF-011, RF-008
3. Diseño de la estructura de ramas
La rama base de trabajo será dev, utilizando la siguiente convención:
dev/feature/*
Ramas propuestas para el desarrollo de los RF:
dev/feature/RF001-002-012
dev/feature/RF003-005-009
dev/feature/RF004-006
dev/feature/RF007-010
dev/feature/RF008-011
Cada rama agrupa uno o varios requerimientos funcionales para facilitar el trabajo paralelo de los desarrolladores.
4. Rama del rol Diseñadora / Arquitecta
Para las tareas de diseño y arquitectura se definió la rama:
dev/feature/Arquitectura
Esta rama se utilizará para diagramas, estructura del proyecto, organización de escenas y elementos de diseño en Godot.
5. Nota de coordinación
Las ramas de requerimientos funcionales serán creadas por los desarrolladores.
La rama de arquitectura corresponde únicamente al rol de Diseñadora / Arquitecta.
organización de los sprints
Los requerimientos funcionales se organizaron en sprints considerando su prioridad y las dependencias entre funcionalidades.
Primero se incluyeron las funciones base necesarias para que el juego pueda iniciar y ser navegable.
Posteriormente, se planificaron las funcionalidades que permiten la interacción del jugador y las mecánicas principales.
Finalmente, se dejaron para los últimos sprints las funcionalidades avanzadas y complementarias, ya que no afectan el funcionamiento principal del juego.
Esta organización permite un desarrollo progresivo, evita retrabajo y facilita la coordinación del equipo.
