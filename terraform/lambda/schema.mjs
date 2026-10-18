// Validate the JSON Schema subset used by this project's OpenAPI 3.1 schemas.
export function validate(value, schema, root, path = "$input") {
  const fail = () => { throw Object.assign(new Error(`Invalid field: ${path}`), { status: 400, code: "INVALID_REQUEST" }); };
  if (schema.$ref) return validate(value, root.components.schemas[schema.$ref.split("/").at(-1)], root, path);
  if (schema.oneOf) {
    const matches = schema.oneOf.filter(option => {
      try { validate(value, option, root, path); return true; } catch { return false; }
    });
    if (matches.length !== 1) fail();
    return;
  }
  const types = Array.isArray(schema.type) ? schema.type : [schema.type];
  const actual = value === null ? "null" : Array.isArray(value) ? "array" : typeof value;
  if (schema.type && !types.some(t => t === actual || (t === "integer" && Number.isSafeInteger(value)))) fail();
  if ("const" in schema && value !== schema.const) fail();
  if (schema.enum && !schema.enum.includes(value)) fail();
  if (typeof value === "string") {
    const length = [...value].length;
    if (length < (schema.minLength ?? 0) || length > (schema.maxLength ?? Infinity)) fail();
    if (schema.pattern && !new RegExp(schema.pattern).test(value)) fail();
    if (schema.format === "date-time" && (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$/i.test(value) || !Number.isFinite(Date.parse(value)))) fail();
  }
  if (typeof value === "number" && value < (schema.minimum ?? -Infinity)) fail();
  if (actual === "object") {
    for (const key of schema.required ?? []) if (!(key in value)) fail();
    for (const [key, child] of Object.entries(value)) {
      if (schema.properties?.[key]) validate(child, schema.properties[key], root, `${path}.${key}`);
      else if (schema.additionalProperties === false) fail();
    }
  }
}

export function canonical(value) {
  if (Array.isArray(value)) return value.map(canonical);
  if (value && typeof value === "object") return Object.fromEntries(Object.keys(value).sort().map(k => [k, canonical(value[k])]));
  return value;
}
