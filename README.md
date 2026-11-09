# Invidious en Render.com

1. Subir este directorio a un repositorio Git (GitHub/GitLab).
2. En Render: **New > Blueprint**, seleccionar el repositorio (usa `render.yaml`).
3. Definir `INVIDIOUS_DOMAIN` (p. ej. `mi-app.onrender.com`).
4. La base de datos se crea sola; `check_tables: true` genera las tablas al iniciar.

Notas:
- Sin `invidious-companion` no se reproducen videos. Desplegarlo como servicio aparte y definir
  `INVIDIOUS_INVIDIOUS_COMPANION` (YAML) e `INVIDIOUS_INVIDIOUS_COMPANION_KEY`.
- Redis/Valkey es opcional (cache de video); omitido.
