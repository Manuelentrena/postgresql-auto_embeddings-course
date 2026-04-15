CREATE EXTENSION IF NOT EXISTS http;

CREATE OR REPLACE FUNCTION generate_embedding()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE
    text_content TEXT;
    response jsonb;
    embedding_vector vector(768);
    api_url TEXT := 'https://api.openai.com/v1/embeddings';
BEGIN
    -- 1. Texto a embeddear
    text_content := COALESCE(NEW.name, '') || ' ' || COALESCE(NEW.summary, '');

    -- 2. Llamada HTTP (FORMA CORRECTA SEGÚN TU EXTENSIÓN)
    SELECT content::jsonb
    INTO response
    FROM http((
        'POST'::text,
        api_url::text,
        ARRAY[
            http_header('Authorization', 'Bearer MY KEY'),
        ]::http_header[],
        'application/json'::text,
        jsonb_build_object(
            'model', 'text-embedding-3-small',
            'input', text_content,
            'dimensions', 768
        )::text
    )::http_request);

    -- 3. Convertir array JSON a vector
    embedding_vector := (
        SELECT array_agg(value::float8)::vector
        FROM jsonb_array_elements_text(response->'data'->0->'embedding') AS t(value)
    );

    -- 4. Guardar embedding
    NEW.embedding := embedding_vector;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg__courses__generate_embedding_before_insert
	BEFORE INSERT
	ON mooc.courses
	FOR EACH ROW
EXECUTE FUNCTION generate_embedding();
