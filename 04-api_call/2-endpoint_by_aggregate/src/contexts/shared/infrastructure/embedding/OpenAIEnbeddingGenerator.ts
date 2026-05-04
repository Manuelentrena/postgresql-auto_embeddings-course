import { Service } from "diod";
import OpenAI from "openai";

import { Embedding } from "../../domain/Embedding";
import { EmbeddingGenerator } from "../../domain/EmbeddingGenerator";

@Service()
export class OpenAIEmbeddingGenerator extends EmbeddingGenerator {
	private readonly maxAttemptsToRetry = 3;
	private readonly client: OpenAI;

	constructor() {
		super();

		this.client = new OpenAI({
			apiKey: process.env.OPENAI_API_KEY,
		});
	}

	async generate(input: string): Promise<Embedding> {
		const output = await this.retry(async () => {
			const response = await this.client.embeddings.create({
				model: "text-embedding-3-small",
				input,
				dimensions: 768,
			});

			return response.data[0].embedding;
		}, this.maxAttemptsToRetry);

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
