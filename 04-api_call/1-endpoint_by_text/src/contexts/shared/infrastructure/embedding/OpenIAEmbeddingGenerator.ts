import { OpenAIEmbeddings } from "@langchain/openai";
import { Service } from "diod";
import { TextEncoder } from "node:util";

import { Embedding } from "../../domain/Embedding";
import { EmbeddingGenerator } from "../../domain/EmbeddingGenerator";

if (typeof globalThis.TextEncoder === "undefined") {
	globalThis.TextEncoder = TextEncoder;
}

@Service()
export class OpenAIEmbeddingGenerator extends EmbeddingGenerator {
	private readonly maxAttemptsToRetry = 3;
	private readonly embeddings: OpenAIEmbeddings;

	constructor() {
		super();

		this.embeddings = new OpenAIEmbeddings({
			// Configuración básica obligatoria
			apiKey: process.env.OPENAI_API_KEY, // ⚠️ Necesitas tu API key
			model: "text-embedding-3-small", // Modelo más reciente y económico
			// Opciones recomendadas
			dimensions: 768, // Misma dimensión que usas en PostgreSQL
			timeout: 30000, // 30 segundos timeout
			maxRetries: 3, // LangChain ya tiene retry incorporado
			// Opcional: para debugging
			verbose: process.env.NODE_ENV === "development",
		});
	}

	async generate(input: string): Promise<Embedding> {
		const output = await this.retry(
			async () => this.embeddings.embedQuery(input),
			this.maxAttemptsToRetry,
		);

		return new Embedding(input, output);
	}

	private async retry<T>(fn: () => Promise<T>, retries: number): Promise<T> {
		try {
			return await fn();
		} catch (error) {
			if (retries <= 0) {
				throw error;
			}

			return this.retry(fn, retries - 1);
		}
	}
}
