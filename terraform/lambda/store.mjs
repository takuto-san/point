import { createHash } from "node:crypto";
import { canonical } from "./schema.mjs";

const conflict = message => Object.assign(new Error(message), { status: 409, code: "REVISION_CONFLICT" });

// Inject the database adapter so both entry points share the same atomic write.
export function createStore(db) {
  const key = (id, revision) => ({ pk: `APPLICATION#${id}`, sk: `REVISION#${revision}` });
  return {
    async receipt(id, revision) {
      return (await db.get(key(id, revision)))?.receipt ?? null;
    },
    async receive(snapshot) {
      const { applicationId: id, revision } = snapshot;
      const hash = createHash("sha256").update(JSON.stringify(canonical(snapshot))).digest("hex");
      for (let attempt = 0; attempt < 8; attempt++) {
        const existing = await db.get(key(id, revision));
        if (existing) {
          if (existing.hash !== hash) throw conflict("Revision content differs.");
          return existing.receipt;
        }
        const latestKey = { pk: `APPLICATION#${id}`, sk: "LATEST" };
        const latest = await db.get(latestKey);
        const previous = latest?.snapshot;
        if (previous && (previous.receivedAt !== snapshot.receivedAt ||
          (previous.submissionVersion === snapshot.submissionVersion && previous.submittedAt !== snapshot.submittedAt) ||
          (revision > latest.seenRevision && snapshot.submissionVersion < previous.submissionVersion))) {
          throw conflict("Submission metadata is inconsistent.");
        }
        const stale = revision <= (latest?.seenRevision ?? 0);
        const held = !stale && latest?.confirmed === true;
        const disposition = stale ? "IGNORED_STALE" : held ? "HELD_AFTER_CONFIRMATION" : "APPLIED";
        const receipt = {
          applicationId: id, revision, receivedAt: new Date().toISOString(), disposition,
          latestAppliedRevision: stale || held ? latest.appliedRevision : revision
        };
        const next = {
          ...latest, ...latestKey, version: (latest?.version ?? 0) + 1,
          seenRevision: Math.max(revision, latest?.seenRevision ?? 0),
          appliedRevision: receipt.latestAppliedRevision,
          snapshot: stale ? previous : snapshot
        };
        if (!stale && !held) next.appliedSnapshot = snapshot;
        const saved = await db.commit({
          record: { ...key(id, revision), hash, snapshot, receipt },
          next, expectedVersion: latest?.version
        });
        if (saved) return receipt;
      }
      throw Object.assign(new Error("Concurrent update; retry later."), { status: 503, code: "UNAVAILABLE" });
    }
  };
}
