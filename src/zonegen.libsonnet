// A zone is a list of layers, merged in order when it is rendered. A layer is an object of owner
// names, each an object of record types. The value of a type is a string for a type that allows one
// record per name, and a set otherwise: an object whose members are true. null at any level removes
// what the layers below have there.

// RFC 2181 10.1 and RFC 6672 2.4 allow one CNAME or DNAME per name, and RFC 1035 one SOA per zone.
local singleTypes = ['cname', 'dname', 'soa'];
local directives = ['$ttl'];

local isDirective(k) = std.startsWith(k, '$');
local fail(where, msg) = error where + ': ' + msg;

local normalizeValue(where, type, v) =
  if v == null then null
  else if std.member(singleTypes, type) then
    if std.isString(v) then v else fail(where, 'must be a string or null')
  else if std.isString(v) then { [v]: true }
  else if std.isArray(v) then { [x]: true for x in v }
  else if std.isObject(v) then
    local bad = [x for x in std.objectFields(v) if v[x] != true && v[x] != null];
    if std.length(bad) == 0 then v else fail(where, 'members must be true or null: ' + std.join(', ', bad))
  else fail(where, 'must be a string, an array, an object of true and null, or null');

local normalize(layer) =
  local unknown = [k for k in std.objectFields(layer) if isDirective(k) && !std.member(directives, k)];
  if std.length(unknown) > 0 then fail('layer', 'unknown directive ' + std.join(', ', unknown))
  else {
    [n]: if isDirective(n) || layer[n] == null then layer[n] else {
      [t]: normalizeValue(n + '.' + t, t, layer[n][t])
      for t in std.objectFields(layer[n])
    }
    for n in std.objectFields(layer)
  };

local merge2(a, b) =
  if std.isObject(a) && std.isObject(b) then a + b + {
    [k]: merge2(a[k], b[k])
    for k in std.setInter(std.objectFields(a), std.objectFields(b))
  }
  else b;

local merge(layers) = std.foldl(function(acc, l) merge2(acc, normalize(l)), layers, {});

local get(o, k, default) = if std.objectHas(o, k) && o[k] != null then o[k] else default;

local fqdn(name, origin) =
  if name == '@' then origin + '.'
  else if std.endsWith(name, '.') then name
  else name + '.' + origin + '.';

// Returns an overlay with a reverse zone for each /24 of the A records.
local reverse(zones) =
  local merged = { [o]: merge(zones[o]) for o in std.objectFields(zones) if zones[o] != null };
  local pairs = [
    { ip: ip, name: fqdn(n, o) }
    for o in std.objectFields(merged)
    for n in std.objectFields(merged[o]) if !isDirective(n) && merged[o][n] != null
    for ip in std.objectFields(get(merged[o][n], 'a', {})) if merged[o][n].a[ip] == true
  ];
  local byIp = std.foldl(function(acc, p) acc + { [p.ip]+: [p.name] }, pairs, {});
  local dup = [ip + ' (' + std.join(', ', std.set(byIp[ip])) + ')' for ip in std.objectFields(byIp) if std.length(std.set(byIp[ip])) > 1];
  if std.length(dup) > 0 then error 'more than one name for ' + std.join(', ', dup)
  else std.foldl(function(acc, ip)
    local o = std.split(ip, '.');
    assert std.length(o) == 4 : 'not an IPv4 address: ' + ip;
    local zone = o[2] + '.' + o[1] + '.' + o[0] + '.in-addr.arpa';
    acc + { [zone]+: { [o[3]]: { ptr: byIp[ip][0] } } },
    std.objectFields(byIp), {});

// Puts each layer of each zone on top of ctx, so that the layer can read the fields of ctx with $. A
// layer keeps the fields that it wrote and that are visible after it, so a hidden field stays out of
// the zone, and so does a field that it writes over a hidden one.
local bindLayers(layers, ctx) = [
  local c = ctx + l;
  { [n]: c[n] for n in std.objectFields(c) if std.objectHasAll(l, n) }
  for l in layers
];
local bind(zones, ctx) = {
  [o]: if zones[o] == null then null else bindLayers(zones[o], ctx)
  for o in std.objectFields(zones)
};

// Puts a layer under every zone, such as the SOA and NS records that all zones share.
local underlay(zones, layer) = {
  [o]: if zones[o] == null then null else [layer] + zones[o]
  for o in std.objectFields(zones)
};

// Adds each layer of an overlay on top of the zone of the same origin; null removes the zone.
local overlay(zones, over) = zones + {
  [o]: if over[o] == null then null else get(zones, o, []) + [over[o]]
  for o in std.objectFields(over)
};

{
  bind: bind,
  merge: merge,
  overlay: overlay,
  reverse: reverse,
  underlay: underlay,
}
