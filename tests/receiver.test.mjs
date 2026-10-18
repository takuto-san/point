import { test } from "node:test";
import assert from "node:assert/strict";
import { createStore } from "../terraform/lambda/store.mjs";
import { canonical, validate } from "../terraform/lambda/schema.mjs";

const snapshot = (revision, extra = {}) => ({ applicationId: "APP-1", revision, submissionVersion: 1, receivedAt: "2026-10-18T00:00:00Z", submittedAt: "2026-10-18T00:00:00Z", ...extra });
function fixture() {
  const rows = new Map();
  const id = value => `${value.pk}/${value.sk}`;
  const db = {
    async get(key) { return structuredClone(rows.get(id(key))); },
    async commit({ record, next, expectedVersion }) {
      if (rows.has(id(record)) || rows.get(id(next))?.version !== expectedVersion) return false;
      rows.set(id(record), structuredClone(record));
      rows.set(id(next), structuredClone(next));
      return true;
    }
  };
  return { rows, store: createStore(db) };
}

test("canonical payload retries return the original immutable receipt", async () => {
  const { store } = fixture();
  const first = await store.receive(snapshot(1));
  await store.receive(snapshot(3));
  assert.deepEqual(await store.receive(Object.fromEntries(Object.entries(snapshot(1)).reverse())), first);
  assert.deepEqual(await store.receipt("APP-1", 1), first);
  await assert.rejects(store.receive(snapshot(1, { submissionVersion: 2 })), { code: "REVISION_CONFLICT" });
});

test("out-of-order and concurrent revisions never overwrite the newest snapshot", async () => {
  const { store, rows } = fixture();
  await Promise.all([store.receive(snapshot(3)), store.receive(snapshot(2)), store.receive(snapshot(1))]);
  const latest = rows.get("APPLICATION#APP-1/LATEST");
  assert.equal(latest.appliedRevision, 3);
  assert.equal(latest.appliedSnapshot.revision, 3);
  assert.equal((await store.receive(snapshot(2))).disposition, "IGNORED_STALE");
});

test("confirmed application keeps its applied result and holds new snapshots", async () => {
  const { store, rows } = fixture();
  await store.receive(snapshot(1));
  rows.get("APPLICATION#APP-1/LATEST").confirmed = true;
  const receipt = await store.receive(snapshot(2));
  assert.equal(receipt.disposition, "HELD_AFTER_CONFIRMATION");
  assert.equal(receipt.latestAppliedRevision, 1);
  assert.equal(rows.get("APPLICATION#APP-1/LATEST").appliedSnapshot.revision, 1);
});

test("immutable submission metadata and backward submission versions are rejected", async () => {
  const { store } = fixture();
  await store.receive(snapshot(3, { submissionVersion: 2 }));
  await assert.rejects(store.receive(snapshot(4)), { code: "REVISION_CONFLICT" });
  await assert.rejects(store.receive(snapshot(4, { receivedAt: "changed" })), { code: "REVISION_CONFLICT" });
});

test("schema rejects unknown fields, fractional revisions and invalid date-times", () => {
  const schema = { type: "object", required: ["revision"], additionalProperties: false, properties: { revision: { type: "integer", minimum: 1 } } };
  validate({ revision: 1 }, schema, {});
  assert.throws(() => validate({ revision: 1, rawOcr: "PII" }, schema, {}));
  assert.throws(() => validate({ revision: 1.5 }, schema, {}));
  assert.throws(() => validate("2026-10-18", { type: "string", format: "date-time" }, {}));
  assert.deepEqual(canonical({ b: 1, a: 2 }), { a: 2, b: 1 });
});
