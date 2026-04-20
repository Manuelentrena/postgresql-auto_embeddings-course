/* CREATE OR REPLACE FUNCTION generate_embedding(
)
	RETURNS TRIGGER
	LANGUAGE plpgsql
AS
$$
DECLARE
	embedding_input_func_name TEXT = tg_argv[0];
	text_content TEXT;
	response_body jsonb;
	embedding_array DOUBLE PRECISION[];
	api_url TEXT := 'https://api.openai.com/v1/embeddings';
	embedding_input_query_string TEXT;
BEGIN
	embedding_input_query_string := 'SELECT ' || embedding_input_func_name || '($1)';

	EXECUTE embedding_input_query_string INTO text_content USING new;

  SELECT content::jsonb
  INTO response_body
  FROM http((
      'POST'::text,
      api_url::text,
      ARRAY[
          http_header('Authorization', 'Bearer k-0sXQ7_hbh9EtDUhvdU-gQp1taV77Bm-FYo4c1RdrOwT3BlbkFJ6VYwiB5CYpn_m-BShUfDClyfttNyVxNZQNFR-guN0A'),
          http_header('Content-Type', 'application/json')
      ]::http_header[],
      'application/json'::text,
      jsonb_build_object(
          'model', 'text-embedding-3-small',
          'input', text_content,
          'dimensions', 768
      )::text
  )::http_request);

	SELECT ARRAY_AGG(e::DOUBLE PRECISION)
	INTO embedding_array
	FROM jsonb_array_elements_text(response_body -> 'data' -> 0 -> 'embedding') AS e;

	new.embedding = embedding_array::vector;

	RETURN new;
END;
$$;
 */

 CREATE OR REPLACE FUNCTION generate_embedding(
)
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE
	embedding_input_func_name TEXT = tg_argv[0];
	query_string TEXT;
	text_content TEXT;
	request_id BIGINT;
	api_url TEXT := 'https://api.openai.com/v1/embeddings';
BEGIN
	-- Construir query dinámica
	query_string := 'SELECT ' || embedding_input_func_name || '($1)';
	EXECUTE query_string INTO text_content USING new;

	-- Validación básica
	IF text_content IS NULL OR length(text_content) = 0 THEN
		RAISE WARNING 'Text content is empty, skipping embedding';
		RETURN new;
	END IF;

	-- Llamada correcta a OpenAI
	SELECT net.http_post(
		url := api_url,
		body := JSONB_BUILD_OBJECT(
			'model', 'text-embedding-3-small',
			'input', text_content,
      'dimensions', 768
		),
		headers := JSONB_BUILD_OBJECT(
			'Content-Type', 'application/json',
			'Authorization', 'Bearer YOUR API KEY HERE'
		)
	)
	INTO request_id;

	RAISE WARNING 'Request ID: %', request_id;

	new.request_id = request_id;

	RETURN new;
END;
$$;