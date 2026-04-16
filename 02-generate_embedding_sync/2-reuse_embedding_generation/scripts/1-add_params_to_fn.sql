CREATE OR REPLACE FUNCTION generate_embedding(
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
          http_header('Authorization', 'Bearer YOUR API KEY HERE'),
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

CREATE OR REPLACE FUNCTION mooc.courses__generate_embedding_input(
	course mooc.courses
)
	RETURNS TEXT
	LANGUAGE plpgsql
	IMMUTABLE
AS
$$
BEGIN
	RETURN '# ' || course.name || E'\n\n' || course.summary;
END;
$$;

CREATE OR REPLACE TRIGGER trg__courses__generate_embedding_before_insert
	BEFORE INSERT
	ON mooc.courses
	FOR EACH ROW
EXECUTE FUNCTION generate_embedding('mooc.courses__generate_embedding_input');

CREATE OR REPLACE TRIGGER trg__courses__generate_embedding_before_update
	BEFORE UPDATE OF name, summary
	ON mooc.courses
	FOR EACH ROW
EXECUTE FUNCTION generate_embedding('mooc.courses__generate_embedding_input');
