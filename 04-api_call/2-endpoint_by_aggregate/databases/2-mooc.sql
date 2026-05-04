CREATE SCHEMA mooc;

CREATE TABLE mooc.courses (
	id CHAR(4) PRIMARY KEY NOT NULL,
	name VARCHAR(255) NOT NULL,
	summary TEXT,
	categories JSONB,
	published_at DATE NOT NULL,
	embedding vector(768),
);

CREATE TABLE mooc.users (
	id CHAR(4) PRIMARY KEY NOT NULL,
	name TEXT NOT NULL,
	bio TEXT NOT NULL,
	email TEXT NOT NULL UNIQUE,
	embedding vector(768),
);

CREATE OR REPLACE FUNCTION generate_course_embedding()
	RETURNS TRIGGER AS $$
BEGIN
	IF TG_OP = 'INSERT' OR (NEW.name IS DISTINCT FROM OLD.name OR NEW.summary IS DISTINCT FROM OLD.summary) THEN
		PERFORM net.http_post(
			url := 'http://host.docker.internal:3000/api/embeddings',
			body := JSONB_BUILD_OBJECT(
				'entity', 'course',
				'id', NEW.id
					),
			headers := JSONB_BUILD_OBJECT('Content-Type', 'application/json')
				);
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg__courses__generate_embedding_after_insert
	AFTER INSERT ON mooc.courses
	FOR EACH ROW
EXECUTE FUNCTION generate_course_embedding();

CREATE OR REPLACE TRIGGER trg__courses__generate_embedding_after_update
	AFTER UPDATE OF name, summary ON mooc.courses
	FOR EACH ROW
EXECUTE FUNCTION generate_course_embedding();
