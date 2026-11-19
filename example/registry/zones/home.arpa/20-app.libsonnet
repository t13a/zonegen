// An edge server resolves app to its own copy, and the others to the nas. SERVER comes from the server.
local edges = { edge1: '10.0.5.20' };

{
  local edge = std.get(edges, $.SERVER),
  'app-edge': if edge == null then null else { a: edge },
  app: { cname: if edge == null then 'nas' else 'app-edge' },
}
