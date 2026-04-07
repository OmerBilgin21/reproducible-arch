import type {
  AgentToolResult,
  ExtensionAPI,
} from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { fetchFullPageWithSummary } from "./search-the-web.ts";

type FetchFullWebPageResult = {
  isError: boolean;
  result: string;
};

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "FullWebPageFetch",
    label: "FullWebPageFetch",
    description: "Fetch a single page's full content.",
    promptSnippet:
      "Fetch a web page's full contents using SearXNG for information about a topic.",
    parameters: Type.Object({
      query: Type.String({
        description: "Search query (what do we want to learn from this search)",
      }),
      url: Type.String({ description: "URL of the Web Page to fetch" }),
    }),
    execute: async (
      _: string,
      params: { query: string; url: string },
      signal: AbortSignal | undefined,
      ___,
      ____,
    ): Promise<AgentToolResult<FetchFullWebPageResult>> => {
      const response = await fetchFullPageWithSummary(
        params.url,
        params.query,
        signal,
      );

      if (response instanceof Error) {
        return {
          content: [
            {
              type: "text",
              text: `there was an error during fetch: ${response.message}`,
            },
          ],
          details: {
            isError: true,
            result: response.message,
          },
        };
      } else {
        return {
          content: [{ type: "text", text: JSON.stringify(response) }],
          details: {
            isError: false,
            result: `Error while fetching web page: ${response}`,
          },
        };
      }
    },
  });
}
