import type {
  AgentToolResult,
  ExtensionAPI,
} from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { searchViaSearxng } from "./search-the-web.ts";

type IndividualResult = {
  url: string;
  title: string;
  content: string;
};

export type SearchResult = {
  pageCount: number;
  results: IndividualResult[];
  isError: boolean;
  error?: {
    message: string;
    trace?: string;
  };
};

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "WebSearch",
    label: "WebSearch",
    description: "Search the web using a local SearXNG instance.",
    promptSnippet:
      "Search the web using SearXNG for information about a topic.",
    parameters: Type.Object({
      query: Type.String({ description: "Search query" }),
    }),
    execute: async (
      _: string,
      params: { query: string },
      signal: AbortSignal | undefined,
      __,
      ___,
    ): Promise<AgentToolResult<SearchResult>> => {
      const response = await searchViaSearxng(params.query, "json", signal);

      if (response instanceof Error) {
        return {
          content: [
            {
              type: "text",
              text: `there was an error during search: ${response.message}`,
            },
          ],
          details: {
            isError: true,
            error: {
              message: response.message,
              trace: response.stack,
            },
            results: [],
            pageCount: 0,
          },
        };
      } else {
        const results = response.results.slice(0, 10);
        return {
          content: [{ type: "text", text: JSON.stringify(results) }],
          details: {
            isError: false,
            error: undefined,
            results,
            pageCount: results.length,
          },
        };
      }
    },
  });
}
