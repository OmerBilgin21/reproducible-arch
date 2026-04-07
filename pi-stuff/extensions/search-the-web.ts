import { Readability } from "@mozilla/readability";
import { parseHTML } from "linkedom";

type OllamaRole = "assistant" | "system" | "user";

type OllamaChatResponse = {
  model: "string";
  created_at: "string";
  message: {
    role: OllamaRole;
    content: string;
  };
  done: boolean;
  done_reason: string;
  total_duration: number;
  load_duration: number;
  prompt_eval_count: number;
  prompt_eval_duration: number;
  eval_count: number;
  eval_duration: number;
};

type SearXNGResult = {
  template: string;
  url: string;
  title: string;
  content: string;
  publishedDate: string | null;
  thumbnail: "string";
  engine: string;
  parsed_url: Array<string>;
  img_src: string;
  priority: string;
  engines: Array<string>;
  positions: Array<number>;
  score: number;
  category: string;
};

type SearXNGResponse = {
  query: string;
  number_of_results: number;
  results: SearXNGResult[];
};

type ResponseFormat = "json" | "html";

const getSearchURL = (
  searchPrompt: string,
  responseFormat: ResponseFormat,
): URL => {
  const encoded = encodeURI(searchPrompt);

  return new URL(
    `http://localhost:5000/search?q=${encoded}&format=${responseFormat ? "json" : "html"}`,
  );
};

export async function searchViaSearxng(
  query: string,
  responseFormat: ResponseFormat,
  signal?: AbortSignal,
): Promise<SearXNGResponse | Error> {
  let error: Error | undefined;
  let data: SearXNGResponse | undefined;
  const searchUrl = getSearchURL(query, responseFormat);

  try {
    const response = await fetch(searchUrl, {
      method: "GET",
      signal,
    });

    data = (await response.json()) as SearXNGResponse;
  } catch (exception) {
    if (exception instanceof Error) {
      error = exception;
    } else {
      error = new Error(String(exception));
    }
  }

  if (error) {
    return error;
  }

  if (data) {
    return data;
  }

  return new Error("there was neither an error nor a result");
}

export async function fetchFullPageWithSummary(
  pageToFetch: string,
  userQuery: string,
  signal?: AbortSignal,
): Promise<string | Error> {
  let result: string | Error;
  try {
    const response = await fetch(pageToFetch, {
      signal,
    });
    const html = await response.text();
    const { document } = parseHTML(html);
    const article = new Readability(document).parse();

    if (!article || !article?.textContent) {
      throw new Error("we did not end up with parse-able webpage contents");
    }

    const cleanedUp = article.textContent
      .split("\n")
      .map((line) => line.trim())
      .filter((line) => line.length > 0)
      .join("\n");

    const ollamaResponse = await fetch(
      new URL("http://localhost:11434/api/chat"),
      {
        method: "POST",
        signal: signal || AbortSignal.timeout(30_000),
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "qwen3.5-9b-48kctx:latest",
          messages: [
            {
              role: "system",
              content: `
You are tasked with summarizing the web page content the user will give you about the question that they have.
Your summary should not prevent the user from getting the information that they want.
Based on user's question/purpose of looking at that web page, clean up the irrelevant parts of the web pages you are given.
If you are unsure about the relevance of a part, leave it. Don't take risks on user being able to access information that they need.
`,
            },
            {
              role: "user",
              content: `I was researching ${userQuery} and I came across this web page:\n${cleanedUp}\n Can you summarize what's on that web page? I don't want to read all of it`,
            },
          ],
          stream: false,
          think: false,
          format: {
            type: "object",
            properties: {
              summary: {
                type: "string",
              },
            },
            required: ["summary"],
          },
          options: {
            temperature: 0.2,
          },
        }),
      },
    );

    const ollamaResponseData =
      (await ollamaResponse.json()) as OllamaChatResponse;

    result = ollamaResponseData.message.content;
  } catch (exception) {
    if (exception instanceof Error) {
      result = exception;
    } else {
      result = new Error(String(exception));
    }
  }

  return result;
}
