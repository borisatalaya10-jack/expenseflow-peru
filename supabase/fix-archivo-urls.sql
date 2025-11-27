-- =====================================================
-- Fix: Actualizar URLs de documentos existentes
-- Fecha: 2025-11-27
-- Problema: Los documentos guardados tienen URLs públicas incorrectas
--           porque el bucket es privado
-- Solución: Extraer solo el path del archivo de las URLs existentes
-- =====================================================

-- Actualizar todos los documentos existentes para guardar solo el path
UPDATE gastos_documentos
SET archivo_url = SUBSTRING(
  archivo_url 
  FROM 'gastos-documentos/(.+)$'
)
WHERE archivo_url LIKE '%/storage/v1/object/public/gastos-documentos/%'
   OR archivo_url LIKE '%gastos-documentos/%';

-- Verificar los cambios
SELECT 
  id,
  archivo_nombre,
  archivo_url as nuevo_path
FROM gastos_documentos
ORDER BY created_at DESC
LIMIT 10;

-- Mensaje de confirmación
DO $$ 
DECLARE
  total_actualizados INTEGER;
BEGIN 
  SELECT COUNT(*) INTO total_actualizados 
  FROM gastos_documentos;
  
  RAISE NOTICE 'URLs actualizadas correctamente: % documentos', total_actualizados;
  RAISE NOTICE 'Ahora archivo_url contiene solo el path (ej: usuario-id/timestamp_archivo.png)';
  RAISE NOTICE 'Las signed URLs se generan dinámicamente en el frontend';
END $$;
