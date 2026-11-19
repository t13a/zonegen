local i = import '../index.libsonnet';
local zonegen = import 'zonegen.libsonnet';

local zones = zonegen.bind(i.zones, { SERVER:: 'ns1' });

{
  zones: zonegen.underlay(zonegen.overlay(zones, zonegen.reverse(zones)), i.templates.defaults),
}
