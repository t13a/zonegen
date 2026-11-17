local i = import '../index.libsonnet';
local zonegen = import 'zonegen.libsonnet';

// The edge serves its own copy of app, does not know the printer, and does not serve the lab.
local zones = zonegen.overlay(i.zones, {
  'home.arpa': {
    'app-edge1': { a: '10.0.5.20' },
    app: { cname: 'app-edge1' },
    printer: null,
  },
  'lab.home.arpa': null,
});

{
  zones: zonegen.overlay(zones, zonegen.reverse(zones)),
}
