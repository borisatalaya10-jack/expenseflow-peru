-- =====================================================
-- FUNCIONES PARA DASHBOARD DE GASTOS
-- =====================================================

-- Función: Obtener gastos agrupados por concepto
CREATE OR REPLACE FUNCTION obtener_gastos_por_concepto(
  fecha_inicio TIMESTAMPTZ DEFAULT NULL,
  fecha_fin TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
  concepto VARCHAR,
  total NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(cg.nombre, 'Sin concepto') AS concepto,
    SUM(
      CASE
        WHEN g.moneda = 'PEN' THEN g.monto
        WHEN g.moneda = 'USD' THEN g.monto * COALESCE(g.tipo_cambio, 3.75)
        WHEN g.moneda = 'EUR' THEN g.monto * COALESCE(g.tipo_cambio, 4.0)
        ELSE g.monto
      END
    )::NUMERIC AS total
  FROM gastos g
  LEFT JOIN conceptos_gasto cg ON g.concepto_gasto_id = cg.id
  WHERE
    (fecha_inicio IS NULL OR g.fecha_gasto >= fecha_inicio)
    AND (fecha_fin IS NULL OR g.fecha_gasto <= fecha_fin)
    AND g.estado NOT IN ('anulado', 'rechazado')
  GROUP BY cg.nombre
  ORDER BY total DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función: Obtener resumen de gastos por estado
CREATE OR REPLACE FUNCTION obtener_resumen_gastos_estado()
RETURNS TABLE (
  estado VARCHAR,
  cantidad BIGINT,
  monto_pen NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    g.estado::VARCHAR,
    COUNT(*)::BIGINT AS cantidad,
    SUM(
      CASE
        WHEN g.moneda = 'PEN' THEN g.monto
        WHEN g.moneda = 'USD' THEN g.monto * COALESCE(g.tipo_cambio, 3.75)
        WHEN g.moneda = 'EUR' THEN g.monto * COALESCE(g.tipo_cambio, 4.0)
        ELSE g.monto
      END
    )::NUMERIC AS monto_pen
  FROM gastos g
  GROUP BY g.estado
  ORDER BY g.estado;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función: Obtener tendencia de gastos mensuales (últimos 6 meses)
CREATE OR REPLACE FUNCTION obtener_tendencia_gastos_mensual()
RETURNS TABLE (
  mes VARCHAR,
  total_gastos BIGINT,
  monto_pen NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    TO_CHAR(DATE_TRUNC('month', g.fecha_gasto), 'Mon YYYY') AS mes,
    COUNT(*)::BIGINT AS total_gastos,
    SUM(
      CASE
        WHEN g.moneda = 'PEN' THEN g.monto
        WHEN g.moneda = 'USD' THEN g.monto * COALESCE(g.tipo_cambio, 3.75)
        WHEN g.moneda = 'EUR' THEN g.monto * COALESCE(g.tipo_cambio, 4.0)
        ELSE g.monto
      END
    )::NUMERIC AS monto_pen
  FROM gastos g
  WHERE
    g.fecha_gasto >= (CURRENT_DATE - INTERVAL '6 months')
    AND g.estado NOT IN ('anulado', 'rechazado')
  GROUP BY DATE_TRUNC('month', g.fecha_gasto)
  ORDER BY DATE_TRUNC('month', g.fecha_gasto) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentarios
COMMENT ON FUNCTION obtener_gastos_por_concepto IS 'Retorna gastos agrupados por concepto con conversión a PEN';
COMMENT ON FUNCTION obtener_resumen_gastos_estado IS 'Retorna resumen de gastos agrupados por estado';
COMMENT ON FUNCTION obtener_tendencia_gastos_mensual IS 'Retorna tendencia de gastos de los últimos 6 meses';
