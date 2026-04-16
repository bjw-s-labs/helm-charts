import { useState, useEffect, useId, useMemo, type KeyboardEvent } from "react";
import { Tab, Tabs, TabList, TabPanel } from "react-tabs";
import { merge } from "allof-merge";

type Schema = Record<string, any>;
const INDENT = 20;

function mergeSchema(s: Schema) {
  const m = merge(s) as Schema;
  return {
    props: (m.properties || {}) as Record<string, Schema>,
    required: new Set<string>(m.required || []),
  };
}

function resolveType(s: Schema): string {
  if (Array.isArray(s.type)) return s.type.filter((t: string) => t !== "null").join(" / ") || "null";
  if (s.type) return s.type;
  if (s.properties || s.additionalProperties) return "object";
  if (s.items) return "array";
  return s.oneOf ? "object" : "any";
}

function fmtDefault(v: unknown): [string, string] | null {
  if (v === undefined || v === null) return null;
  const s = typeof v === "object" ? JSON.stringify(v) : String(v);
  return [s, typeof v === "boolean" ? "bool" : typeof v === "number" ? "num" : "str"];
}

const strEx = (ex: unknown) => typeof ex === "string" ? ex : JSON.stringify(ex, null, 2);

function collectExamples(s: Schema, d = 0): string[] {
  if (d > 5) return [];
  const r: string[] = [];
  for (const e of s.examples || []) r.push(strEx(e));
  for (const b of s.oneOf || []) for (const e of b.examples || []) r.push(strEx(e));
  if (s.additionalProperties) r.push(...collectExamples(s.additionalProperties, d + 1));
  return r;
}

interface Variant { type: string; desc?: string; schema: Schema; examples: string[] }

function getVariants(s: Schema): Variant[] {
  const out: Variant[] = [], counts = new Map<string, number>();
  for (const b of s.oneOf || []) {
    const c = b.properties?.type?.const;
    if (c === undefined || c === null) continue;
    const base = String(c), n = (counts.get(base) || 0) + 1;
    counts.set(base, n);
    // Use "existing" for the second PVC variant, counter for 3+
    const label = n === 1 ? base : n === 2 && base === "persistentVolumeClaim" ? `${base} (existing)` : `${base} (${n})`;
    out.push({ type: label, desc: b.description, schema: b, examples: (b.examples || []).map(strEx) });
  }
  return out;
}

const shiki = import("shiki").then(({ createHighlighter }) =>
  createHighlighter({ themes: ["github-dark", "github-light"], langs: ["yaml"] }),
);

function CodeBlock({ code }: { code: string }) {
  const [html, setHtml] = useState<string | null>(null);
  useEffect(() => {
    let live = true;
    shiki.then(h => { if (live) setHtml(h.codeToHtml(code, { lang: "yaml", themes: { dark: "github-dark", light: "github-light" } })); });
    return () => { live = false; };
  }, [code]);
  return (
    <pre className="yv-code">
      {html ? <span dangerouslySetInnerHTML={{ __html: html }} /> : <code>{code}</code>}
    </pre>
  );
}

const activate = (fn: () => void) => ({
  role: "button" as const, tabIndex: 0, onClick: fn,
  onKeyDown: (e: KeyboardEvent) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); fn(); } },
});

function Line({ depth, children, onClick }: { depth: number; children: React.ReactNode; onClick?: () => void }) {
  return (
    <div
      className={`yv-line${onClick ? " yv-expandable" : ""}`}
      style={{ paddingLeft: depth * INDENT + 12 }}
      {...(onClick ? activate(onClick) : {})}
    >
      {children}
    </div>
  );
}

function Desc({ text }: { text: string }) {
  const t = text.length > 70 ? text.slice(0, 69) + "…" : text;
  return <span className="yv-c" title={text.length > 70 ? text : undefined}> # {t}</span>;
}

function Examples({ examples, depth }: { examples: string[]; depth: number }) {
  const [show, setShow] = useState(false);
  const [limit, setLimit] = useState(2);
  useEffect(() => setLimit(2), [examples]);
  if (!examples.length) return null;
  return (
    <div className="yv-examples">
      <Line depth={depth}>
        <span className="yv-link" aria-expanded={show} {...activate(() => setShow(o => !o))}>
          {show ? "▾" : "▸"} {examples.length} example{examples.length > 1 ? "s" : ""}
        </span>
      </Line>
      {show && (
        <div className="yv-examples-list" style={{ paddingLeft: depth * INDENT + 12 }}>
          {examples.slice(0, limit).map((ex, i) => <CodeBlock key={ex.slice(0, 40) + i} code={ex} />)}
          {limit < examples.length && (
            <span className="yv-link" {...activate(() => setLimit(examples.length))}>
              Show {examples.length - limit} more…
            </span>
          )}
        </div>
      )}
    </div>
  );
}

function VariantTabs({ variants, depth }: { variants: Variant[]; depth: number }) {
  return (
    <Tabs className="yv-variants" style={{ paddingLeft: depth * INDENT + 12 }}>
      <TabList className="yv-variant-tabs">
        {variants.map(v => <Tab key={v.type} className="yv-variant-tab" selectedClassName="yv-variant-active">{v.type}</Tab>)}
      </TabList>
      {variants.map(v => (
        <TabPanel key={v.type}>
          {v.desc && <p className="yv-variant-desc">{v.desc}</p>}
          {v.examples[0] && <CodeBlock code={v.examples[0]} />}
          <VariantProps schema={v.schema} />
        </TabPanel>
      ))}
    </Tabs>
  );
}

