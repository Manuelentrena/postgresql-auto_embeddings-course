create extension if not exists pg_net;

ALTER TABLE mooc.courses ADD COLUMN request_id BIGINT;

CREATE OR REPLACE FUNCTION net._http_response__handle_embedding_response(
)
	RETURNS TRIGGER
	LANGUAGE plpgsql
AS
$$
DECLARE
	embedding_array FLOAT[];
BEGIN
	SELECT ARRAY_AGG(e::DOUBLE PRECISION)
	INTO embedding_array
	FROM jsonb_array_elements_text(new.content::jsonb -> 'data' -> 0 -> 'embedding') AS e;

	UPDATE mooc.courses
	SET embedding = embedding_array::vector
	WHERE request_id = new.id;

	RETURN new;
END;
$$;

CREATE OR REPLACE TRIGGER trg__http_response__handle_embedding_response_after_insert
	AFTER INSERT
	ON net._http_response
	FOR EACH ROW
EXECUTE FUNCTION net._http_response__handle_embedding_response();
