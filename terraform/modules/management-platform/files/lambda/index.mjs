import { readFileSync } from "node:fs";
import { DynamoDBClient, GetItemCommand, TransactWriteItemsCommand } from "@aws-sdk/client-dynamodb";
import { validate } from "./schema.mjs";
import { createStore } from "./store.mjs";

const spec = JSON.parse(readFileSync(new URL("./openapi.json", import.meta.url)));
const client = new DynamoDBClient({});
const TableName = process.env.TABLE_NAME;
const key = item => ({ pk: { S: item.pk }, sk: { S: item.sk } });
const store = createStore({
  async get(Key) {
    const { Item } = await client.send(new GetItemCommand({ TableName, Key: key(Key), ConsistentRead: true }));
    return Item ? JSON.parse(Item.data.S) : null;
  },
  async commit({ record, next, expectedVersion }) {
    const item = data => ({ ...key(data), data: { S: JSON.stringify(data) } });
    try {
      await client.send(new TransactWriteItemsCommand({ TransactItems: [
        { Put: { TableName, Item: item(record), ConditionExpression: "attribute_not_exists(pk)" } },
        { Put: {
          TableName, Item: { ...item(next), version: { N: String(next.version) } },
          ConditionExpression: expectedVersion === undefined ? "attribute_not_exists(pk)" : "version = :version",
          ...(expectedVersion === undefined ? {} : { ExpressionAttributeValues: { ":version": { N: String(expectedVersion) } } })
        } }
      ] }));
      return true;
    } catch (error) {
      if (error.name === "TransactionCanceledException" && error.CancellationReasons?.every(r => ["None", "ConditionalCheckFailed", "TransactionConflict"].includes(r.Code))) return false;
      throw error;
    }
  }
});

async function receive(snapshot) {
  validate(snapshot, spec.components.schemas.AnalysisSnapshot, spec);
  return store.receive(snapshot);
}

export async function handler(event) {
  if (Array.isArray(event.Records)) {
    const batchItemFailures = [];
    for (const record of event.Records) {
      try { await receive(JSON.parse(record.body).detail); }
      catch { batchItemFailures.push({ itemIdentifier: record.messageId }); }
    }
    return { batchItemFailures };
  }
  const requestId = event.requestContext?.requestId ?? "unknown";
  const reply = (statusCode, body) => ({ statusCode, headers: { "content-type": "application/json" }, body: JSON.stringify(body) });
  try {
    const { applicationId, revision: rawRevision } = event.pathParameters ?? {};
    const revision = Number(rawRevision);
    validate(applicationId, spec.components.schemas.ApplicationId, spec);
    validate(revision, { type: "integer", minimum: 1 }, spec);
    if (event.requestContext.http.method === "GET") {
      const receipt = await store.receipt(applicationId, revision);
      return receipt ? reply(200, receipt) : reply(404, { code: "NOT_FOUND", message: "Receipt not found.", requestId });
    }
    const body = event.isBase64Encoded ? Buffer.from(event.body, "base64").toString() : event.body;
    const snapshot = JSON.parse(body);
    if (snapshot.applicationId !== applicationId || snapshot.revision !== revision) throw Object.assign(new Error("Path and payload differ."), { status: 400, code: "INVALID_REQUEST" });
    return reply(200, await receive(snapshot));
  } catch (error) {
    const status = error instanceof SyntaxError ? 400 : error.status ?? 500;
    return reply(status, { code: error.code ?? (status === 400 ? "INVALID_REQUEST" : "INTERNAL_ERROR"), message: status === 500 ? "Unexpected error." : error.message, requestId });
  }
}