function VariantProps({ schema }: { schema: Schema }) {
  const { props, required } = useMemo(() => mergeSchema(schema), [schema]);
  const keys = useMemo(() => Object.keys(props).filter(k => k !== "type").sort(), [props]);
  if (!keys.length) return null;
  return <>{keys.map(k => <PropertyNode key={k} name={k} schema={props[k]} depth={0} required={required.has(k)} />)}</>;
}

function PropertyNode({ name, schema, depth, required }: { name: string; schema: Schema; depth: number; required: boolean }) {
  const type = resolveType(schema);
  const isMap = !!schema.additionalProperties && !schema.properties;
  const item = isMap ? schema.additionalProperties! : schema;

  const { props: childProps, required: childReq } = useMemo(() => mergeSchema(item), [item]);
  const childKeys = useMemo(() => Object.keys(childProps).sort(), [childProps]);
  const variants = useMemo(() => getVariants(isMap ? item : schema), [isMap, item, schema]);
  const examples = useMemo(() => collectExamples(schema), [schema]);
  const { def, desc } = useMemo(() => ({ def: fmtDefault(schema.default), desc: schema.description?.split("\n")[0] }), [schema]);

  // When variants exist, only show shared properties (direct on schema, not from oneOf branches)
  const sharedKeys = useMemo(() => {
    if (variants.length === 0) return childKeys;
    const direct = new Set(Object.keys(item.properties || {}));
    return childKeys.filter(k => direct.has(k));
  }, [variants, childKeys, item]);

  const expandable = childKeys.length > 0 || variants.length > 0;
  const [open, setOpen] = useState(false);

  if (!expandable) {
    return (
      <Line depth={depth}>
        <span className="yv-k">{name}</span>
        <span className="yv-p">: </span>
        {def ? <span className={`yv-v-${def[1]}`}>{def[0]}</span> : <span className="yv-v-null">~</span>}
        <span className="yv-type"> {type}</span>
        {required && <span className="yv-badge yv-badge-req">required</span>}
        {desc && <Desc text={desc} />}
      </Line>
    );
  }

  const summary = variants.length > 0
    ? `${sharedKeys.length} shared + ${variants.length} variants`
    : `${childKeys.length} keys`;

  return (
    <>
      <Line depth={depth} onClick={() => setOpen(o => !o)}>
        <span className="yv-arrow" aria-hidden="true">{open ? "▾" : "▸"}</span>
        <span className="yv-k">{name}</span>
        <span className="yv-p">:</span>
        <span className="yv-type"> {type}</span>
        {required && <span className="yv-badge yv-badge-req">required</span>}
        {isMap && <span className="yv-badge yv-badge-map">map</span>}
        {!open && <span className="yv-c"> # {summary}</span>}
        {open && desc && <Desc text={desc} />}
      </Line>
      {open && (
        <div className="yv-children">
          {examples.length > 0 && <Examples examples={examples} depth={depth + 1} />}
          {variants.length > 0 && sharedKeys.length > 0 && (
            <>
              <Line depth={depth + 1}><span className="yv-section-label">common properties</span></Line>
              {sharedKeys.map(k =>
                <PropertyNode key={k} name={k} schema={childProps[k]} depth={depth + 1} required={childReq.has(k)} />
              )}
              <Line depth={depth + 1}><span className="yv-section-label">type variants</span></Line>
            </>
          )}
          {variants.length === 0 && sharedKeys.length > 0 && sharedKeys.map(k =>
            <PropertyNode key={k} name={k} schema={childProps[k]} depth={depth + 1} required={childReq.has(k)} />
          )}
          {variants.length > 0
            ? <VariantTabs variants={variants} depth={depth + 1} />
            : childKeys.filter(k => !sharedKeys.includes(k)).map(k =>
                <PropertyNode key={k} name={k} schema={childProps[k]} depth={depth + 1} required={childReq.has(k)} />
              )
          }
        </div>
      )}
    </>
  );
}

export default function ValuesExplorer({ schemaUrl }: { schemaUrl: string }) {
  const [schema, setSchema] = useState<Schema | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState("");
  const id = useId();

  useEffect(() => {
    const ac = new AbortController();
    fetch(schemaUrl, { signal: ac.signal })
      .then(r => { if (!r.ok) throw new Error(`HTTP ${r.status}`); return r.json(); })
      .then(setSchema)
      .catch(e => { if (e.name !== "AbortError") setError("Failed to load schema"); });
    return () => ac.abort();
  }, [schemaUrl]);

  const props = useMemo(() => schema?.properties || {}, [schema]);
  const keys = useMemo(() => Object.keys(props).sort(), [props]);
  const filtered = useMemo(() => {
    const q = filter.toLowerCase();
    return q ? keys.filter(k => k.toLowerCase().includes(q) || (props[k].description?.toLowerCase().includes(q) ?? false)) : keys;
  }, [keys, filter, props]);

  if (error) return <p>{error}</p>;
  if (!schema) return <div className="yv-root"><div className="yv-tree yv-loading">Loading schema…</div></div>;

  return (
    <div className="yv-root">
      <label className="yv-sr-only" htmlFor={id}>Filter</label>
      <input id={id} className="yv-filter" type="search" placeholder="Filter properties…" value={filter} onChange={e => setFilter(e.target.value)} />
      <div className="yv-tree" role="region" aria-label="Values schema">
        {!filtered.length && <div className="yv-empty">No match for "{filter}"</div>}
        {filtered.map(k => <PropertyNode key={k} name={k} schema={props[k]} depth={0} required={false} />)}
      </div>
    </div>
  );
}
