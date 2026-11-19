local i = import '../index.libsonnet';
local zonegen = import 'zonegen.libsonnet';

// The edge does not know the printer, and does not serve the lab.
local zones = zonegen.overlay(zonegen.bind(i.zones, { SERVER:: 'edge1' }), {
  'home.arpa': { printer: null },
  'lab.home.arpa': null,
});

{
  zones: zonegen.underlay(zonegen.overlay(zones, zonegen.reverse(zones)), i.templates.defaults),
}
