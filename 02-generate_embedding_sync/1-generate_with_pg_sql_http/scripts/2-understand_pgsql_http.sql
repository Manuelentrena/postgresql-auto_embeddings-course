CREATE EXTENSION IF NOT EXISTS http;

SET my.openai.key = 'MY KEY';

SELECT *
FROM http((
  'POST'::text,
  'https://api.openai.com/v1/embeddings'::text,
  ARRAY[
    http_header('Authorization', 'Bearer ' || current_setting('my.openai.key'))
  ]::http_header[],
  'application/json'::text,
  jsonb_build_object(
    'model', 'text-embedding-3-small',
    'input', 'Un curso muy guapo',
    'dimensions', 768
  )::text
)::http_request);

